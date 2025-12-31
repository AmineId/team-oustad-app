import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Service pour la gestion des bannières
class BannerService {
  final ApiService _apiService;
  static const String _cacheKey = 'cached_banners';
  static const String _cacheTimestampKey = 'banners_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  BannerService(this._apiService);

  /// Récupérer les bannières actives depuis l'API avec cache
  Future<List<BannerModel>> getActiveBanners({
    BannerType? type,
    int? gymId,
    bool forceRefresh = false,
  }) async {
    try {
      // Vérifier le cache si pas de forceRefresh
      if (!forceRefresh) {
        final cachedBanners = await _getCachedBanners();
        if (cachedBanners != null) {
          return _filterBanners(cachedBanners, type: type, gymId: gymId);
        }
      }

      // Récupérer depuis l'API
      final bannersData = await _apiService.getBanners(
        type: type?.name,
        gymId: gymId,
        activeOnly: true,
      );

      if (bannersData == null) {
        return [];
      }

      // Convertir en modèles
      final banners = bannersData
          .map((data) => BannerModel.fromJson(data as Map<String, dynamic>))
          .toList();

      // Trier par priorité et date
      banners.sort((a, b) {
        // D'abord par priorité (décroissant)
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        
        // Ensuite par date de début (plus récent en premier)
        return b.startDate.compareTo(a.startDate);
      });

      // Mettre en cache
      await _cacheBanners(banners);

      return banners;
    } catch (e) {
      debugPrint('Error getting active banners: $e');
      return [];
    }
  }

  /// Récupérer une bannière spécifique
  Future<BannerModel?> getBannerById(int bannerId) async {
    try {
      final bannerData = await _apiService.getBannerById(bannerId);
      if (bannerData == null) return null;

      return BannerModel.fromJson(bannerData);
    } catch (e) {
      debugPrint('Error getting banner by id: $e');
      return null;
    }
  }

  /// Créer une nouvelle bannière (Admin/Owner)
  Future<BannerModel?> createBanner(
    Map<String, dynamic> bannerData,
    String token,
  ) async {
    try {
      final result = await _apiService.createBanner(bannerData, token);
      if (result == null) return null;

      // Invalider le cache
      await _clearCache();

      return BannerModel.fromJson(result);
    } catch (e) {
      debugPrint('Error creating banner: $e');
      return null;
    }
  }

  /// Mettre à jour une bannière (Admin/Owner)
  Future<BannerModel?> updateBanner(
    int bannerId,
    Map<String, dynamic> bannerData,
    String token,
  ) async {
    try {
      final result = await _apiService.updateBanner(
        bannerId,
        bannerData,
        token,
      );
      if (result == null) return null;

      // Invalider le cache
      await _clearCache();

      return BannerModel.fromJson(result);
    } catch (e) {
      debugPrint('Error updating banner: $e');
      return null;
    }
  }

  /// Supprimer une bannière (Admin/Owner)
  Future<bool> deleteBanner(int bannerId, String token) async {
    try {
      final success = await _apiService.deleteBanner(bannerId, token);
      
      if (success) {
        // Invalider le cache
        await _clearCache();
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting banner: $e');
      return false;
    }
  }

  /// Tracker la vue d'une bannière
  Future<void> trackView(int bannerId) async {
    try {
      await _apiService.trackBannerView(bannerId);
    } catch (e) {
      debugPrint('Error tracking banner view: $e');
    }
  }

  /// Tracker le clic sur une bannière
  Future<void> trackClick(int bannerId) async {
    try {
      await _apiService.trackBannerClick(bannerId);
    } catch (e) {
      debugPrint('Error tracking banner click: $e');
    }
  }

  /// Récupérer les statistiques d'une bannière (Admin/Owner)
  Future<Map<String, dynamic>?> getBannerStats(
    int bannerId,
    String token,
  ) async {
    try {
      return await _apiService.getBannerStats(bannerId, token);
    } catch (e) {
      debugPrint('Error getting banner stats: $e');
      return null;
    }
  }

  /// Filtrer les bannières selon des critères
  List<BannerModel> _filterBanners(
    List<BannerModel> banners, {
    BannerType? type,
    int? gymId,
  }) {
    return banners.where((banner) {
      // Filtrer par type
      if (type != null && banner.type != type) {
        return false;
      }

      // Filtrer par salle
      if (gymId != null && banner.gymId != null && banner.gymId != gymId) {
        return false;
      }

      // Vérifier que la bannière est actuellement active
      return banner.isCurrentlyActive;
    }).toList();
  }

  /// Mettre en cache les bannières
  Future<void> _cacheBanners(List<BannerModel> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bannersJson = banners.map((b) => b.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(bannersJson));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error caching banners: $e');
    }
  }

  /// Récupérer les bannières depuis le cache
  Future<List<BannerModel>?> _getCachedBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier l'expiration du cache
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return null;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        return null; // Cache expiré
      }

      // Récupérer depuis le cache
      final bannersJson = prefs.getString(_cacheKey);
      if (bannersJson == null) return null;

      final List<dynamic> bannersList = jsonDecode(bannersJson);
      return bannersList
          .map((data) => BannerModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting cached banners: $e');
      return null;
    }
  }

  /// Vider le cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      debugPrint('Error clearing banners cache: $e');
    }
  }

  /// Vérifier si le cache est valide
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheDuration.inMilliseconds;
    } catch (e) {
      return false;
    }
  }

  /// Forcer le rafraîchissement des bannières
  Future<List<BannerModel>> refreshBanners({
    BannerType? type,
    int? gymId,
  }) async {
    return getActiveBanners(
      type: type,
      gymId: gymId,
      forceRefresh: true,
    );
  }
}
