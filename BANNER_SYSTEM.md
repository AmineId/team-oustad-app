# Système de Bannières Saisonnières

Ce document décrit l'architecture complète du système de bannières saisonnières pour l'application Team Fitness.

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Modèles de données](#modèles-de-données)
4. [Services](#services)
5. [Widgets](#widgets)
6. [Intégration](#intégration)
7. [API Backend](#api-backend)
8. [Utilisation](#utilisation)

## 🎯 Vue d'ensemble

Le système de bannières permet d'afficher des bannières saisonnières, événementielles ou promotionnelles dans l'application. Les bannières sont:
- **Cliquables** avec différents types d'actions (navigation, URL externe, détails)
- **Saisonnières** avec dates de début et fin
- **Personnalisables** avec images, couleurs et priorités
- **Trackées** avec statistiques de vues et clics
- **Filtrables** par type et salle de sport

## 🏗️ Architecture

L'architecture est modulaire et suit le pattern **Clean Architecture** :

```
lib/
├── core/
│   ├── models/
│   │   ├── banner_model.dart          # Modèle de bannière
│   │   ├── banner_action.dart         # Types d'actions
│   │   └── models.dart                # Barrel file
│   └── services/
│       ├── api_service.dart           # Endpoints API (étendu)
│       ├── banner_service.dart        # Business logic
│       └── services.dart              # Barrel file
├── widgets/
│   └── common/
│       ├── banner_card.dart           # Carte de bannière
│       ├── banner_carousel.dart       # Carrousel auto-scroll
│       └── common_widgets.dart        # Barrel file
└── screens/
    ├── member/
    │   └── member_home_screen.dart    # Intégration membre
    └── admin/
        └── admin_home_screen.dart     # Intégration admin
```

## 📦 Modèles de données

### BannerModel

Représente une bannière avec toutes ses propriétés :

```dart
class BannerModel {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? imageBase64;
  final BannerType type;           // seasonal, event, promotion, info, announcement
  final DateTime startDate;
  final DateTime endDate;
  final BannerAction action;
  final int priority;
  final bool isActive;
  final int? gymId;                // null = toutes les salles
  final String? backgroundColor;
  final String? textColor;
  final int viewCount;
  final int clickCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Propriétés calculées:**
- `isCurrentlyActive`: Vérifie si la bannière est dans sa période de validité
- `clickThroughRate`: Calcule le taux de clic (CTR) en pourcentage

### BannerAction

Définit l'action à exécuter lors du clic :

```dart
enum BannerActionType {
  navigate,      // Navigation vers un écran
  externalUrl,   // Ouvrir URL externe
  showDetails,   // Afficher modal détails
  none,          // Aucune action
}

class BannerAction {
  final BannerActionType type;
  final String? data;               // Route ou URL
  final Map<String, dynamic>? params;
}
```

## 🔧 Services

### BannerService

Service de gestion business logic avec cache local (1h) :

**Méthodes principales:**

```dart
// Récupérer bannières actives (avec cache)
Future<List<BannerModel>> getActiveBanners({
  BannerType? type,
  int? gymId,
  bool forceRefresh = false,
})

// Récupérer bannière spécifique
Future<BannerModel?> getBannerById(int bannerId)

// Créer bannière (Admin/Owner)
Future<BannerModel?> createBanner(Map<String, dynamic> data, String token)

// Mettre à jour bannière (Admin/Owner)
Future<BannerModel?> updateBanner(int id, Map<String, dynamic> data, String token)

// Supprimer bannière (Admin/Owner)
Future<bool> deleteBanner(int id, String token)

// Tracking
Future<void> trackView(int bannerId)
Future<void> trackClick(int bannerId)

// Statistiques (Admin/Owner)
Future<Map<String, dynamic>?> getBannerStats(int bannerId, String token)
```

**Fonctionnalités:**
- ✅ Cache local avec SharedPreferences (1h)
- ✅ Tri automatique par priorité et date
- ✅ Filtrage par type et salle
- ✅ Validation des dates actives
- ✅ Invalidation cache après modifications

### ApiService (étendu)

Endpoints ajoutés pour l'API backend :

```dart
// GET /banners
Future<List<dynamic>?> getBanners({String? type, int? gymId, bool activeOnly})

// GET /banners/{id}
Future<Map<String, dynamic>?> getBannerById(int bannerId)

// POST /banners
Future<Map<String, dynamic>?> createBanner(Map<String, dynamic> data, String token)

// PUT /banners/{id}
Future<Map<String, dynamic>?> updateBanner(int id, Map<String, dynamic> data, String token)

// DELETE /banners/{id}
Future<bool> deleteBanner(int bannerId, String token)

// POST /banners/{id}/track/view
Future<bool> trackBannerView(int bannerId)

// POST /banners/{id}/track/click
Future<bool> trackBannerClick(int bannerId)

// GET /banners/{id}/stats
Future<Map<String, dynamic>?> getBannerStats(int bannerId, String token)
```

## 🎨 Widgets

### BannerCard

Carte de bannière individuelle avec :
- Image de fond (URL ou base64)
- Gradient overlay
- Badge de type
- Titre et description
- Statistiques (mode admin)
- Gestion des couleurs personnalisées

```dart
BannerCard(
  banner: banner,
  onTap: () => handleTap(banner),
  showStatistics: true,  // Afficher stats (admin)
  height: 180,
)
```

### BannerCarousel

Carrousel avec auto-scroll :
- PageView avec indicateurs
- Auto-scroll configurable
- Tracking automatique des vues
- Gestion des actions (navigation, URL, détails)
- Modal de détails intégrée
- Mode skeleton pendant chargement

```dart
BannerCarousel(
  gymId: gymId,              // Filtrer par salle
  filterType: BannerType.seasonal,  // Filtrer par type
  height: 180,
  autoScroll: true,
  autoScrollDuration: Duration(seconds: 5),
  showStatistics: true,      // Mode admin
)
```

## 🔗 Intégration

### Dans MemberHomeScreen

```dart
Column(
  children: [
    // Carrousel de bannières
    BannerCarousel(
      height: 180,
      autoScroll: true,
    ),
    SizedBox(height: 16),
    
    // Reste du contenu...
  ],
)
```

### Dans AdminHomeScreen

```dart
BannerCarousel(
  height: 180,
  autoScroll: true,
  showStatistics: true,  // Affiche vues, clics et CTR
)
```

## 🌐 API Backend

Voir `swagger.yml` pour la documentation complète.

### Endpoints principaux

#### GET /banners
Récupère les bannières actives avec filtres optionnels.

**Query parameters:**
- `type`: seasonal | event | promotion | info | announcement
- `gymId`: ID de la salle
- `activeOnly`: true/false (défaut: true)

**Response:**
```json
{
  "banners": [
    {
      "id": 1,
      "title": "Offre spéciale été",
      "description": "Profitez de -30%",
      "imageUrl": "https://...",
      "type": "seasonal",
      "startDate": "2024-06-01T00:00:00Z",
      "endDate": "2024-08-31T23:59:59Z",
      "action": {
        "type": "navigate",
        "data": "/subscriptions"
      },
      "priority": 10,
      "isActive": true,
      "gymId": null,
      "viewCount": 150,
      "clickCount": 25
    }
  ]
}
```

#### POST /banners
Créer une bannière (Admin/Owner).

**Body:**
```json
{
  "title": "Offre spéciale",
  "description": "Description",
  "imageUrl": "https://...",
  "type": "promotion",
  "startDate": "2024-06-01T00:00:00Z",
  "endDate": "2024-08-31T23:59:59Z",
  "action": {
    "type": "externalUrl",
    "data": "https://teamfitness.com/promo"
  },
  "priority": 5,
  "isActive": true,
  "gymId": 1
}
```

#### POST /banners/{id}/track/view
Enregistrer une vue de bannière.

#### POST /banners/{id}/track/click
Enregistrer un clic sur une bannière.

## 📖 Utilisation

### Exemple complet

```dart
import 'package:flutter/material.dart';
import '../../widgets/common/common_widgets.dart';
import '../../core/models/models.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carrousel de bannières saisonnières
            BannerCarousel(
              filterType: BannerType.seasonal,
              height: 200,
              autoScroll: true,
              autoScrollDuration: Duration(seconds: 6),
            ),
            
            // Bannières événements
            BannerCarousel(
              filterType: BannerType.event,
              height: 150,
              autoScroll: false,
            ),
            
            // Reste du contenu...
          ],
        ),
      ),
    );
  }
}
```

### Créer une bannière manuellement

```dart
final bannerService = BannerService(ApiService.fromEnv());
final token = await authService.loadToken();

