import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Service simplifié pour la gestion des bannières
class BannerService {
  final ApiService _apiService;

  BannerService(this._apiService);

  /// Récupérer les bannières actives
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final bannersData = await _apiService.getBanners(activeOnly: true);
      if (bannersData == null) return [];

      // Convertir et filtrer par dates
      final banners = bannersData
          .map((data) => BannerModel.fromJson(data as Map<String, dynamic>))
          .where((banner) => banner.isActive)
          .toList();

      return banners;
    } catch (e) {
      debugPrint('Error getting banners: $e');
      return [];
    }
  }

  /// Tracker un clic sur une bannière
  Future<void> trackClick(int bannerId) async {
    try {
      await _apiService.trackBannerClick(bannerId);
    } catch (e) {
      debugPrint('Error tracking click: $e');
    }
  }
}
