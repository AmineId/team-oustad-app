# Système de Bannières Simplifié

## 🎯 Architecture Modulaire Simplifiée

Cette version simplifie drastiquement l'architecture pour la rendre plus maintenable et utilisable partout.

### Composants

#### 1. **Modèle de données** (`lib/core/models/banner_model.dart`)

```dart
class BannerModel {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String? actionUrl;
  final bool isExternalUrl;
  final BannerStyle? style;  // Style personnalisé
}

class BannerStyle {
  final Color? gradientStart;
  final Color? gradientEnd;
  final Color? textColor;
  final double overlayOpacity;
}
```

**Caractéristiques:**
- ✅ Simple et clair
- ✅ Validation de dates automatique (`isActive`)
- ✅ Style personnalisé pour chaque bannière (gradients, couleurs)
- ✅ Action unique (URL interne ou externe)

#### 2. **Service** (`lib/core/services/banner_service.dart`)

```dart
class BannerService {
  Future<List<BannerModel>> getActiveBanners()
  Future<void> trackClick(int bannerId)
}
```

**Caractéristiques:**
- ✅ 2 méthodes seulement
- ✅ Pas de cache complexe
- ✅ Filtrage automatique par dates

#### 3. **Widget Modulaire** (`lib/widgets/common/banner_carousel.dart`)

```dart
BannerCarousel(
  height: 180,
  autoScroll: true,
  onBannerTap: (banner) => handleTap(banner),
)
```

**Caractéristiques:**
- ✅ Auto-masquage si pas de bannières
- ✅ Auto-scroll configurable
- ✅ Callback personnalisable
- ✅ Style personnalisé par bannière
- ✅ Gestion d'actions automatique

### API Backend (Simplifié)

**2 endpoints seulement:**

```
GET /banners?activeOnly=true
POST /banners/{id}/click
```

### Utilisation

#### 1. Simple - Partout dans l'app

```dart
const BannerCarousel(height: 180)
```

#### 2. Avec callback personnalisé

```dart
BannerCarousel(
  height: 200,
  onBannerTap: (banner) {
    // Gestion personnalisée
    Navigator.pushNamed(context, banner.actionUrl);
  },
)
```

#### 3. Style personnalisé

```dart
BannerCarousel(
  height: 180,
  margin: EdgeInsets.all(8),
  borderRadius: BorderRadius.circular(24),
)
```

### Exemple JSON (Backend)

```json
{
  "banners": [
    {
      "id": 1,
      "title": "Offre Spéciale Été",
      "description": "Profitez de -30%",
      "imageUrl": "https://example.com/banner.jpg",
      "startDate": "2024-06-01T00:00:00Z",
      "endDate": "2024-08-31T23:59:59Z",
      "actionUrl": "/subscriptions",
      "isExternalUrl": false,
      "style": {
        "gradientStart": "#FF5733",
        "gradientEnd": "#C70039",
        "textColor": "#FFFFFF",
        "overlayOpacity": 0.6
      }
    }
  ]
}
```

### Avantages vs Version Précédente

| Aspect | Avant | Maintenant |
|--------|-------|------------|
| **Modèles** | 2 fichiers, 5 types | 1 fichier, simple |
| **Service** | 250+ lignes, cache complexe | 40 lignes, simple |
| **API** | 8 endpoints | 2 endpoints |
| **Widget** | 2 fichiers, 400+ lignes | 1 fichier, 300 lignes intégré |
| **Utilisation** | Config complexe | 1 ligne de code |
| **Style** | Couleurs fixes | Gradients personnalisés |

### Fonctionnalités Clés

✅ **Auto-masquage** - Pas de bannières = pas d'affichage  
✅ **Style personnalisé** - Gradient et couleurs par bannière  
✅ **Modulaire** - Utilisable partout avec 1 ligne  
✅ **Simple** - Pas de configuration complexe  
✅ **Performant** - Chargement optimisé  
✅ **Flexible** - Callback personnalisable  

### Migration Backend

Le backend doit simplement:
1. **GET /banners** - Retourner les bannières actives avec dates et style
2. **POST /banners/{id}/click** - Logger les clics

C'est tout! Plus besoin de:
- ❌ Endpoints CRUD admin
- ❌ Tracking de vues
- ❌ Statistiques
- ❌ Filtrage complexe

---

**Version:** 2.0 - Simplifiée  
**Date:** 2025-01-01  
**Statut:** ✅ Prêt pour production