final bannerData = {
  'title': 'Nouvelle année, nouveau vous!',
  'description': 'Offre spéciale janvier',
  'imageUrl': 'https://example.com/banner.jpg',
  'type': 'seasonal',
  'startDate': DateTime(2025, 1, 1).toIso8601String(),
  'endDate': DateTime(2025, 1, 31).toIso8601String(),
  'action': {
    'type': 'navigate',
    'data': '/subscriptions',
  },
  'priority': 10,
  'isActive': true,
};

final banner = await bannerService.createBanner(bannerData, token);
```

## 🎯 Fonctionnalités à venir

Les écrans de gestion admin pour créer/modifier/supprimer les bannières via l'interface seront développés dans une prochaine itération.

### Écrans admin prévus:
- `AdminBannersScreen` - Liste et gestion des bannières
- `AdminCreateBannerScreen` - Création de bannière
- `AdminEditBannerScreen` - Édition de bannière
- `AdminBannerStatsScreen` - Statistiques détaillées

## 📝 Notes importantes

1. **Cache**: Les bannières sont mises en cache localement pendant 1h
2. **Tracking**: Les vues sont trackées automatiquement, les clics lors de l'interaction
3. **Filtrage**: Le filtrage par dates est automatique (startDate/endDate)
4. **Priorité**: Plus la priorité est élevée, plus la bannière est affichée en premier
5. **Salle**: Si `gymId` est null, la bannière s'affiche pour toutes les salles

## 🔒 Sécurité

- Création/modification/suppression réservées aux Admin/Owner
- Tracking des vues/clics public
- Récupération des statistiques réservée aux Admin/Owner
- Token JWT requis pour les opérations protégées

## 🚀 Performance

- Cache local pour réduire les appels API
- Chargement asynchrone des images
- Skeleton loader pendant le chargement
- Pagination possible pour grandes listes (à implémenter côté backend)

---

**Auteur**: Team Fitness Development Team  
**Version**: 1.0.0  
**Date**: 2025-01-01
