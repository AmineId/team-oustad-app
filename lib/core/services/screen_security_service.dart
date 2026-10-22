import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bloque les captures et l'enregistrement d'écran sur les écrans sensibles
/// (Android : FLAG_SECURE, iOS : couche UITextField sécurisée).
///
/// Compteur de références : la protection reste active tant qu'au moins un
/// écran l'a demandée (ex. page planning + popup programme ouverte dessus).
class ScreenSecurityService {
  ScreenSecurityService._();

  static const _channel = MethodChannel('team.oustad.security');
  static int _activeCount = 0;

  static bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> acquire() async {
    _activeCount++;
    if (_activeCount == 1) await _setBlocked(true);
  }

  static Future<void> release() async {
    if (_activeCount == 0) return;
    _activeCount--;
    if (_activeCount == 0) await _setBlocked(false);
  }

  static Future<void> _setBlocked(bool blocked) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('setScreenCaptureBlocked', blocked);
      debugPrint(
        blocked
            ? '🔒 Protection des screenshots activée'
            : '🔓 Protection des screenshots désactivée',
      );
    } catch (e) {
      debugPrint('⚠️ Erreur protection screenshots: $e');
    }
  }
}
