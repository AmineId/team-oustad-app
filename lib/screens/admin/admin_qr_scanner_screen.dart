import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class AdminQrScannerScreen extends StatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  State<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends State<AdminQrScannerScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  Map<String, dynamic>? _scanResult;
  Map<String, dynamic>? _checkInResult;
  String? _errorMessage;
  Timer? _resetTimer;

  @override
  void dispose() {
    _scannerController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrData = barcode.rawValue!;

    setState(() {
      _isProcessing = true;
      _scanResult = null;
      _checkInResult = null;
      _errorMessage = null;
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Session expirée';
          _isProcessing = false;
        });
        return;
      }

      // 1. Valider le QR code et récupérer les infos du membre
      final scanResult = await _apiService.scanQrCode(qrData, token);

      if (scanResult == null) {
        setState(() {
          _errorMessage = 'Erreur lors de la validation du QR code';
          _isProcessing = false;
        });
        _scheduleReset();
        return;
      }

      // Vérifier si le scan est réussi
      if (scanResult['success'] != true) {
        setState(() {
          _errorMessage = scanResult['message'] ?? 'QR code invalide';
          _scanResult = scanResult;
          _isProcessing = false;
        });
        _scheduleReset();
        return;
      }

      // 2. Afficher les infos et le quota
      setState(() {
        _scanResult = scanResult;
      });

      // Debug: afficher le quota reçu
      print('🔍 DEBUG Quota reçu: ${scanResult['quota']}');

      // Attendre 1 seconde pour afficher les infos avant de proposer le check-in
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isProcessing = false;
      });
      _scheduleReset();
    }
  }

  Future<void> _performCheckIn() async {
    if (_scanResult == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.loadToken();
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Session expirée';
          _isProcessing = false;
        });
        return;
      }

      // Recharger le profil depuis l'API pour avoir les données à jour
      await _authService.fetchAndCacheUserProfile(token);
      final profileData = await _authService.getCachedUserProfile();
      
      if (profileData == null) {
        setState(() {
          _errorMessage = 'Session expirée';
          _isProcessing = false;
        });
        return;
      }

      final gymId = profileData['gymId'] as int;
      final member = _scanResult!['member'] as Map<String, dynamic>?;
      
      if (member == null) {
        setState(() {
          _errorMessage = 'Informations du membre non disponibles';
          _isProcessing = false;
        });
        return;
      }

      final qrCode = member['displayId'] as String;

      // Effectuer le check-in
      final checkInResult = await _apiService.checkInScan(
        qrCode: qrCode,
        gymId: gymId,
        token: token,
      );

      if (checkInResult == null) {
        setState(() {
          _errorMessage = 'Erreur lors du check-in';
          _isProcessing = false;
        });
        _scheduleReset();
        return;
      }

      if (checkInResult['success'] != true) {
        setState(() {
          _errorMessage = checkInResult['error'] ?? checkInResult['message'] ?? 'Échec du check-in';
          _isProcessing = false;
        });
        _scheduleReset();
        return;
      }

      setState(() {
        _checkInResult = checkInResult;
        _isProcessing = false;
      });

      _scheduleReset(seconds: 4);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isProcessing = false;
      });
      _scheduleReset();
    }
  }

  void _scheduleReset({int seconds = 3}) {
    _resetTimer?.cancel();
    _resetTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _scanResult = null;
          _checkInResult = null;
          _errorMessage = null;
        });
      }
    });
  }

  void _resetScanner() {
    _resetTimer?.cancel();
    setState(() {
      _scanResult = null;
      _checkInResult = null;
      _errorMessage = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_scanResult != null || _errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
              tooltip: 'Réinitialiser',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleScan,
          ),

          // Scan overlay
          if (_scanResult == null && _checkInResult == null && _errorMessage == null)
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Result overlay
          if (_scanResult != null || _checkInResult != null || _errorMessage != null)
            Container(
              color: Colors.black87,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildResultCard(),
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Traitement...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    if (_checkInResult != null) {
      return _buildCheckInSuccessCard();
    }

    if (_scanResult != null) {
      return _buildMemberInfoCard();
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorCard() {
    return Card(
      color: AppColors.error.withValues(alpha: 0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Scanner à nouveau'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSuccessCard() {
    final quota = _checkInResult!['quota'] as Map<String, dynamic>?;
    final member = _checkInResult!['member'] as Map<String, dynamic>?;
    final message = _checkInResult!['message'] as String?;

    return Card(
      color: AppColors.success.withValues(alpha: 0.95),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              '✅ Check-in réussi !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (member != null) ...[
              const SizedBox(height: 8),
              Text(
                '${member['firstName']} ${member['lastName']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (quota != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Séances restantes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (quota['isUnlimited'] == true)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.all_inclusive, color: Colors.white, size: 40),
                          SizedBox(width: 8),
                          Text(
                            'Illimité',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${quota['sessionsRemaining'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (quota['sessionQuota'] != null && quota['isUnlimited'] != true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'sur ${quota['sessionQuota']} (${quota['percentageUsed'] ?? 0}% utilisé)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Scanner un autre membre'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfoCard() {
    final member = _scanResult!['member'] as Map<String, dynamic>?;
    final quota = _scanResult!['quota'] as Map<String, dynamic>?;
    final subscription = member?['subscription'] as Map<String, dynamic>?;
    final message = _scanResult!['message'] as String?;

    return Card(
      color: AppColors.primary.withValues(alpha: 0.95),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            if (member != null) ...[
              Text(
                '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                member['displayId'] ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (subscription != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Abonnement',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subscription['subscriptionType']?['name'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(
                          subscription['status'] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (quota != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Séances restantes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (quota['sessionQuota'] == null || quota['isUnlimited'] == true)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.all_inclusive, color: Colors.white, size: 32),
                          SizedBox(width: 8),
                          Text(
                            'Illimité',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${quota['sessionsRemaining'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (quota['sessionQuota'] != null && quota['isUnlimited'] != true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'sur ${quota['sessionQuota']} (${quota['percentageUsed'] ?? 0}% utilisé)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (quota['canCheckIn'] == false) ...[
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Quota épuisé',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScanner,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (quota?['canCheckIn'] == true) ? _performCheckIn : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Valider l\'entrée'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
