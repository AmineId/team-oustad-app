import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Service complet pour la gestion des bannières
class BannerService {
  final ApiService _apiService;
  String? _token;

  BannerService(this._apiService);

  /// Set the token for authenticated requests
  void setToken(String? token) {
    _token = token;
  }

  /// Récupérer toutes les bannières (admin/owner)
  Future<List<BannerModel>> getAllBanners({
    BannerType? type,
    int? gymId,
    bool activeOnly = false,
    String? token,
  }) async {
    try {
      final bannersData = await _apiService.getBanners(
        token: token ?? _token,
        type: type?.name,
        gymId: gymId,
        activeOnly: activeOnly,
      );
      if (bannersData == null) return [];

      return bannersData
          .map((data) => BannerModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting banners: $e');
      return [];
    }
  }

  /// Récupérer les bannières actives (pour affichage)
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final bannersData = await _apiService.getBanners(activeOnly: true);
      if (bannersData == null) return [];

      return bannersData
          .map((data) => BannerModel.fromJson(data as Map<String, dynamic>))
          .where((banner) => banner.isCurrentlyActive)
          .toList();
    } catch (e) {
      debugPrint('Error getting active banners: $e');
      return [];
    }
  }

  /// Récupérer une bannière par ID
  Future<BannerModel?> getBanner(int id, {String? token}) async {
    try {
      final data = await _apiService.getBanner(id, token: token ?? _token);
      if (data == null) return null;
      return BannerModel.fromJson(data);
    } catch (e) {
      debugPrint('Error getting banner $id: $e');
      return null;
    }
  }

  /// Créer une nouvelle bannière
  Future<BannerModel?> createBanner(BannerModel banner, {String? token}) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      final data = await _apiService.createBanner(authToken, banner.toJson());
      if (data == null) return null;
      return BannerModel.fromJson(data);
    } catch (e) {
      debugPrint('Error creating banner: $e');
      rethrow;
    }
  }

  /// Mettre à jour une bannière
  Future<BannerModel?> updateBanner(
    int id,
    BannerModel banner, {
    String? token,
  }) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      final data = await _apiService.updateBanner(
        authToken,
        id,
        banner.toJson(),
      );
      if (data == null) return null;
      return BannerModel.fromJson(data);
    } catch (e) {
      debugPrint('Error updating banner $id: $e');
      rethrow;
    }
  }

  /// Supprimer une bannière
  Future<bool> deleteBanner(int id, {String? token}) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      await _apiService.deleteBanner(authToken, id);
      return true;
    } catch (e) {
      debugPrint('Error deleting banner $id: $e');
      return false;
    }
  }

  /// Tracker une vue
  Future<void> trackView(int bannerId) async {
    try {
      await _apiService.trackBannerView(bannerId);
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  /// Tracker un clic
  Future<void> trackClick(int bannerId) async {
    try {
      await _apiService.trackBannerClick(bannerId);
    } catch (e) {
      debugPrint('Error tracking click: $e');
    }
  }

  /// Récupérer les statistiques d'une bannière
  Future<Map<String, dynamic>?> getBannerStats(
    int bannerId, {
    String? token,
  }) async {
    try {
      return await _apiService.getBannerStats(bannerId, token: token ?? _token);
    } catch (e) {
      debugPrint('Error getting banner stats: $e');
      return null;
    }
  }
}
