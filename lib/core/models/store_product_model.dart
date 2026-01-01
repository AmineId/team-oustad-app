import 'package:flutter/foundation.dart';

/// Modèle pour les produits du store
class StoreProduct {
  final int? id;
  final String? displayId;
  final String name;
  final String? description;
  final String? imageUrl; // Image principale (première de la liste)
  final List<String> imageUrls; // Toutes les images
  final double price;
  final int stock;
  final int reservedStock;
  final int availableStock;
  final bool isActive;
  final String? category;
  final int? gymId;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoreProduct({
    this.id,
    this.displayId,
    required this.name,
    this.description,
    this.imageUrl,
    this.imageUrls = const [],
    required this.price,
    required this.stock,
    this.reservedStock = 0,
    this.availableStock = 0,
    this.isActive = true,
    this.category,
    this.gymId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Catégories prédéfinies
  static const List<String> categories = [
    'Nutrition',
    'Suppléments',
    'Vêtements',
    'Accessoires',
    'Équipement',
    'Boissons',
    'Autre',
  ];

  /// Créer depuis JSON
  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    // Récupérer les images base64 (nouveau format: imagesBase64)
    List<String> images = [];
    
    debugPrint('🖼️ StoreProduct.fromJson: ${json['name']}');
    debugPrint('🖼️ Has imagesBase64: ${json.containsKey('imagesBase64')}');
    debugPrint('🖼️ Has images: ${json.containsKey('images')}');
    debugPrint('🖼️ Has imageUrl: ${json.containsKey('imageUrl')}');
    
    if (json['imagesBase64'] != null && json['imagesBase64'] is List) {
      images = (json['imagesBase64'] as List).map((e) => e.toString()).toList();
      debugPrint('🖼️ imagesBase64 count: ${images.length}');
      if (images.isNotEmpty) {
        debugPrint('🖼️ First image starts with: ${images.first.substring(0, 30)}...');
      }
    } else if (json['images'] != null && json['images'] is List) {
      // Fallback ancien format
      images = (json['images'] as List).map((e) => e.toString()).toList();
      debugPrint('🖼️ images (legacy) count: ${images.length}');
    }
    
    // Image principale (première de la liste ou imageUrl legacy)
    String? mainImage = json['imageUrl'] as String?;
    if (mainImage == null && images.isNotEmpty) {
      mainImage = images.first;
    }
    
    debugPrint('🖼️ Final imageUrl: ${mainImage?.substring(0, 30)}...');
    debugPrint('🖼️ Final imageUrls count: ${images.length}');
    debugPrint('');
    
    return StoreProduct(
      id: json['id'] as int?,
      displayId: json['displayId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: mainImage,
      imageUrls: images,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      reservedStock: json['reservedStock'] as int? ?? 0,
      availableStock: json['availableStock'] as int? ?? json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      category: json['category'] as String?,
      gymId: json['gymId'] as int?,
      createdBy: json['createdBy'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrls.isNotEmpty) 'imagesBase64': imageUrls,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      if (category != null) 'category': category,
      if (gymId != null) 'gymId': gymId,
    };
  }

  /// Copie avec modifications
  StoreProduct copyWith({
    int? id,
    String? displayId,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    double? price,
    int? stock,
    int? reservedStock,
    int? availableStock,
    bool? isActive,
    String? category,
    int? gymId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      reservedStock: reservedStock ?? this.reservedStock,
      availableStock: availableStock ?? this.availableStock,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      gymId: gymId ?? this.gymId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si le produit a des images
  bool get hasImages => imageUrls.isNotEmpty || imageUrl != null;
  
  /// Nombre d'images
  int get imageCount => imageUrls.isNotEmpty ? imageUrls.length : (imageUrl != null ? 1 : 0);
  
  /// Vérifie si une chaîne est une image base64
  static bool isBase64Image(String? image) {
    if (image == null) return false;
    return image.startsWith('data:image') || 
           (!image.startsWith('http') && image.length > 100);
  }
  
  /// Liste des images à afficher (gère base64 et URLs)
  List<String> get displayImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null) return [imageUrl!];
    return [];
  }

  /// Vérifie si le produit est en rupture de stock
  bool get isOutOfStock => availableStock <= 0;

  /// Vérifie si le stock est faible (< 5)
  bool get isLowStock => availableStock > 0 && availableStock < 5;

  /// Prix formaté
  String get formattedPrice => '${price.toStringAsFixed(2)} MAD';
}
