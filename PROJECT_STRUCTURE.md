# Structure du Projet - Team Fitness App

## 📁 Organisation des Dossiers

### `lib/`
Racine du code source de l'application Flutter.

#### `lib/core/`
Contient les éléments fondamentaux de l'application (services, configuration, utilitaires).

- **`core/services/`** - Services de l'application
  - `api_service.dart` - Gestion des appels API
  - `auth_service.dart` - Service d'authentification
  - `db_service.dart` - Service de base de données
  - `error_reporter.dart` - Rapport d'erreurs
  - `fcm_service.dart` - Firebase Cloud Messaging
  - `notification_service.dart` - Notifications locales
  - `ota_update_service.dart` - Mises à jour OTA (Over The Air)
  - `services.dart` - Fichier barrel (exports)

- **`core/config/`** - Configuration de l'application
  - `app_config.dart` - Configuration globale de l'app
  - `config.dart` - Fichier barrel (exports)

- **`core/utils/`** - Utilitaires
  - `platform_utils.dart` - Utilitaires spécifiques aux plateformes
  - `utils.dart` - Fichier barrel (exports)

- **`core.dart`** - Fichier barrel principal du core

#### `lib/screens/`
Contient tous les écrans de l'application, organisés par module.

- **`screens/admin/`** - Écrans d'administration
  - `admin_admins_list_screen.dart` - Liste des administrateurs
  - `admin_create_admin_screen.dart` - Création d'administrateur
  - `admin_create_gym_screen.dart` - Création de salle de sport
  - `admin_create_member_screen.dart` - Création de membre
  - `admin_create_planning_screen.dart` - Création de planning
  - `admin_create_subscription_screen.dart` - Création d'abonnement
  - `admin_edit_admin_screen.dart` - Édition d'administrateur
  - `admin_edit_gym_screen.dart` - Édition de salle de sport
  - `admin_gyms_list_screen.dart` - Liste des salles de sport
  - `admin_gym_opening_hours_screen.dart` - Horaires d'ouverture
  - `admin_home_screen.dart` - Accueil administrateur
  - `admin_members_screen.dart` - Liste des membres
  - `admin_member_details_screen.dart` - Détails d'un membre
  - `admin_plannings_screen.dart` - Liste des plannings
  - `admin_subscription_details_screen.dart` - Détails d'abonnement
  - `admin_screens.dart` - Fichier barrel (exports)

- **`screens/auth/`** - Écrans d'authentification
  - `login_screen.dart` - Connexion
  - `forgot_password_screen.dart` - Mot de passe oublié
  - `reset_password_screen.dart` - Réinitialisation du mot de passe
  - `setup_password_screen.dart` - Configuration du mot de passe
  - `auth_screens.dart` - Fichier barrel (exports)

- **`screens/member/`** - Écrans membres
  - `member_home_screen.dart` - Accueil membre
  - `subscription_details_screen.dart` - Détails d'abonnement
  - `edit_profile_screen.dart` - Édition du profil
  - `member_screens.dart` - Fichier barrel (exports)

- **`screens/common/`** - Écrans communs
  - `home_screen.dart` - Écran d'accueil général
  - `splash_screen.dart` - Écran de démarrage
  - `about_screen.dart` - À propos
  - `security_settings_screen.dart` - Paramètres de sécurité
  - `notification_test_screen.dart` - Test des notifications
  - `common_screens.dart` - Fichier barrel (exports)

- **`screens.dart`** - Fichier barrel principal des écrans (avec limitations dues aux conflits de noms)

#### `lib/widgets/`
Contient tous les widgets réutilisables, organisés par catégorie.

- **`widgets/responsive/`** - Widgets responsive
  - `responsive_layout.dart` - Layout responsive
  - `responsive_grid.dart` - Grille responsive
  - `responsive_card.dart` - Carte responsive
  - `responsive_widgets.dart` - Fichier barrel (exports)

- **`widgets/platform/`** - Widgets spécifiques aux plateformes
  - `desktop_widgets.dart` - Widgets pour desktop
  - `watch_widgets.dart` - Widgets pour montre connectée
  - `platform_widgets.dart` - Fichier barrel (exports)

- **`widgets/common/`** - Widgets communs
  - `gym_details_bottom_sheet.dart` - Bottom sheet des détails de salle
  - `common_widgets.dart` - Fichier barrel (exports)

- **`widgets.dart`** - Fichier barrel principal des widgets

#### Fichiers racine de `lib/`
- `main.dart` - Point d'entrée de l'application
- `firebase_options.dart` - Configuration Firebase

## 📦 Fichiers Barrel

Les fichiers barrel (exports) permettent d'importer facilement plusieurs fichiers en une seule instruction :

```dart
// Au lieu de :
import 'package:team_fitness_app/core/services/api_service.dart';
import 'package:team_fitness_app/core/services/auth_service.dart';
import 'package:team_fitness_app/core/services/db_service.dart';

// Utilisez :
import 'package:team_fitness_app/core/services/services.dart';
```

### Fichiers barrel disponibles :
- `lib/core/core.dart` - Tous les éléments du core
- `lib/core/services/services.dart` - Tous les services
- `lib/core/config/config.dart` - Configuration
- `lib/core/utils/utils.dart` - Utilitaires
- `lib/screens/admin/admin_screens.dart` - Écrans admin
- `lib/screens/auth/auth_screens.dart` - Écrans auth
- `lib/screens/member/member_screens.dart` - Écrans membre
- `lib/screens/common/common_screens.dart` - Écrans communs
- `lib/widgets/responsive/responsive_widgets.dart` - Widgets responsive
- `lib/widgets/platform/platform_widgets.dart` - Widgets platform
- `lib/widgets/common/common_widgets.dart` - Widgets communs
- `lib/widgets/widgets.dart` - Tous les widgets

⚠️ **Note** : Le fichier `lib/screens/screens.dart` a des limitations dues à des conflits de noms entre les écrans admin et communs. Importez directement depuis les sous-dossiers quand nécessaire.

## 🔄 Avantages de cette Organisation

1. **Séparation des préoccupations** - Chaque module a son propre dossier
2. **Facilité de navigation** - Structure claire et intuitive
3. **Maintenance simplifiée** - Facile de localiser et modifier le code
4. **Scalabilité** - Facile d'ajouter de nouveaux modules
5. **Imports simplifiés** - Grâce aux fichiers barrel

## 🚀 Bonnes Pratiques

- Utilisez les fichiers barrel pour les imports multiples
- Gardez les écrans dans leur module respectif (admin, auth, member, common)
- Placez les widgets réutilisables dans `widgets/`
- Mettez tous les services dans `core/services/`
- Gardez la configuration dans `core/config/`
- Utilisez `core/utils/` pour les fonctions utilitaires

## 📝 Notes

- **Conflits de noms** : Certains écrans ont des noms de classes en conflit (ex: `AccueilPage`). Dans ces cas, importez directement depuis le fichier spécifique.
- **Code inchangé** : Cette réorganisation n'a modifié aucun code, seulement la structure des dossiers.
