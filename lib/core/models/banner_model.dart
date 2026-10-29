import 'package:flutter/material.dart';

/// Types de bannières disponibles
enum BannerType {
  seasonal,
  event,
  promotion,
  info,
  announcement;

  String get displayName {
    switch (this) {
      case BannerType.seasonal:
        return 'Saisonnier';
      case BannerType.event:
        return 'Événement';
      case BannerType.promotion:
        return 'Promotion';
      case BannerType.info:
        return 'Information';
      case BannerType.announcement:
        return 'Annonce';
    }
  }

  IconData get icon {
    switch (this) {
      case BannerType.seasonal:
        return Icons.wb_sunny_rounded;
      case BannerType.event:
        return Icons.event_rounded;
      case BannerType.promotion:
        return Icons.local_offer_rounded;
      case BannerType.info:
        return Icons.info_rounded;
      case BannerType.announcement:
        return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BannerType.seasonal:
        return Colors.orange;
      case BannerType.event:
        return Colors.purple;
      case BannerType.promotion:
        return Colors.green;
      case BannerType.info:
        return Colors.blue;
      case BannerType.announcement:
        return Colors.red;
    }
  }

  static BannerType fromString(String value) {
    return BannerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BannerType.info,
    );
  }
}

/// Types d'action au clic
enum BannerActionType {
  navigate,
  externalUrl,
  showDetails,
  none;

  String get displayName {
    switch (this) {
      case BannerActionType.navigate:
        return 'Navigation interne';
      case BannerActionType.externalUrl:
        return 'Lien externe';
      case BannerActionType.showDetails:
        return 'Afficher détails';
      case BannerActionType.none:
        return 'Aucune action';
    }
  }

  static BannerActionType fromString(String? value) {
    if (value == null) return BannerActionType.none;
    return BannerActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BannerActionType.none,
    );
  }
}

/// Action de la bannière
class BannerAction {
  final BannerActionType type;
  final String? data;
  final Map<String, dynamic>? params;

  const BannerAction({
    this.type = BannerActionType.none,
    this.data,
    this.params,
  });

  factory BannerAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BannerAction();
    return BannerAction(
      type: BannerActionType.fromString(json['type'] as String?),
      data: json['data'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (data != null) 'data': data,
      if (params != null) 'params': params,
    };
  }
}

/// Modèle complet de bannière/événement
class BannerModel {
  final int? id;

  /// Identifiant public, envoyé dans les push `banner` (`data.bannerId`).
  final String? displayId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? imageBase64;
  final BannerType type;
  final DateTime startDate;
  final DateTime endDate;
  final BannerAction? action;
  final int priority;
  final bool isActive;
  final int? gymId;
  final String? backgroundColor;
  final String? textColor;
  final int viewCount;
  final int clickCount;

  /// Push envoyé aux membres quand la bannière devient visible.
  final bool notifyMembers;

  /// Date d'envoi de ce push (lecture seule, posée par le serveur).
  final DateTime? notifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BannerModel({
    this.id,
    this.displayId,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageBase64,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.action,
    this.priority = 0,
    this.isActive = true,
    this.gymId,
    this.backgroundColor,
    this.textColor,
    this.viewCount = 0,
    this.clickCount = 0,
    this.notifyMembers = false,
    this.notifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Vérifie si la bannière est active (dans la période et flag isActive)
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Statut textuel
  String get statusText {
    if (!isActive) return 'Désactivée';
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'Programmée';
    if (now.isAfter(endDate)) return 'Expirée';
    return 'Active';
  }

  /// Couleur du statut
  Color get statusColor {
    if (!isActive) return Colors.grey;
    final now = DateTime.now();
    if (now.isBefore(startDate)) return Colors.orange;
    if (now.isAfter(endDate)) return Colors.red;
    return Colors.green;
  }

  /// Taux de clic
  double get clickThroughRate {
    if (viewCount == 0) return 0;
    return (clickCount / viewCount) * 100;
  }

  /// Créer depuis JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int?,
      displayId: json['displayId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageBase64: json['imageBase64'] as String?,
      type: BannerType.fromString(json['type'] as String? ?? 'info'),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      action: json['action'] != null
          ? BannerAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      priority: json['priority'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      gymId: json['gymId'] as int?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      clickCount: json['clickCount'] as int? ?? 0,
      notifyMembers: json['notifyMembers'] as bool? ?? false,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convertir vers JSON pour création/modification
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (action != null) 'action': action!.toJson(),
      'priority': priority,
      'isActive': isActive,
      'notifyMembers': notifyMembers,
      if (gymId != null) 'gymId': gymId,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
    };
  }

  /// Copie avec modifications
  BannerModel copyWith({
    int? id,
    String? displayId,
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
    bool? notifyMembers,
    DateTime? notifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
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
      notifyMembers: notifyMembers ?? this.notifyMembers,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
