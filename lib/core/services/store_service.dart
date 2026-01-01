import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Service pour la gestion des produits du store
class StoreService {
  final ApiService _apiService;
  String? _token;

  StoreService(this._apiService);

  /// Set the token for authenticated requests
  void setToken(String? token) {
    _token = token;
  }

  /// Récupérer tous les produits
  Future<List<StoreProduct>> getAllProducts({
    int? gymId,
    String? category,
    bool? available,
    String? token,
  }) async {
    try {
      final productsData = await _apiService.getStoreProducts(
        token: token ?? _token,
        gymId: gymId,
        category: category,
        available: available,
      );
      if (productsData == null) return [];

      return productsData
          .map((data) => StoreProduct.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// Récupérer les produits disponibles uniquement
  Future<List<StoreProduct>> getAvailableProducts({int? gymId}) async {
    return getAllProducts(gymId: gymId, available: true);
  }

  /// Récupérer un produit par displayId
  Future<StoreProduct?> getProduct(String displayId, {String? token}) async {
    try {
      final data = await _apiService.getStoreProduct(
        displayId,
        token: token ?? _token,
      );
      if (data == null) return null;
      return StoreProduct.fromJson(data);
    } catch (e) {
      debugPrint('Error getting product $displayId: $e');
      return null;
    }
  }

  /// Créer un nouveau produit avec plusieurs images
  Future<StoreProduct?> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
    String? category,
    int? gymId,
    List<Uint8List>? imagesBytes,
    List<String>? imageNames,
    String? token,
  }) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      final data = await _apiService.createStoreProduct(
        authToken,
        name: name,
        description: description,
        price: price,
        stock: stock,
        category: category,
        gymId: gymId,
        imagesBytes: imagesBytes,
        imageNames: imageNames,
      );
      if (data == null) return null;
      return StoreProduct.fromJson(data);
    } catch (e) {
      debugPrint('Error creating product: $e');
      rethrow;
    }
  }

  /// Mettre à jour un produit avec plusieurs images
  Future<StoreProduct?> updateProduct(
    String displayId, {
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    bool? isActive,
    List<Uint8List>? imagesBytes,
    List<String>? imageNames,
    String? token,
  }) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      final data = await _apiService.updateStoreProduct(
        authToken,
        displayId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        category: category,
        isActive: isActive,
        imagesBytes: imagesBytes,
        imageNames: imageNames,
      );
      if (data == null) return null;
      return StoreProduct.fromJson(data);
    } catch (e) {
      debugPrint('Error updating product $displayId: $e');
      rethrow;
    }
  }

  /// Supprimer un produit
  Future<bool> deleteProduct(String displayId, {String? token}) async {
    final authToken = token ?? _token;
    if (authToken == null) throw Exception('Token required');
    try {
      await _apiService.deleteStoreProduct(authToken, displayId);
      return true;
    } catch (e) {
      debugPrint('Error deleting product $displayId: $e');
      return false;
    }
  }

  /// Récupérer les produits par catégorie
  Future<List<StoreProduct>> getProductsByCategory(String category) async {
    return getAllProducts(category: category);
  }

  /// Récupérer les produits en rupture de stock
  Future<List<StoreProduct>> getOutOfStockProducts({int? gymId}) async {
    final products = await getAllProducts(gymId: gymId);
    return products.where((p) => p.isOutOfStock).toList();
  }

  /// Récupérer les produits avec stock faible
  Future<List<StoreProduct>> getLowStockProducts({int? gymId}) async {
    final products = await getAllProducts(gymId: gymId);
    return products.where((p) => p.isLowStock).toList();
  }
}
