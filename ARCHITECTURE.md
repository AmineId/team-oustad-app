# Architecture du Projet Team Fitness App

```
team_fitness_app/
│
├── lib/                                    # Code source principal
│   ├── main.dart                          # Point d'entrée
│   ├── firebase_options.dart              # Configuration Firebase
│   │
│   ├── core/                              # 🔧 CORE - Éléments fondamentaux
│   │   ├── core.dart                      # Barrel file
│   │   │
│   │   ├── services/                      # Services applicatifs
│   │   │   ├── services.dart              # Barrel
│   │   │   ├── api_service.dart           # API REST
│   │   │   ├── auth_service.dart          # Authentification
│   │   │   ├── db_service.dart            # Base de données
│   │   │   ├── error_reporter.dart        # Gestion d'erreurs
│   │   │   ├── fcm_service.dart           # Push notifications (FCM)
│   │   │   ├── notification_service.dart   # Notifications locales
│   │   │   └── ota_update_service.dart    # Mises à jour OTA
│   │   │
│   │   ├── config/                        # Configuration
│   │   │   ├── config.dart                # Barrel
│   │   │   └── app_config.dart            # Config globale
│   │   │
│   │   └── utils/                         # Utilitaires
│   │       ├── utils.dart                 # Barrel
│   │       └── platform_utils.dart        # Détection de plateforme
│   │
│   ├── screens/                           # 📱 ÉCRANS
│   │   ├── screens.dart                   # Barrel (limité)
│   │   │
│   │   ├── admin/                         # Module Administrateur
│   │   │   ├── admin_screens.dart         # Barrel
│   │   │   ├── admin_home_screen.dart
│   │   │   ├── admin_admins_list_screen.dart
│   │   │   ├── admin_create_admin_screen.dart
│   │   │   ├── admin_edit_admin_screen.dart
│   │   │   ├── admin_gyms_list_screen.dart
│   │   │   ├── admin_create_gym_screen.dart
│   │   │   ├── admin_edit_gym_screen.dart
│   │   │   ├── admin_gym_opening_hours_screen.dart
│   │   │   ├── admin_members_screen.dart
│   │   │   ├── admin_create_member_screen.dart
│   │   │   ├── admin_member_details_screen.dart
│   │   │   ├── admin_plannings_screen.dart
│   │   │   ├── admin_create_planning_screen.dart
│   │   │   ├── admin_subscription_details_screen.dart
│   │   │   └── admin_create_subscription_screen.dart
│   │   │
│   │   ├── auth/                          # Module Authentification
│   │   │   ├── auth_screens.dart          # Barrel
│   │   │   ├── login_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   └── setup_password_screen.dart
│   │   │
│   │   ├── member/                        # Module Membre
│   │   │   ├── member_screens.dart        # Barrel
│   │   │   ├── member_home_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── subscription_details_screen.dart
│   │   │
│   │   └── common/                        # Module Commun
│   │       ├── common_screens.dart        # Barrel
│   │       ├── splash_screen.dart
│   │       ├── home_screen.dart
│   │       ├── about_screen.dart
│   │       ├── security_settings_screen.dart
│   │       └── notification_test_screen.dart
│   │
│   └── widgets/                           # 🧩 WIDGETS RÉUTILISABLES
│       ├── widgets.dart                   # Barrel
│       │
│       ├── responsive/                    # Widgets responsive
│       │   ├── responsive_widgets.dart    # Barrel
│       │   ├── responsive_layout.dart
│       │   ├── responsive_grid.dart
│       │   └── responsive_card.dart
│       │
│       ├── platform/                      # Widgets plateforme
│       │   ├── platform_widgets.dart      # Barrel
│       │   ├── desktop_widgets.dart
│       │   └── watch_widgets.dart
│       │
│       └── common/                        # Widgets communs
│           ├── common_widgets.dart        # Barrel
│           └── gym_details_bottom_sheet.dart
│
├── android/                               # Configuration Android
├── ios/                                   # Configuration iOS
├── web/                                   # Configuration Web
├── windows/                               # Configuration Windows
├── linux/                                 # Configuration Linux
├── macos/                                 # Configuration macOS
├── assets/                                # Ressources (images, etc.)
├── test/                                  # Tests unitaires
├── scripts/                               # Scripts utilitaires
│
├── pubspec.yaml                           # Dépendances Flutter
├── analysis_options.yaml                  # Règles d'analyse Dart
└── README.md                              # Documentation principale
```

## 🎯 Principes d'Organisation

### 1. **Séparation par Couches**
- **Core** : Logique métier et services
- **Screens** : Interface utilisateur (pages)
- **Widgets** : Composants réutilisables

### 2. **Séparation par Modules**
- **Admin** : Fonctionnalités administratives
- **Auth** : Authentification et sécurité
- **Member** : Fonctionnalités membres
- **Common** : Fonctionnalités partagées

### 3. **Séparation par Type**
- **Responsive** : Adaptation aux tailles d'écran
- **Platform** : Adaptation aux plateformes (desktop, watch, mobile)
- **Common** : Composants génériques

## 📊 Flux de Données

```
User Action (Screen)
       ↓
   Widget Layer
       ↓
    Services (Core)
       ↓
  API / Database
       ↓
    Services (Core)
       ↓
   Widget Layer
       ↓
   Screen Update
```

## 🔄 Dépendances

```
Screens → Widgets → Core
  ↓         ↓         ↓
 UI     Components  Logic
```

### Règles de Dépendance :
1. **Core** ne dépend de rien (indépendant)
2. **Widgets** peut dépendre de Core
3. **Screens** peut dépendre de Widgets et Core
4. Éviter les dépendances circulaires

## 📝 Convention de Nommage

### Fichiers
- **Écrans** : `*_screen.dart` (ex: `login_screen.dart`)
- **Widgets** : `*_widget.dart` ou nom descriptif (ex: `responsive_card.dart`)
- **Services** : `*_service.dart` (ex: `api_service.dart`)
- **Barrel files** : nom du dossier + `.dart` (ex: `services.dart`)

### Classes
- **Écrans** : `*Screen` ou nom spécifique (ex: `LoginScreen`, `AccueilPage`)
- **Widgets** : `*Widget` ou nom descriptif (ex: `ResponsiveCard`)
- **Services** : `*Service` (ex: `ApiService`)

## 🚀 Avantages de cette Architecture

✅ **Maintenabilité** : Code organisé et facile à naviguer  
✅ **Scalabilité** : Facile d'ajouter de nouveaux modules  
✅ **Réutilisabilité** : Widgets et services partagés  
✅ **Testabilité** : Séparation claire entre logique et UI  
✅ **Collaboration** : Structure claire pour toute l'équipe  

## 📦 Imports Recommandés

```dart
// ✅ BON - Utiliser les barrel files
import 'package:team_fitness_app/core/core.dart';
import 'package:team_fitness_app/widgets/widgets.dart';
import 'package:team_fitness_app/screens/auth/auth_screens.dart';

// ❌ ÉVITER - Imports multiples
import 'package:team_fitness_app/core/services/api_service.dart';
import 'package:team_fitness_app/core/services/auth_service.dart';
import 'package:team_fitness_app/core/services/db_service.dart';
```

## ⚠️ Notes Importantes

- **Conflits de noms** : Certaines classes ont des noms identiques dans différents modules (ex: `AccueilPage`). Utilisez des imports spécifiques dans ces cas.
- **Barrel files limités** : Le fichier `screens/screens.dart` a des limitations. Préférez les imports depuis les sous-dossiers.
- **Code préservé** : Cette réorganisation n'a modifié aucune ligne de code, uniquement la structure.
