import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class AdminWhatsAppScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminWhatsAppScreen({super.key, this.onBack});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _qrPollingTimer?.cancel();
    super.dispose();
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
        // Already connected — reload status
        _loadStatus();
        return;
      }
      if (statusCode == 503) {
        // QR not ready yet — poll after 3s
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
        // Poll status every 5s to detect when scanned
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
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'WhatsApp',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatus,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, theme.cardTheme.color!],
          ),
        ),
        child: SafeArea(
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
                      if (!_connected) _buildQrSection(theme),
                      if (_connected) _buildDisconnectSection(),
                    ],
                  ),
                ),
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
                    'Scannez le QR ci-dessous',
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

  Widget _buildQrSection(ThemeData theme) {
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

  Widget _buildQrImage() {
    try {
      // _qrDataUrl is "data:image/png;base64,..."
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
