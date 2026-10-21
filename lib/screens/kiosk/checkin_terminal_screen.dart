import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import 'kiosk_audio.dart';

enum _ScanStatus { idle, processing, success, denied, error }

class _ScanEntry {
  final String name;
  final String initials;
  final String subscriptionName;
  final DateTime time;
  final bool allowed;

  const _ScanEntry({
    required this.name,
    required this.initials,
    required this.subscriptionName,
    required this.time,
    required this.allowed,
  });
}

class CheckinTerminalScreen extends StatefulWidget {
  const CheckinTerminalScreen({super.key});

  @override
  State<CheckinTerminalScreen> createState() => _CheckinTerminalScreenState();
}

class _CheckinTerminalScreenState extends State<CheckinTerminalScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService.fromEnv();
  late final AuthService _auth;

  String? _token;
  int? _gymId;
  bool _initialized = false;

  _ScanStatus _status = _ScanStatus.idle;
  Map<String, dynamic>? _scanResult;
  Map<String, dynamic>? _checkInResult;
  String? _errorMessage;

  int _todayCount = 0;
  final List<_ScanEntry> _sessionEntries = [];

  final TextEditingController _qrCtrl = TextEditingController();
  final FocusNode _qrFocus = FocusNode();
  final ScrollController _listScroll = ScrollController();

  Timer? _resetTimer;
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Countdown for auto-reset bar
  late AnimationController _countdownCtrl;
  // Idle pulse animation
  late AnimationController _pulseCtrl;

  static const _resetDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _auth = AuthService(_api);

    _countdownCtrl = AnimationController(vsync: this, duration: _resetDuration);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _init();
  }

  Future<void> _init() async {
    _token = await _auth.loadToken();
    if (_token == null) {
      if (mounted) setState(() => _initialized = true);
      return;
    }

    final profile = await _auth.getCachedUserProfile();
    if (profile != null) {
      final raw = profile['gymId'];
      _gymId = raw is int ? raw : null;
    }

    await _refreshTodayCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshTodayCount());

    if (mounted) {
      setState(() => _initialized = true);
      _refocusQr();
    }
  }

  Future<void> _refreshTodayCount() async {
    if (_token == null || _gymId == null) return;
    final count = await _api.getTodayCheckIns(_gymId!, _token!);
    if (mounted && count != null) setState(() => _todayCount = count);
  }

  @override
  void dispose() {
    _qrCtrl.dispose();
    _qrFocus.dispose();
    _listScroll.dispose();
    _resetTimer?.cancel();
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _countdownCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── QR handling ─────────────────────────────────────────────────────────────

  Future<void> _handleQrInput(String raw) async {
    final qrCode = raw.trim();
    if (qrCode.isEmpty || _status == _ScanStatus.processing) return;

    _qrCtrl.clear();
    _refocusQr();

    setState(() {
      _status = _ScanStatus.processing;
      _scanResult = null;
      _checkInResult = null;
      _errorMessage = null;
    });
    _countdownCtrl.stop();

    if (_token == null || _gymId == null) {
      _setError('Session expirée — reconnectez-vous');
      return;
    }

    try {
      // Step 1: validate QR + get member/subscription details
      final scanResult = await _api.scanQrCode(qrCode, _token!);

      if (scanResult == null) {
        _setError('Erreur de connexion');
        return;
      }

      final member = scanResult['member'] as Map<String, dynamic>?;
      final quota = scanResult['quota'] as Map<String, dynamic>?;
      final canCheckIn = quota?['canCheckIn'] as bool? ?? false;

      if (!canCheckIn) {
        final reason = _resolveReason(scanResult['reason'] as String?, scanResult['message'] as String?);
        setState(() {
          _status = _ScanStatus.denied;
          _errorMessage = reason;
          _scanResult = scanResult;
        });
        playKioskBeep(success: false);
        _addSessionEntry(member, allowed: false);
        _scheduleReset();
        return;
      }

      // Step 2: record the check-in
      final displayId = member?['displayId'] as String? ?? qrCode;
      final checkInResult = await _api.checkInScan(
        qrCode: displayId,
        gymId: _gymId!,
        token: _token!,
      );

      if (checkInResult == null || (checkInResult['success'] == false)) {
        final msg = checkInResult?['message'] ?? checkInResult?['error'] ?? 'Check-in échoué';
        setState(() {
          _status = _ScanStatus.denied;
          _errorMessage = msg as String;
          _scanResult = scanResult;
        });
        playKioskBeep(success: false);
        _addSessionEntry(member, allowed: false);
        _scheduleReset();
        return;
      }

      setState(() {
        _status = _ScanStatus.success;
        _scanResult = scanResult;
        _checkInResult = checkInResult;
        _todayCount++;
      });
      playKioskBeep(success: true);
      _addSessionEntry(member, allowed: true);
      _scheduleReset();
    } catch (_) {
      _setError('Erreur de connexion');
    }
  }

  void _setError(String msg) {
    setState(() {
      _status = _ScanStatus.error;
      _errorMessage = msg;
    });
    playKioskBeep(success: false);
    _scheduleReset();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _countdownCtrl.forward(from: 0);
    _resetTimer = Timer(_resetDuration, () {
      if (mounted) {
        setState(() {
          _status = _ScanStatus.idle;
          _scanResult = null;
          _checkInResult = null;
          _errorMessage = null;
        });
        _countdownCtrl.stop();
        _refocusQr();
      }
    });
  }

  void _refocusQr() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _qrFocus.requestFocus();
    });
  }

  String _resolveReason(String? reason, String? message) {
    if (reason != null) {
      switch (reason) {
        case 'no_subscription':
          return 'Aucun abonnement actif';
        case 'subscription_expired':
          return 'Abonnement expiré';
        case 'quota_exceeded':
          return 'Quota de séances épuisé';
        case 'already_checked_in':
          return 'Déjà enregistré aujourd\'hui';
        default:
          return message ?? 'Accès refusé';
      }
    }
    return message ?? 'Accès refusé';
  }

  void _addSessionEntry(Map<String, dynamic>? member, {required bool allowed}) {
    if (member == null) return;
    final first = member['firstName'] as String? ?? '';
    final last = member['lastName'] as String? ?? '';
    final full = '$first $last'.trim();
    if (full.isEmpty) return;

    final parts = full.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : full.substring(0, math.min(2, full.length)).toUpperCase();

    final subscription = member['subscription'] as Map<String, dynamic>?;
    final subName = subscription?['subscriptionType']?['name'] as String? ?? '';

    setState(() {
      _sessionEntries.insert(
        0,
        _ScanEntry(name: full, initials: initials, subscriptionName: subName, time: DateTime.now(), allowed: allowed),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScroll.hasClients) _listScroll.jumpTo(0);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: PopScope(
        canPop: false,
        child: !_initialized
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _token == null
                ? _buildNoSession()
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(flex: 6, child: _buildScanPanel()),
                            Container(width: 1, color: const Color(0xFF374151)),
                            Expanded(flex: 4, child: _buildTodayPanel()),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(_now);

    return Container(
      height: 58,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('TF', style: GoogleFonts.barlowCondensed(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87,
              )),
            ),
          ),
          const SizedBox(width: 10),
          Text('Borne d\'accueil', style: GoogleFonts.barlowCondensed(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4,
          )),
          const Spacer(),
          Text(
            dateStr,
            style: GoogleFonts.barlow(fontSize: 13, color: AppColors.darkTextTertiary),
          ),
          const SizedBox(width: 20),
          Text(timeStr, style: GoogleFonts.barlowCondensed(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          )),
          const SizedBox(width: 20),
          _buildCountBadge(),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.darkTextTertiary),
            tooltip: 'Quitter la borne',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$_todayCount',
            style: GoogleFonts.barlowCondensed(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scan panel (left) ────────────────────────────────────────────────────────

  Widget _buildScanPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(onTap: _refocusQr, child: Container(color: Colors.transparent)),
        // Hidden QR capture field
        Positioned(
          left: -200, top: -200,
          child: SizedBox(
            width: 1, height: 1,
            child: TextField(
              controller: _qrCtrl,
              focusNode: _qrFocus,
              autofocus: true,
              onSubmitted: _handleQrInput,
              keyboardType: TextInputType.text,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))],
            ),
          ),
        ),
        // State content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(anim), child: child),
          ),
          child: switch (_status) {
            _ScanStatus.idle => _buildIdleState(),
            _ScanStatus.processing => _buildProcessingState(),
            _ScanStatus.success => _buildSuccessState(),
            _ScanStatus.denied || _ScanStatus.error => _buildErrorState(),
          },
        ),
        // Countdown bar (visible when not idle)
        if (_status != _ScanStatus.idle && _status != _ScanStatus.processing)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _countdownCtrl,
              builder: (_, _) => LinearProgressIndicator(
                value: 1.0 - _countdownCtrl.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  _status == _ScanStatus.success ? AppColors.success : AppColors.error,
                ),
                minHeight: 3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdleState() {
    return Center(
      key: const ValueKey('idle'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) {
              final t = _pulseCtrl.value;
              final opacity = 0.4 + 0.6 * t;
              final scale = 1.0 + 0.04 * math.sin(t * math.pi);
              return Transform.scale(
                scale: scale,
                child: _buildQrFrame(opacity),
              );
            },
          ),
          const SizedBox(height: 36),
          Text(
            'EN ATTENTE DE SCAN',
            style: GoogleFonts.barlowCondensed(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approchez le QR code du lecteur',
            style: GoogleFonts.barlow(fontSize: 15, color: AppColors.darkTextTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildQrFrame(double opacity) {
    const frameSize = 168.0;
    const cornerLen = 36.0;
    const cornerThick = 4.0;
    final color = AppColors.primary.withValues(alpha: opacity);

    Widget corner({required bool flipH, required bool flipV}) {
      return Transform.scale(
        scaleX: flipH ? -1 : 1,
        scaleY: flipV ? -1 : 1,
        child: SizedBox(
          width: cornerLen, height: cornerLen,
          child: Stack(
            children: [
              Positioned(top: 0, left: 0, right: 0, child: Container(height: cornerThick, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(cornerThick)))),
              Positioned(top: 0, left: 0, bottom: 0, child: Container(width: cornerThick, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(cornerThick)))),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: frameSize, height: frameSize,
      child: Stack(
        children: [
          // Subtle dot grid
          ...List.generate(4, (r) => List.generate(4, (c) => Positioned(
            left: 22.0 + c * 44,
            top: 22.0 + r * 44,
            child: Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity * 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))).expand((e) => e),
          Positioned(top: 0, left: 0, child: corner(flipH: false, flipV: false)),
          Positioned(top: 0, right: 0, child: corner(flipH: true, flipV: false)),
          Positioned(bottom: 0, left: 0, child: corner(flipH: false, flipV: true)),
          Positioned(bottom: 0, right: 0, child: corner(flipH: true, flipV: true)),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 22),
          Text('Validation en cours…', style: GoogleFonts.barlowCondensed(
            fontSize: 22, fontWeight: FontWeight.w600,
            color: AppColors.darkTextSecondary, letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final member = _scanResult?['member'] as Map<String, dynamic>?;
    final scanQuota = _scanResult?['quota'] as Map<String, dynamic>?;
    final checkInQuota = _checkInResult?['quota'] as Map<String, dynamic>?;
    final quota = checkInQuota ?? scanQuota;
    final subscription = member?['subscription'] as Map<String, dynamic>?;

    final first = member?['firstName'] as String? ?? '';
    final last = member?['lastName'] as String? ?? '';
    final full = member?['fullName'] as String? ?? '$first $last'.trim();
    final parts = full.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : full.substring(0, math.min(2, full.length)).toUpperCase();

    final profileUrl = member?['profileImageUrl'] as String?;
    final subName = subscription?['subscriptionType']?['name'] as String? ?? '';
    final subStatus = subscription?['status'] as String? ?? 'active';
    final endDateStr = subscription?['endDate'] as String?;

    int? daysLeft;
    if (endDateStr != null) {
      try {
        daysLeft = DateTime.parse(endDateStr).difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    final isExpired = subStatus == 'expired' || (daysLeft != null && daysLeft < 0);
    final isExpiringSoon = !isExpired && daysLeft != null && daysLeft <= 7;

    final sessionsRemaining = quota?['sessionsRemaining'] as int?;
    final isUnlimited = quota?['isUnlimited'] as bool? ?? false;

    return Container(
      key: const ValueKey('success'),
      color: const Color(0xFF011a11),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: check + avatar
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 28, spreadRadius: 4)],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 20),
                  _buildAvatar(profileUrl, initials, 100),
                ],
              ),
              const SizedBox(width: 36),
              // Right: info
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      full.toUpperCase(),
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 54, fontWeight: FontWeight.w800,
                        color: Colors.white, height: 1, letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        if (subName.isNotEmpty)
                          _buildBadge(subName, AppColors.primary.withValues(alpha: 0.18), AppColors.primary),
                        if (isExpired)
                          _buildBadge('Expiré', AppColors.error.withValues(alpha: 0.2), AppColors.error)
                        else if (isExpiringSoon)
                          _buildBadge('Expire dans $daysLeft j', AppColors.warning.withValues(alpha: 0.2), AppColors.warning)
                        else
                          _buildBadge('✓ Actif', AppColors.success.withValues(alpha: 0.2), AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSessionsBox(isUnlimited, sessionsRemaining),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsBox(bool isUnlimited, int? sessionsRemaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (isUnlimited)
            const Icon(Icons.all_inclusive_rounded, color: AppColors.primary, size: 52)
          else
            Text(
              '${sessionsRemaining ?? 0}',
              style: GoogleFonts.barlowCondensed(
                fontSize: 68, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUnlimited ? 'ILLIMITÉ' : 'SÉANCES',
                style: GoogleFonts.barlow(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.darkTextTertiary, letterSpacing: 1.5,
                ),
              ),
              Text(
                isUnlimited ? 'abonnement' : 'restantes',
                style: GoogleFonts.barlow(fontSize: 11, color: AppColors.darkTextTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isDenied = _status == _ScanStatus.denied;
    final member = _scanResult?['member'] as Map<String, dynamic>?;
    final first = member?['firstName'] as String? ?? '';
    final last = member?['lastName'] as String? ?? '';
    final full = member?['fullName'] as String? ?? '$first $last'.trim();

    return Container(
      key: const ValueKey('error'),
      color: const Color(0xFF150303),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 28, spreadRadius: 4)],
              ),
              child: Icon(
                isDenied ? Icons.block_rounded : Icons.error_outline_rounded,
                color: Colors.white, size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isDenied ? 'ACCÈS REFUSÉ' : 'ERREUR',
              style: GoogleFonts.barlowCondensed(
                fontSize: 40, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              style: GoogleFonts.barlow(fontSize: 18, color: AppColors.errorLight),
              textAlign: TextAlign.center,
            ),
            if (full.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                full,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 28, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Today panel (right) ──────────────────────────────────────────────────────

  Widget _buildTodayPanel() {
    final dateStr = DateFormat('d MMMM', 'fr_FR').format(_now);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
          color: AppColors.darkSurface,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aujourd\'hui', style: GoogleFonts.barlowCondensed(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.3,
                  )),
                  Text(dateStr, style: GoogleFonts.barlow(
                    fontSize: 12, color: AppColors.darkTextTertiary,
                  )),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$_todayCount entrées',
                  style: GoogleFonts.barlow(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFF374151)),
        Expanded(
          child: _sessionEntries.isEmpty
              ? _buildEmptyList()
              : ListView.builder(
                  controller: _listScroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sessionEntries.length,
                  itemBuilder: (_, i) => _buildListEntry(_sessionEntries[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 40, color: AppColors.darkTextTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Aucune entrée cette session', style: GoogleFonts.barlow(
            fontSize: 13, color: AppColors.darkTextTertiary,
          )),
        ],
      ),
    );
  }

  Widget _buildListEntry(_ScanEntry entry) {
    final timeStr = DateFormat('HH:mm').format(entry.time);
    final color = entry.allowed ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(entry.initials, style: GoogleFonts.barlowCondensed(
                  fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary,
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.name, style: GoogleFonts.barlow(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  ), overflow: TextOverflow.ellipsis),
                  if (entry.subscriptionName.isNotEmpty)
                    Text(entry.subscriptionName, style: GoogleFonts.barlow(
                      fontSize: 10, color: AppColors.darkTextTertiary,
                    ), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: GoogleFonts.barlowCondensed(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.darkTextTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
                const SizedBox(height: 2),
                Icon(
                  entry.allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 13, color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── No session fallback ──────────────────────────────────────────────────────

  Widget _buildNoSession() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 52, color: AppColors.darkTextTertiary),
          const SizedBox(height: 16),
          Text('Session expirée', style: GoogleFonts.barlowCondensed(
            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const SizedBox(height: 8),
          Text('Reconnectez-vous pour accéder à la borne.', style: GoogleFonts.barlow(
            fontSize: 15, color: AppColors.darkTextTertiary,
          )),
          const SizedBox(height: 28),
          TextButton.icon(
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildAvatar(String? imageUrl, String initials, double size) {
    return Container(
      width: size, height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 2)],
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitials(initials, size),
            )
          : _buildInitials(initials, size),
    );
  }

  Widget _buildInitials(String initials, double size) {
    return Center(
      child: Text(initials, style: GoogleFonts.barlowCondensed(
        fontSize: size * 0.35, fontWeight: FontWeight.w800, color: Colors.black87,
      )),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.barlow(
        fontSize: 12, fontWeight: FontWeight.w600, color: fg,
      )),
    );
  }
}
