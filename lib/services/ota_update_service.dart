import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

/// Service de mise à jour OTA (Over-The-Air)
/// Vérifie et installe automatiquement les mises à jour de l'application
class OTAUpdateService {
  static final OTAUpdateService _instance = OTAUpdateService._internal();
  factory OTAUpdateService() => _instance;
  OTAUpdateService._internal();

  // URL du serveur qui héberge les informations de mise à jour
  // Détermine automatiquement l'URL selon l'environnement
  static String get _updateCheckUrl {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    
    // Si une URL custom est définie, l'utiliser en priorité
    const customUrl = String.fromEnvironment('UPDATE_CHECK_URL', defaultValue: '');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    
    // Sinon, déterminer selon l'environnement
    switch (environment) {
      case 'pprod':
        return 'https://app.team-oustad.com/android/beta/check-update';
      case 'prod':
        return 'https://app.team-oustad.com/android/check-update';
      case 'dev':
      default:
        return 'http://localhost:3000/android/check-update';
    }
  }

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  /// Vérifie s'il y a une mise à jour disponible
  Future<UpdateInfo?> checkForUpdate() async {
    if (_isChecking) return null;
    
    _isChecking = true;
    
    try {
      // Récupérer la version actuelle de l'app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      // Vérifier auprès du serveur avec le paramètre current_version
      final url = '$_updateCheckUrl?current_version=$currentBuildNumber';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Vérifier si une mise à jour est disponible
        final updateAvailable = data['update_available'] as bool? ?? false;
        if (!updateAvailable) {
          return null; // Pas de mise à jour disponible
        }
        
        // Récupérer les informations de la dernière version
        final versionData = data['latest_version'];
        if (versionData == null) {
          return null; // Pas de données de version
        }
        
        final latestVersion = versionData['version_name'] as String;
        final latestBuildNumber = versionData['version_code'] as int;
        final downloadUrl = versionData['download_url'] as String;
        final changelog = versionData['changelog'] as String? ?? 'Nouvelles fonctionnalités et corrections';
        final forceUpdate = versionData['force_update'] as bool? ?? false;
        final minSupportedVersion = versionData['min_supported_version'] as int?;

        // Retourner les informations de mise à jour
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          currentBuildNumber: currentBuildNumber,
          latestBuildNumber: latestBuildNumber,
          downloadUrl: downloadUrl,
          changelog: changelog,
          forceUpdate: forceUpdate,
          minSupportedVersion: minSupportedVersion,
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de mise à jour: $e');
      return null;
    } finally {
      _isChecking = false;
    }
  }

  /// Télécharge et installe la mise à jour (Android uniquement)
  Future<bool> downloadAndInstallUpdate(
    UpdateInfo updateInfo, {
    Function(double)? onProgress,
  }) async {
    if (_isDownloading) return false;
    
    // Ne fonctionne que sur Android
    if (!Platform.isAndroid) {
      debugPrint('⚠️ OTA update non supporté sur cette plateforme');
      return false;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      // Créer un dossier temporaire pour le téléchargement
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/app_update.apk';
      final file = File(filePath);

      // Supprimer l'ancien fichier s'il existe
      if (await file.exists()) {
        await file.delete();
      }

      // Télécharger le fichier APK
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        debugPrint('❌ Erreur de téléchargement: ${response.statusCode}');
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final sink = file.openWrite();
      
      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (contentLength > 0) {
          _downloadProgress = downloadedBytes / contentLength;
          onProgress?.call(_downloadProgress);
        }
      }

      await sink.close();

      debugPrint('✅ Téléchargement terminé: $filePath');

      // Installer l'APK (nécessite les permissions appropriées)
      // Note: L'installation nécessite l'interaction utilisateur sur Android
      await _installApk(filePath);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du téléchargement/installation: $e');
      return false;
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
    }
  }

  /// Installe l'APK téléchargé (Android uniquement)
  Future<void> _installApk(String filePath) async {
    if (!Platform.isAndroid) return;

    try {
      // Sur Android, on utilise un intent pour installer l'APK
      // Cela nécessite le package android_intent_plus ou similar
      // Pour l'instant, on log juste le chemin
      debugPrint('📦 APK prêt à être installé: $filePath');
      debugPrint('💡 L\'utilisateur doit installer manuellement l\'APK');
      
      // TODO: Implémenter l'installation automatique avec android_intent_plus
      // Example:
      // final AndroidIntent intent = AndroidIntent(
      //   action: 'android.intent.action.VIEW',
      //   data: 'file://$filePath',
      //   type: 'application/vnd.android.package-archive',
      //   flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      // );
      // await intent.launch();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'installation: $e');
    }
  }

  /// Vérifie automatiquement les mises à jour (appelé au démarrage)
  Future<void> autoCheckForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si l'auto-update est activé
      final autoUpdateEnabled = prefs.getBool('auto_update_enabled') ?? true;
      if (!autoUpdateEnabled) return;

      // Vérifier la dernière fois qu'on a vérifié (éviter de vérifier trop souvent)
      final lastCheck = prefs.getInt('last_update_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const checkInterval = 24 * 60 * 60 * 1000; // 24 heures

      if (now - lastCheck < checkInterval) {
        debugPrint('ℹ️ Dernière vérification récente, skip');
        return;
      }

      // Sauvegarder la date de vérification
      await prefs.setInt('last_update_check', now);

      // Vérifier les mises à jour
      final updateInfo = await checkForUpdate();
      
      if (updateInfo != null) {
        debugPrint('🆕 Mise à jour disponible: ${updateInfo.latestVersion}');
        // La notification de mise à jour sera gérée par l'UI
      } else {
        debugPrint('✅ Application à jour');
      }
    } catch (e) {
      debugPrint('❌ Erreur auto-check: $e');
    }
  }

  /// Getters pour l'état actuel
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
}

/// Informations sur une mise à jour disponible
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuildNumber;
  final int latestBuildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  final int? minSupportedVersion;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuildNumber,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
    this.minSupportedVersion,
  });

  /// Construit une info de mise à jour depuis JSON
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      currentVersion: json['currentVersion'] as String,
      latestVersion: json['version'] as String,
      currentBuildNumber: json['currentBuildNumber'] as int,
      latestBuildNumber: json['buildNumber'] as int,
      downloadUrl: json['downloadUrl'] as String,
      changelog: json['changelog'] as String? ?? 'Nouvelles fonctionnalités',
      forceUpdate: json['force_update'] as bool? ?? false,
      minSupportedVersion: json['min_supported_version'] as int?,
    );
  }

  /// Détermine si la mise à jour est critique (force l'utilisateur à mettre à jour)
  bool get isCritical {
    if (minSupportedVersion == null) return forceUpdate;
    
    // Comparer le build number actuel avec la version minimale supportée
    return currentBuildNumber < minSupportedVersion!;
  }

  /// Alias pour la compatibilité (deprecated)
  @Deprecated('Use forceUpdate instead')
  bool get isMandatory => forceUpdate;
}
