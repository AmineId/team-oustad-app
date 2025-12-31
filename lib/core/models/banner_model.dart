import 'package:flutter/material.dart';

/// Modèle simplifié de bannière/événement
class BannerModel {
  /// Identifiant unique
  final int id;
  
  /// Titre
  final String title;
  
  /// Description (optionnelle)
  final String? description;
  
  /// URL de l'image
  final String imageUrl;
  
  /// Date de début
  final DateTime startDate;
  
  /// Date de fin
  final DateTime endDate;
  
  /// Action au clic (route ou URL)
  final String? actionUrl;
  
  /// Type d'action (navigation interne ou URL externe)
  final bool isExternalUrl;
  
  /// Style personnalisé pour le fond
  final BannerStyle? style;
  
  const BannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    this.actionUrl,
    this.isExternalUrl = false,
    this.style,
  });

  /// Vérifie si la bannière est active (dans la période)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Créer depuis JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      actionUrl: json['actionUrl'] as String?,
      isExternalUrl: json['isExternalUrl'] as bool? ?? false,
      style: json['style'] != null
          ? BannerStyle.fromJson(json['style'] as Map<String, dynamic>)
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (actionUrl != null) 'actionUrl': actionUrl,
      'isExternalUrl': isExternalUrl,
      if (style != null) 'style': style!.toJson(),
    };
  }
}

/// Style personnalisé pour la bannière
class BannerStyle {
  /// Couleur de début du gradient
  final Color? gradientStart;
  
  /// Couleur de fin du gradient
  final Color? gradientEnd;
  
  /// Couleur du texte
  final Color? textColor;
  
  /// Opacité de l'overlay (0.0 - 1.0)
  final double overlayOpacity;

  const BannerStyle({
    this.gradientStart,
    this.gradientEnd,
    this.textColor,
    this.overlayOpacity = 0.5,
  });

  factory BannerStyle.fromJson(Map<String, dynamic> json) {
    return BannerStyle(
      gradientStart: json['gradientStart'] != null
          ? Color(int.parse(json['gradientStart'].toString().replaceFirst('#', '0xFF')))
          : null,
      gradientEnd: json['gradientEnd'] != null
          ? Color(int.parse(json['gradientEnd'].toString().replaceFirst('#', '0xFF')))
          : null,
      textColor: json['textColor'] != null
          ? Color(int.parse(json['textColor'].toString().replaceFirst('#', '0xFF')))
          : null,
      overlayOpacity: json['overlayOpacity'] as double? ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gradientStart != null) 'gradientStart': '#${gradientStart!.value.toRadixString(16).substring(2)}',
      if (gradientEnd != null) 'gradientEnd': '#${gradientEnd!.value.toRadixString(16).substring(2)}',
      if (textColor != null) 'textColor': '#${textColor!.value.toRadixString(16).substring(2)}',
      'overlayOpacity': overlayOpacity,
    };
  }
}
