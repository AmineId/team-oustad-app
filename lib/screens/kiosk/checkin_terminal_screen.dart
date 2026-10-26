import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../incidents/incident_create_screen.dart';
import 'kiosk_audio.dart';
import 'kiosk_links.dart';
import 'kiosk_member_search.dart';

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
  // Photo du membre lors d'un check-in manuel (le scan QR n'en fournit pas).
  Uint8List? _memberPhoto;
  String? _errorMessage;

  int _todayCount = 0;
  final List<_ScanEntry> _sessionEntries = [];

  final TextEditingController _qrCtrl = TextEditingController();
  final FocusNode _qrFocus = FocusNode();
  final ScrollController _listScroll = ScrollController();

  // Scan webcam (en plus du lecteur USB/Bluetooth qui tape dans _qrCtrl) —
  // dégrade silencieusement si aucune caméra n'est disponible/autorisée.
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // Connexion directe depuis la borne (pas de passage par l'app complète)
  final TextEditingController _loginEmailCtrl = TextEditingController();
  final TextEditingController _loginPasswordCtrl = TextEditingController();
  bool _loggingIn = false;
  bool _obscurePassword = true;
  String? _loginError;

  Timer? _resetTimer;
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Countdown for auto-reset bar
  late AnimationController _countdownCtrl;
  // Idle pulse animation
  late AnimationController _pulseCtrl;

  static const _resetDuration = Duration(seconds: 5);
  static const _qrFrameSize = 168.0;

  @override
  void initState() {
    super.initState();
    _auth = AuthService(_api);

    _countdownCtrl = AnimationController(vsync: this, duration: _resetDuration);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

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
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshTodayCount(),
    );

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
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _resetTimer?.cancel();
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _countdownCtrl.dispose();
    _pulseCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ── QR handling ─────────────────────────────────────────────────────────────

  /// Détection via la webcam — même point d'entrée que le lecteur USB
  /// (_handleQrInput), ignorée hors de l'état idle pour ne pas re-déclencher
  /// tant qu'un code reste dans le cadre pendant l'affichage du résultat.
  void _handleBarcodeDetect(BarcodeCapture capture) {
    if (_status != _ScanStatus.idle) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) _handleQrInput(code);
  }

  Future<void> _handleQrInput(String raw) async {
    final qrCode = raw.trim();
    if (qrCode.isEmpty || _status == _ScanStatus.processing) return;

    _qrCtrl.clear();
    _refocusQr();

    setState(() {
      _status = _ScanStatus.processing;
      _scanResult = null;
      _checkInResult = null;
      _memberPhoto = null;
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
        final reason = _resolveReason(
          scanResult['reason'] as String?,
          scanResult['message'] as String?,
        );
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
        setState(() {
          _status = _ScanStatus.denied;
          _errorMessage = _checkInError(checkInResult);
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

  // ── Check-in manuel (sans QR code) ────────────────────────────────────────

  Future<void> _openManualCheckIn() async {
    if (_status == _ScanStatus.processing) return;
    if (_token == null || _gymId == null) {
      _setError('Session expirée — reconnectez-vous');
      return;
    }
    final pick = await showKioskMemberSearch(
      context,
      api: _api,
      token: _token!,
      gymId: _gymId!,
    );
    _refocusQr();
    if (pick != null && mounted) await _manualCheckIn(pick);
  }

  /// Même enregistrement que le scan (`/check-in/scan` avec le displayId du
  /// membre), puis même écran de résultat, avec la photo de la fiche.
  Future<void> _manualCheckIn(KioskManualPick pick) async {
    final member = pick.member;
    final displayId = member['displayId'] as String?;
    if (displayId == null || displayId.isEmpty) {
      _setError('Identifiant du membre manquant');
      return;
    }
    _resetTimer?.cancel();
    _countdownCtrl.stop();

    final sub = member['activeSubscription'] as Map<String, dynamic>?;
    final subType = sub?['type'];
    // Forme attendue par l'écran de résultat (comme la réponse du scan QR).
    final shown = <String, dynamic>{
      'id': member['id'],
      'displayId': displayId,
      'firstName': member['firstName'],
      'lastName': member['lastName'],
      if (sub != null)
        'subscription': {
          'status': sub['status'],
          'endDate': sub['endDate'],
          if (subType is String) 'subscriptionType': {'name': subType},
        },
    };
    setState(() {
      _status = _ScanStatus.processing;
      _scanResult = {'member': shown};
      _checkInResult = null;
      _memberPhoto = pick.photo;
      _errorMessage = null;
    });

    final result = await _api.checkInScan(
      qrCode: displayId,
      gymId: _gymId!,
      token: _token!,
      notes: 'Check-in manuel (borne)',
    );
    if (!mounted) return;
    if (result == null) {
      _setError('Erreur de connexion');
      return;
    }
    final ok = result['success'] == true;
    setState(() {
      _status = ok ? _ScanStatus.success : _ScanStatus.denied;
      _checkInResult = ok ? result : null;
      _errorMessage = ok ? null : _checkInError(result);
      if (ok) _todayCount++;
    });
    playKioskBeep(success: ok);
    _addSessionEntry(shown, allowed: ok);
    _scheduleReset();
  }

  /// Message lisible pour un refus de `/check-in/scan` (erreurs serveur en
  /// anglais dans `message`).
  String _checkInError(Map<String, dynamic>? result) {
    final raw = '${result?['message'] ?? result?['error'] ?? ''}';
    final msg = raw.toLowerCase();
    if (msg.contains('already scanned')) return 'Déjà enregistré aujourd\'hui';
    if (msg.contains('quota exhausted')) return 'Quota de séances épuisé';
    if (msg.contains('expired')) return 'Abonnement expiré';
    if (msg.contains('no active subscription')) {
      return 'Aucun abonnement actif';
    }
    if (msg.contains('subscription is')) return 'Abonnement inactif';
    if (msg.contains('member not found')) return 'Membre introuvable';
    if (msg.contains('forbidden')) return 'Action non autorisée';
    return raw.isEmpty ? 'Check-in échoué' : raw;
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
          _memberPhoto = null;
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
        _ScanEntry(
          name: full,
          initials: initials,
          subscriptionName: subName,
          time: DateTime.now(),
          allowed: allowed,
        ),
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
            ? Center(
                child: CircularProgressIndicator(color: context.palette.primary),
              )
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

  // ── Install doc (pprod only) ─────────────────────────────────────────────────

  void _showInstallDoc() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'PPROD',
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.palette.warning,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Installer l\'app mobile',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.darkTextTertiary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Android
                _buildInstallSection(
                  icon: Icons.android_rounded,
                  color: const Color(0xFF3DDC84),
                  title: 'Android',
                  badge: 'Play Store (test interne)',
                  tools: const [
                    'Téléphone Android',
                    'Compte Google ajouté aux testeurs',
                  ],
                  steps: const [
                    'Ouvre le lien ci-dessous sur le téléphone et accepte l\'invitation',
                    'Installe depuis le Play Store (bouton "Rejoindre")',
                    'Lance "Team Oustad" et connecte-toi',
                  ],
                  actionLabel: 'Rejoindre le test Android',
                  actionUrl: kAndroidTestingUrl,
                  note:
                      'Le compte Google doit être ajouté à la liste de testeurs dans Play Console avant d\'accepter.',
                ),

                const SizedBox(height: 20),

                // iOS
                _buildInstallSection(
                  icon: Icons.apple_rounded,
                  color: Colors.white,
                  title: 'iOS',
                  badge: 'AltStore (source privée Team Oustad)',
                  tools: const [
                    'AltStore installé sur l\'iPhone (altstore.io, une seule fois)',
                    'PC Windows ou Mac pour la 1re installation d\'AltStore',
                    'Identifiant Apple gratuit',
                  ],
                  steps: const [
                    'Installe AltStore sur l\'iPhone (voir le guide détaillé)',
                    'Sur l\'iPhone, ouvre le bouton ci-dessous : la source Team Oustad s\'ajoute dans AltStore',
                    'Dans AltStore → Parcourir → Team Oustad → Installer',
                    'Les mises à jour arrivent ensuite directement dans AltStore',
                  ],
                  actionLabel: 'Ajouter la source dans AltStore',
                  actionUrl: kAltStoreAddSourceUrl,
                  note:
                      'À ouvrir depuis l\'iPhone. Avec un Apple ID gratuit, AltStore doit rafraîchir l\'app tous les 7 jours.',
                  onGuideTap: _showAltStoreGuide,
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.barlow(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallSection({
    required IconData icon,
    required Color color,
    required String title,
    required String badge,
    required List<String> tools,
    required List<String> steps,
    required String actionLabel,
    required String actionUrl,
    required String note,
    VoidCallback? onGuideTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête section
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.barlow(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Outils requis
          Text(
            'Requis',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tools
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 11,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t,
                          style: GoogleFonts.barlow(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),

          // Étapes
          Text(
            'Étapes',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton lien
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(actionUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(icon, size: 16, color: Colors.black87),
              label: Text(
                actionLabel,
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Note
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppColors.darkTextTertiary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  note,
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    color: AppColors.darkTextTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),

          if (onGuideTap != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onGuideTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Voir le guide détaillé',
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        decoration: TextDecoration.underline,
                        decorationColor: color,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: color),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Guide AltStore détaillé (pas-à-pas pour le staff) ─────────────────────────

  void _showAltStoreGuide() {
    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.barlowCondensed(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.palette.primary,
        ),
      ),
    );

    Widget step(String title, List<String> lines) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: AppColors.darkTextTertiary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l,
                      style: GoogleFonts.barlow(
                        fontSize: 12.5,
                        color: AppColors.darkTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Widget link(String label, String url) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: context.palette.primary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.barlow(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: context.palette.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: context.palette.primary,
                      ),
                    ),
                    SelectableText(
                      url,
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        color: AppColors.darkTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 620,
          height: 640,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apple_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Installer avec AltStore',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.darkTextTertiary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pas besoin de compte développeur payant : AltStore signe l\'app avec ton '
                        'identifiant Apple gratuit, puis installe et met à jour Team Oustad '
                        'directement depuis notre source privée.',
                        style: GoogleFonts.barlow(
                          fontSize: 12.5,
                          color: AppColors.darkTextTertiary,
                          height: 1.5,
                        ),
                      ),

                      sectionTitle('Liens utiles'),
                      link(
                        'Ajouter la source Team Oustad (AltStore)',
                        kAltStoreAddSourceUrl,
                      ),
                      link(
                        'Ajouter la source Team Oustad (SideStore)',
                        kSideStoreAddSourceUrl,
                      ),
                      link(
                        'URL de la source (ajout manuel)',
                        kAltStoreSourceUrl,
                      ),
                      link(
                        'Télécharger AltServer (PC / Mac)',
                        'https://altstore.io/',
                      ),
                      link(
                        'iTunes pour Windows (version Apple)',
                        'https://www.apple.com/itunes/',
                      ),
                      link(
                        'iCloud pour Windows (version Apple)',
                        'https://support.apple.com/fr-fr/103232',
                      ),
                      link(
                        'Fichier IPA (installation manuelle)',
                        kIpaDownloadUrl,
                      ),

                      sectionTitle('Ce qu\'il faut'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: const [
                          'iPhone (iOS 16+ recommandé)',
                          'PC Windows ou Mac (1re installation)',
                          'iTunes + iCloud version Apple (Windows)',
                          'AltServer (altstore.io)',
                          'Câble USB',
                          'Identifiant Apple (gratuit)',
                        ].map((t) => _Chip(label: t)).toList(),
                      ),

                      sectionTitle('Étapes'),
                      step('1. Préparer le PC (une seule fois)', const [
                        'Windows : installe iTunes et iCloud depuis le site d\'Apple (pas la version Microsoft Store), puis ouvre-les une fois.',
                        'Installe AltServer depuis altstore.io et lance-le (icône dans la barre des tâches ou la barre des menus).',
                      ]),
                      step('2. Installer AltStore sur l\'iPhone (une seule fois)', const [
                        'Branche l\'iPhone au PC et accepte "Faire confiance à cet ordinateur ?".',
                        'Clique sur l\'icône AltServer → Install AltStore → choisis ton iPhone.',
                        'Entre ton identifiant Apple et son mot de passe : AltServer signe et installe AltStore.',
                      ]),
                      step('3. Autoriser AltStore sur l\'iPhone', const [
                        'Réglages → Général → VPN et gestion de l\'appareil → touche ton adresse Apple → Faire confiance.',
                        'iOS 16 et plus : Réglages → Confidentialité et sécurité → Mode développeur → activer, puis redémarrer.',
                      ]),
                      step('4. Ajouter la source Team Oustad', const [
                        'Sur l\'iPhone, ouvre le lien "Ajouter la source Team Oustad (AltStore)" ci-dessus.',
                        'Ou dans AltStore → Sources → + → colle l\'URL de la source.',
                      ]),
                      step('5. Installer l\'app', const [
                        'AltStore → Parcourir → Team Oustad → Installer.',
                        'Les nouvelles versions apparaissent dans Mes apps → Mettre à jour.',
                      ]),

                      sectionTitle('Rafraîchir tous les 7 jours'),
                      step('', const [
                        'Avec un Apple ID gratuit, la signature expire après 7 jours.',
                        'AltStore rafraîchit automatiquement si l\'iPhone et le PC (AltServer ouvert) sont sur le même Wi-Fi.',
                        'Sinon : AltStore → Mes apps → Tout rafraîchir.',
                      ]),

                      sectionTitle('Limitations (Apple ID gratuit)'),
                      step('', const [
                        '3 apps maximum signées ainsi par iPhone (AltStore compte pour une).',
                        'Pas de notifications push (FCM) avec ce mode de signature.',
                        'Le lien de la source ne s\'ouvre que sur un iPhone où AltStore est installé.',
                      ]),

                      sectionTitle('Problèmes fréquents'),
                      const _TroubleshootRow(
                        symptom: 'AltServer ne voit pas l\'iPhone',
                        solution:
                            'Installe iTunes et iCloud version Apple, rebranche le câble, relance AltServer.',
                      ),
                      const _TroubleshootRow(
                        symptom: 'Le lien de la source ne fait rien',
                        solution:
                            'Ouvre-le sur l\'iPhone où AltStore est installé, ou ajoute l\'URL à la main dans Sources.',
                      ),
                      const _TroubleshootRow(
                        symptom: '"Impossible de vérifier l\'app" au lancement',
                        solution:
                            'Refais l\'étape 3 (faire confiance au profil, mode développeur).',
                      ),
                      const _TroubleshootRow(
                        symptom: 'L\'app ne s\'ouvre plus après quelques jours',
                        solution:
                            'Signature expirée (7 jours) → AltStore → Mes apps → Tout rafraîchir.',
                      ),
                      const _TroubleshootRow(
                        symptom:
                            'Erreur de mot de passe alors qu\'il est correct',
                        solution:
                            'Avec la double authentification, utilise un mot de passe '
                            'd\'application généré sur appleid.apple.com.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            'Borne d\'accueil',
            style: GoogleFonts.barlowCondensed(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Text(
            dateStr,
            style: GoogleFonts.barlow(
              fontSize: 13,
              color: AppColors.darkTextTertiary,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            timeStr,
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 20),
          _buildCountBadge(),
          const SizedBox(width: 12),
          if (AppConfig.fromEnvironment().isPreProduction)
            IconButton(
              icon: Icon(
                Icons.install_mobile_outlined,
                size: 18,
                color: context.palette.warning,
              ),
              tooltip: 'Installer l\'app mobile',
              onPressed: _showInstallDoc,
            ),
          IconButton(
            icon: const Icon(
              Icons.report_outlined,
              size: 18,
              color: AppColors.darkTextTertiary,
            ),
            tooltip: 'Signaler un incident',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IncidentCreateScreen()),
              );
              _refocusQr();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.darkTextTertiary,
            ),
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
          Icon(
            Icons.people_outline_rounded,
            size: 14,
            color: context.palette.primary,
          ),
          const SizedBox(width: 5),
          Text(
            '$_todayCount',
            style: GoogleFonts.barlowCondensed(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.palette.primary,
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
        GestureDetector(
          onTap: _refocusQr,
          child: Container(color: Colors.transparent),
        ),
        // Hidden QR capture field
        Positioned(
          left: -200,
          top: -200,
          child: SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: _qrCtrl,
              focusNode: _qrFocus,
              autofocus: true,
              onSubmitted: _handleQrInput,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
              ],
            ),
          ),
        ),
        // State content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(anim),
              child: child,
            ),
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
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _countdownCtrl,
              builder: (_, _) => LinearProgressIndicator(
                value: 1.0 - _countdownCtrl.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  _status == _ScanStatus.success
                      ? context.palette.success
                      : context.palette.error,
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
                child: SizedBox(
                  width: _qrFrameSize,
                  height: _qrFrameSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: _handleBarcodeDetect,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      _buildQrFrame(opacity),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          Text(
            'EN ATTENTE DE SCAN',
            style: GoogleFonts.barlowCondensed(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approchez le QR code du lecteur ou de la webcam',
            style: GoogleFonts.barlow(
              fontSize: 15,
              color: AppColors.darkTextTertiary,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _openManualCheckIn,
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Pas de QR code ? Rechercher un membre'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.darkTextTertiary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrFrame(double opacity) {
    const frameSize = _qrFrameSize;
    const cornerLen = 36.0;
    const cornerThick = 4.0;
    final color = AppColors.primary.withValues(alpha: opacity);

    Widget corner({required bool flipH, required bool flipV}) {
      return Transform.scale(
        scaleX: flipH ? -1 : 1,
        scaleY: flipV ? -1 : 1,
        child: SizedBox(
          width: cornerLen,
          height: cornerLen,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: cornerThick,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(cornerThick),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: cornerThick,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(cornerThick),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        children: [
          // Subtle dot grid
          ...List.generate(
            4,
            (r) => List.generate(
              4,
              (c) => Positioned(
                left: 22.0 + c * 44,
                top: 22.0 + r * 44,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: opacity * 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ).expand((e) => e),
          Positioned(
            top: 0,
            left: 0,
            child: corner(flipH: false, flipV: false),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: corner(flipH: true, flipV: false),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: corner(flipH: false, flipV: true),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: corner(flipH: true, flipV: true),
          ),
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
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: context.palette.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Validation en cours…',
            style: GoogleFonts.barlowCondensed(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
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

    final isExpired =
        subStatus == 'expired' || (daysLeft != null && daysLeft < 0);
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAvatar(
                    profileUrl,
                    initials,
                    100,
                    bytes: _memberPhoto,
                  ),
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
                        fontSize: 54,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (subName.isNotEmpty)
                          _buildBadge(
                            subName,
                            AppColors.primary.withValues(alpha: 0.18),
                            context.palette.primary,
                          ),
                        if (isExpired)
                          _buildBadge(
                            'Expiré',
                            AppColors.error.withValues(alpha: 0.2),
                            context.palette.error,
                          )
                        else if (isExpiringSoon)
                          _buildBadge(
                            'Expire dans $daysLeft j',
                            AppColors.warning.withValues(alpha: 0.2),
                            context.palette.warning,
                          )
                        else
                          _buildBadge(
                            '✓ Actif',
                            AppColors.success.withValues(alpha: 0.2),
                            context.palette.success,
                          ),
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
            Icon(
              Icons.all_inclusive_rounded,
              color: context.palette.primary,
              size: 52,
            )
          else
            Text(
              '${sessionsRemaining ?? 0}',
              style: GoogleFonts.barlowCondensed(
                fontSize: 68,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                isUnlimited ? 'abonnement' : 'restantes',
                style: GoogleFonts.barlow(
                  fontSize: 11,
                  color: AppColors.darkTextTertiary,
                ),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isDenied ? Icons.block_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isDenied ? 'ACCÈS REFUSÉ' : 'ERREUR',
              style: GoogleFonts.barlowCondensed(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              style: GoogleFonts.barlow(
                fontSize: 18,
                color: AppColors.errorLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (full.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                full,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
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
                  Text(
                    'Aujourd\'hui',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      color: AppColors.darkTextTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$_todayCount entrées',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.success,
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
          Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: AppColors.darkTextTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune entrée cette session',
            style: GoogleFonts.barlow(
              fontSize: 13,
              color: AppColors.darkTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListEntry(_ScanEntry entry) {
    final timeStr = DateFormat('HH:mm').format(entry.time);
    final color = entry.allowed ? context.palette.success : context.palette.error;

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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  entry.initials,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.palette.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.subscriptionName.isNotEmpty)
                    Text(
                      entry.subscriptionName,
                      style: GoogleFonts.barlow(
                        fontSize: 10,
                        color: AppColors.darkTextTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  entry.allowed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 13,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── No session fallback ──────────────────────────────────────────────────────

  Future<void> _handleKioskLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'Email et mot de passe requis');
      return;
    }

    setState(() {
      _loggingIn = true;
      _loginError = null;
    });

    try {
      final loginResult = await _api.login(email, password, kiosk: true);
      if (loginResult == null) {
        setState(() {
          _loginError = 'Identifiants incorrects';
          _loggingIn = false;
        });
        return;
      }

      final userType = AuthService.normalizeRole(
        loginResult['userType'] as String?,
      );
      // Le serveur refuse déjà coach/member au kiosk (kiosk_forbidden_role) ;
      // ce filtre couvre un serveur pas encore migré.
      if (loginResult['error'] == 'kiosk_forbidden_role' ||
          (userType != 'manager' && userType != 'owner')) {
        setState(() {
          _loginError = 'Accès réservé aux managers et propriétaires';
          _loggingIn = false;
        });
        return;
      }

      final token = loginResult['token'] as String;
      await _auth.saveToken(token);
      await _auth.saveUserType(userType!);
      await _auth.fetchAndCacheUserProfile(token);

      final profile = await _auth.getCachedUserProfile();
      final raw = profile?['gymId'];

      if (!mounted) return;
      setState(() {
        _token = token;
        _gymId = raw is int ? raw : null;
        _loggingIn = false;
        _loginPasswordCtrl.clear();
      });

      await _refreshTodayCount();
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshTodayCount(),
      );
      _refocusQr();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loginError = 'Erreur de connexion';
        _loggingIn = false;
      });
    }
  }

  Widget _buildNoSession() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'Borne d\'accueil',
              style: GoogleFonts.barlowCondensed(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connexion requise pour activer la borne',
              style: GoogleFonts.barlow(
                fontSize: 13,
                color: AppColors.darkTextTertiary,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _loginEmailCtrl,
              enabled: !_loggingIn,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.barlow(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.barlow(
                  color: AppColors.darkTextTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.darkTextTertiary,
                ),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleKioskLogin(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginPasswordCtrl,
              enabled: !_loggingIn,
              obscureText: _obscurePassword,
              style: GoogleFonts.barlow(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: GoogleFonts.barlow(
                  color: AppColors.darkTextTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.darkTextTertiary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.darkTextTertiary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleKioskLogin(),
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 12),
              Text(
                _loginError!,
                style: GoogleFonts.barlow(color: context.palette.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loggingIn ? null : _handleKioskLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primaryFill,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loggingIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Activer la borne',
                        style: GoogleFonts.barlow(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildAvatar(
    String? imageUrl,
    String initials,
    double size, {
    Uint8List? bytes,
  }) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.success, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitials(initials, size),
            )
          : imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitials(initials, size),
            )
          : _buildInitials(initials, size),
    );
  }

  Widget _buildInitials(String initials, double size) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.barlowCondensed(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
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
      child: Text(
        label,
        style: GoogleFonts.barlow(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Text(
        label,
        style: GoogleFonts.barlow(
          fontSize: 11,
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}

class _TroubleshootRow extends StatelessWidget {
  final String symptom;
  final String solution;

  const _TroubleshootRow({required this.symptom, required this.solution});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: context.palette.warning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  symptom,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Text(
              solution,
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
