/// Types d'actions possibles pour une bannière
enum BannerActionType {
  /// Navigation vers un écran de l'application
  navigate,
  
  /// Ouvrir une URL externe
  externalUrl,
  
  /// Afficher une modal avec plus d'informations
  showDetails,
  
  /// Aucune action
  none,
}

/// Action à exécuter lors du clic sur une bannière
class BannerAction {
  /// Type d'action
  final BannerActionType type;
  
  /// Données de l'action (route, URL, etc.)
  final String? data;
  
  /// Paramètres additionnels
  final Map<String, dynamic>? params;

  const BannerAction({
    required this.type,
    this.data,
    this.params,
  });

  /// Créer une action de navigation
  factory BannerAction.navigate(String route, {Map<String, dynamic>? params}) {
    return BannerAction(
      type: BannerActionType.navigate,
      data: route,
      params: params,
    );
  }

  /// Créer une action d'URL externe
  factory BannerAction.externalUrl(String url) {
    return BannerAction(
      type: BannerActionType.externalUrl,
      data: url,
    );
  }

  /// Créer une action de détails
  factory BannerAction.showDetails({Map<String, dynamic>? params}) {
    return BannerAction(
      type: BannerActionType.showDetails,
      params: params,
    );
  }

  /// Créer une action vide
  factory BannerAction.none() {
    return const BannerAction(
      type: BannerActionType.none,
    );
  }

  /// Convertir depuis JSON
  factory BannerAction.fromJson(Map<String, dynamic> json) {
    return BannerAction(
      type: BannerActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BannerActionType.none,
      ),
      data: json['data'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  /// Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (data != null) 'data': data,
      if (params != null) 'params': params,
    };
  }

  @override
  String toString() {
    return 'BannerAction(type: $type, data: $data, params: $params)';
  }
}
