import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

import 'api_service.dart';

/// Vérification de version, sur toutes les plateformes.
/// Compare le build number installé à la dernière version publiée ; la mise à
/// jour elle-même passe par le store (Play Store sur Android), jamais par un
/// téléchargement d'APK dans l'app.
class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=team.fitness.team_fitness_app';

  /// Seul Android a un store où renvoyer l'utilisateur.
  static bool get canOpenStore => !kIsWeb && Platform.isAndroid;

  // Même API que le reste de l'app (api-pprod sur staging, api en prod) :
  // chaque environnement publie sa propre version, sans canal beta.
  static String get _updateCheckUrl {
    // Si une URL custom est définie, l'utiliser en priorité
    const customUrl = String.fromEnvironment(
      'UPDATE_CHECK_URL',
      defaultValue: '',
    );
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    return ApiService.fromEnv().baseUri
        .resolve('/android/check-update')
        .toString();
  }

  bool _isChecking = false;

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
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

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
        final changelog =
            versionData['changelog'] as String? ??
            'Nouvelles fonctionnalités et corrections';
        final forceUpdate = versionData['force_update'] as bool? ?? false;
        final minSupportedVersion =
            versionData['min_supported_version'] as int?;

        // Retourner les informations de mise à jour
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          currentBuildNumber: currentBuildNumber,
          latestBuildNumber: latestBuildNumber,
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

  /// Ouvre la fiche Play Store de l'app (Android uniquement).
  Future<bool> openStore() async {
    if (!canOpenStore) return false;

    try {
      return await launchUrl(
        Uri.parse(playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture du Play Store: $e');
      return false;
    }
  }

  /// Getter pour l'état actuel
  bool get isChecking => _isChecking;
}

/// Informations sur une mise à jour disponible
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuildNumber;
  final int latestBuildNumber;
  final String changelog;
  final bool forceUpdate;
  final int? minSupportedVersion;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuildNumber,
    required this.latestBuildNumber,
    required this.changelog,
    required this.forceUpdate,
    this.minSupportedVersion,
  });

  /// Détermine si la mise à jour est critique (force l'utilisateur à mettre à jour)
  bool get isCritical {
    if (minSupportedVersion == null) return forceUpdate;

    // Comparer le build number actuel avec la version minimale supportée
    return currentBuildNumber < minSupportedVersion!;
  }
}
