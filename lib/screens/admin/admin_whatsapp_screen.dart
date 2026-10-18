import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/glass.dart';

class AdminWhatsAppScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminWhatsAppScreen({super.key, this.onBack});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());

  bool _isLoading = true;
  bool _connected = false;
  String? _phone;
  String? _qrDataUrl;
  bool _qrLoading = false;
  bool _actionLoading = false;
  String _statusMessage = '';
  Timer? _qrPollingTimer;

  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  String? _pairingCode;
  bool _pairingLoading = false;
  String? _pairingError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStatus();
  }

  @override
  void dispose() {
    _qrPollingTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    setState(() {
      _pairingCode = null;
      _pairingError = null;
    });
    if (_tabController.index == 0 && _qrDataUrl == null && !_qrLoading) {
      _fetchQr();
    }
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _statusMessage = 'Token non disponible';
          _isLoading = false;
        });
        return;
      }
      final status = await _apiService.getWhatsAppStatus(token);
      if (!mounted) return;
      setState(() {
        _connected = status?['connected'] as bool? ?? false;
        _phone = status?['phone'] as String?;
        _isLoading = false;
      });
      if (!_connected) {
        _fetchQr();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchQr() async {
    if (_qrLoading) return;
    setState(() {
      _qrLoading = true;
      _qrDataUrl = null;
    });
    try {
      final token = await _authService.loadToken();
      if (token == null) return;
      final result = await _apiService.getWhatsAppQr(token);
      if (!mounted) return;
      final statusCode = result?['statusCode'] as int?;
      if (statusCode == 204) {
        _loadStatus();
        return;
      }
      if (statusCode == 503) {
        setState(() {
          _qrLoading = false;
          _statusMessage = 'Génération du QR en cours…';
        });
        _qrPollingTimer?.cancel();
        _qrPollingTimer = Timer(const Duration(seconds: 3), _fetchQr);
        return;
      }
      final qr = result?['qr'] as String?;
      setState(() {
        _qrDataUrl = qr;
        _qrLoading = false;
        _statusMessage = '';
      });
      if (qr != null) {
        _qrPollingTimer?.cancel();
        _qrPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
          final t = await _authService.loadToken();
          if (t == null) return;
          final s = await _apiService.getWhatsAppStatus(t);
          if (!mounted) return;
          if (s?['connected'] == true) {
            _qrPollingTimer?.cancel();
            _loadStatus();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _qrLoading = false;
        _statusMessage = 'Erreur chargement QR: $e';
      });
    }
  }

  Future<void> _requestPairingCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _pairingError = 'Numéro requis');
      return;
    }

    setState(() {
      _pairingLoading = true;
      _pairingCode = null;
      _pairingError = null;
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _pairingError = 'Session expirée';
          _pairingLoading = false;
        });
        return;
      }

      final result = await _apiService.requestWhatsAppPairingCode(phone, token);
      if (!mounted) return;

      final statusCode = result?['statusCode'] as int?;
      if (statusCode == 409) {
        setState(() {
          _pairingError = 'WhatsApp déjà connecté';
          _pairingLoading = false;
        });
        _loadStatus();
        return;
      }
      if (statusCode == 503) {
        setState(() {
          _pairingError = 'Client pas encore prêt, réessayez dans quelques secondes';
          _pairingLoading = false;
        });
        return;
      }
      if (statusCode == 400) {
        setState(() {
          _pairingError = 'Numéro de téléphone invalide';
          _pairingLoading = false;
        });
        return;
      }

      final code = result?['pairingCode'] as String?;
      if (code == null) {
        setState(() {
          _pairingError = 'Réponse inattendue du serveur';
          _pairingLoading = false;
        });
        return;
      }

      setState(() {
        _pairingCode = code;
        _pairingLoading = false;
      });

      // Poll status to detect when user scans the code
      _qrPollingTimer?.cancel();
      _qrPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final t = await _authService.loadToken();
        if (t == null) return;
        final s = await _apiService.getWhatsAppStatus(t);
        if (!mounted) return;
        if (s?['connected'] == true) {
          _qrPollingTimer?.cancel();
          _loadStatus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pairingError = 'Erreur: $e';
        _pairingLoading = false;
      });
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Déconnecter WhatsApp', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'La session WhatsApp sera supprimée. Un nouveau scan QR sera nécessaire pour reconnecter.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() => _actionLoading = false);
        return;
      }
      final ok = await _apiService.disconnectWhatsApp(token);
      if (!mounted) return;
      setState(() => _actionLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp déconnecté'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la déconnexion'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: glassExtendsBody,
      appBar: glassAppBar(
        context,
        title: const Text(
          'WhatsApp',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatus,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Container(
        decoration: appBackgroundDecoration(context),
        child: glassBodyInsets(context, _buildScrollBody(theme)),
      ),
    );
  }

  Widget _buildScrollBody(ThemeData theme) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(theme),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!_connected) _buildConnectionSection(theme),
                  if (_connected) _buildDisconnectSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_connected ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (_connected ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _connected ? Icons.check_circle : Icons.cancel,
              color: _connected ? AppColors.success : AppColors.error,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _connected ? 'Connecté' : 'Déconnecté',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _connected ? AppColors.success : AppColors.error,
                  ),
                ),
                if (_connected && _phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+$_phone',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ] else if (!_connected) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Choisissez une méthode de connexion',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection(ThemeData theme) {
    return Column(
      children: [
        // Tab toggle
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 18),
                    SizedBox(width: 8),
                    Text('QR Code'),
                  ],
                ),
              ),
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android, size: 18),
                    SizedBox(width: 8),
                    Text('Numéro'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQrTab(theme),
              _buildPhoneTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Scanner avec WhatsApp',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ouvrez WhatsApp → Appareils connectés → Connecter un appareil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (_qrLoading)
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_qrDataUrl != null)
                _buildQrImage()
              else
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: Icon(Icons.qr_code, size: 80, color: Colors.white30),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _qrLoading ? null : _fetchQr,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Régénérer le QR'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Connecter via numéro',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ouvrez WhatsApp → Appareils connectés → Connecter avec numéro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                helperText: 'Format international, ex : 212600123456',
                helperStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
                prefixIcon: Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _pairingError,
                errorStyle: const TextStyle(color: AppColors.error),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.error),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
              onSubmitted: (_) => _pairingLoading ? null : _requestPairingCode(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _pairingLoading ? null : _requestPairingCode,
                icon: _pairingLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_pairingLoading ? 'Demande en cours…' : 'Obtenir le code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_pairingCode != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Code d\'appairage',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pairingCode!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entrez ce code dans WhatsApp',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrImage() {
    try {
      final comma = _qrDataUrl!.indexOf(',');
      if (comma == -1) return const SizedBox();
      final b64 = _qrDataUrl!.substring(comma + 1);
      final bytes = base64Decode(b64);
      return Container(
        width: 220,
        height: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Icon(Icons.broken_image, size: 60, color: Colors.white30),
        ),
      );
    }
  }

  Widget _buildDisconnectSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _actionLoading ? null : _disconnect,
        icon: _actionLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.logout, size: 20),
        label: const Text('Déconnecter WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
