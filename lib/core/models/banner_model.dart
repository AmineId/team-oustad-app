import 'banner_action.dart';

/// Types de bannières
enum BannerType {
  /// Bannière saisonnière (Noël, été, etc.)
  seasonal,
  
  /// Bannière d'événement ponctuel
  event,
  
  /// Bannière de promotion
  promotion,
  
  /// Bannière informative
  info,
  
  /// Bannière d'annonce
  announcement,
}

/// Modèle de bannière pour affichage dans l'application
class BannerModel {
  /// Identifiant unique
  final int id;
  
  /// Titre de la bannière
  final String title;
  
  /// Description détaillée
  final String? description;
  
  /// URL de l'image
  final String imageUrl;
  
  /// Image en base64 (optionnel, pour cache local)
  final String? imageBase64;
  
  /// Type de bannière
  final BannerType type;
  
  /// Date de début d'affichage
  final DateTime startDate;
  
  /// Date de fin d'affichage
  final DateTime endDate;
  
  /// Action à exécuter au clic
  final BannerAction action;
  
  /// Priorité d'affichage (plus élevé = plus prioritaire)
  final int priority;
  
  /// Bannière active ou non
  final bool isActive;
  
  /// ID de la salle (null = toutes les salles)
  final int? gymId;
  
  /// Couleur de fond (optionnel)
  final String? backgroundColor;
  
  /// Couleur du texte (optionnel)
  final String? textColor;
  
  /// Nombre de vues
  final int viewCount;
  
  /// Nombre de clics
  final int clickCount;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Date de dernière mise à jour
  final DateTime? updatedAt;

  const BannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.imageBase64,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.action,
    this.priority = 0,
    this.isActive = true,
    this.gymId,
    this.backgroundColor,
    this.textColor,
    this.viewCount = 0,
    this.clickCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Vérifie si la bannière est actuellement active (dans la période)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  /// Taux de clic (CTR)
  double get clickThroughRate {
    if (viewCount == 0) return 0.0;
    return (clickCount / viewCount) * 100;
  }

  /// Créer depuis JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      imageBase64: json['imageBase64'] as String?,
      type: BannerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BannerType.info,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      action: json['action'] != null
          ? BannerAction.fromJson(json['action'] as Map<String, dynamic>)
          : BannerAction.none(),
      priority: json['priority'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      gymId: json['gymId'] as int?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      clickCount: json['clickCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'imageUrl': imageUrl,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'action': action.toJson(),
      'priority': priority,
      'isActive': isActive,
      if (gymId != null) 'gymId': gymId,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
      'viewCount': viewCount,
      'clickCount': clickCount,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Créer une copie avec des modifications
  BannerModel copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    String? imageBase64,
    BannerType? type,
    DateTime? startDate,
    DateTime? endDate,
    BannerAction? action,
    int? priority,
    bool? isActive,
    int? gymId,
    String? backgroundColor,
    String? textColor,
    int? viewCount,
    int? clickCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      gymId: gymId ?? this.gymId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      viewCount: viewCount ?? this.viewCount,
      clickCount: clickCount ?? this.clickCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, type: $type, priority: $priority, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BannerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
