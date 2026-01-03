# Team Fitness App - Context Documentation

## 📋 Vue d'ensemble

Application de gestion de salle de sport développée avec Flutter, permettant la gestion des membres, abonnements, paiements, plannings et accès via QR codes.

### Technologies principales
- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Node.js/Express (API REST)
- **Base de données**: PostgreSQL (via Prisma)
- **Infrastructure**: VPS Ubuntu avec Nginx, SSL Let's Encrypt

---

## 🏗️ Architecture

### Structure du projet
```
team_fitness_app/
├── lib/
│   ├── core/
│   │   ├── config/          # Configuration environnements (dev, pprod, prod)
│   │   ├── l10n/            # Internationalisation (FR, EN, AR)
│   │   ├── models/          # Modèles de données
│   │   ├── services/        # Services (API, Auth, Storage, etc.)
│   │   ├── theme/           # Thème et design system
│   │   └── utils/           # Utilitaires (responsive, platform, etc.)
│   ├── screens/
│   │   ├── admin/           # Écrans administrateur
│   │   ├── auth/            # Authentification (login, register)
│   │   ├── common/          # Écrans partagés
│   │   ├── member/          # Écrans membres
│   │   └── owner/           # Écrans propriétaire
│   └── main.dart
├── android/                 # Configuration Android
├── ios/                     # Configuration iOS
├── web/                     # Configuration Web
├── docs/                    # Documentation technique
└── scripts/                 # Scripts de déploiement
```

### Rôles utilisateurs
1. **Owner** (Propriétaire)
   - Gestion multi-salles
   - Création d'admins
   - Rapports et statistiques globales

2. **Admin** (Administrateur)
   - Gestion des membres (création, modification, suppression)
   - Gestion des abonnements et paiements
   - Scanner QR codes d'accès
   - Gestion du store/produits
   - Planning et présences

3. **Member** (Membre)
   - Consultation profil et abonnement
   - QR code d'accès personnel
   - Consultation planning
   - Historique paiements
   - Store (consultation/achat produits)

---

## 🌍 Environnements

### Configuration
Définie via `--dart-define=ENVIRONMENT=<env>` au build

| Environnement | API Base URL | Usage |
|---------------|--------------|-------|
| **dev** | `http://localhost:3000` (ou `10.0.2.2` sur Android) | Développement local |
| **pprod** | `https://api-pprod.team-oustad.com` | Pré-production/Tests |
| **prod** | `https://api.team-oustad.com` | Production |

### Domaines déployés
- **App Web**: https://app.team-oustad.com
- **OTA Android**: https://app.team-oustad.com/android
- **API PProd**: https://api-pprod.team-oustad.com

---

## 🚀 Déploiement

### Android
```powershell
# Build APK
flutter build apk --release --dart-define=ENVIRONMENT=pprod

# Déploiement OTA (Over-The-Air)
# Via le backend Express sur le VPS
```

### Web (Flutter Web)
```powershell
# Build
flutter build web --release --dart-define=ENVIRONMENT=pprod

# Déploiement automatisé
.\deploy-web.ps1

# Serveur: Nginx avec reverse proxy
# Path: /var/www/team-fitness-app/
```

**⚠️ Limitations actuelles Web:**
- Version en développement, non recommandée pour production
- Certaines fonctionnalités natives désactivées (screenshot protection, biométrie)
- Nécessite JavaScript et cookies activés
- Pas d'installation hors-ligne (PWA partiellement configurée)

### Nginx Configuration
```nginx
# Frontend Flutter Web
location / {
    root /var/www/team-fitness-app;
    try_files $uri $uri/ /index.html;
}

# Backend OTA Android (préservé)
location /android {
    proxy_pass http://localhost:3001;
}
```

---

## 🎨 Design System

### Responsive Layout
- **Watch**: < 300px - Interface montre connectée
- **Mobile**: 300-600px - Interface smartphone
- **Desktop**: > 600px - Interface bureau/tablette

### Composants responsive
- `ResponsiveScaffold` - Layout adaptatif
- `ResponsiveLayout` - Widgets conditionnels
- `ResponsiveGrid` - Grilles flexibles
- `PlatformUtils` - Détection device type

### Thème
- **Mode clair/sombre** avec switch automatique
- Colors: `AppColors` (primary, success, error, warning, info)
- Typography: Système de tailles cohérent
- Spacing: Grille de 4px

---

## 📡 API Backend

### Endpoints principaux

#### Authentication
- `POST /auth/register` - Inscription
- `POST /auth/login` - Connexion
- `GET /auth/me` - Profil utilisateur

#### Members (Admin)
- `GET /members` - Liste membres
- `POST /members` - Créer membre (avec `address` requis)
- `PUT /members/:id/profile` - Modifier profil
- `GET /members/:id/qr` - QR code membre

#### Admins (Owner)
- `GET /admins` - Liste admins
- `POST /admins` - Créer admin (avec `address` requis)
- `DELETE /admins/:id` - Supprimer admin

#### Subscriptions
- `GET /subscriptions/member/:memberId` - Abonnements membre
- `POST /subscriptions` - Créer abonnement
- `PUT /subscriptions/:id` - Modifier abonnement

#### Payments
- `GET /payments` - Liste paiements
- `POST /payments` - Enregistrer paiement

#### Store
- `GET /store/products` - Liste produits
- `POST /store/products` - Créer produit
- `DELETE /store/products/:displayId` - Supprimer produit

---

## 🔐 Sécurité

### Authentication
- JWT Bearer tokens
- Stockage sécurisé via `flutter_secure_storage`
- Refresh automatique du profil

### Protection données
- Screenshot blocking (Android/iOS natifs uniquement)
- Biométrie locale (natif uniquement)
- Validation formulaires côté client et serveur
- Sanitization des entrées

### Web Security
- HTTPS obligatoire (SSL Let's Encrypt)
- CORS configuré sur l'API
- CSP (Content Security Policy) à renforcer
- Pas de stockage sensible en localStorage

---

## 📦 Dépendances principales

### Core
```yaml
flutter: sdk
http: ^1.0.0
shared_preferences: ^2.0.0
flutter_secure_storage: ^9.0.0
```

### Firebase
```yaml
firebase_core: ^2.24.0
firebase_messaging: ^14.7.0
```

### UI/UX
```yaml
connectivity_plus: ^5.0.0
intl: ^0.18.0
qr_flutter: ^4.1.0
```

### Utilities
```yaml
package_info_plus: ^4.0.0
image_picker: ^1.0.0
local_auth: ^2.1.0
```

---

## 🐛 Issues connus

### Web
1. **Platform API** - Résolu avec guards `kIsWeb`
2. **displayId vide** - Cache profil à forcer refresh
3. **PWA** - Installation partielle, service worker à améliorer
4. **Biométrie** - Non disponible sur web

### Android
1. **OTA Updates** - Fonctionne uniquement hors Play Store
2. **Screenshot protection** - Peut échouer sur certains devices custom

### iOS
1. **App non déployée** - En attente compte développeur Apple
2. **Certificats** - Configuration manuelle requise

---

## 🔄 Workflow Git

### Branches
- `main` - Production stable
- `staging` - Pré-production (branche active actuelle)
- `feature/*` - Nouvelles fonctionnalités

### Commits récents importants
- `be62cb8` - feat: add required address field to admin and member creation
- Latest - fix: add kIsWeb protection for Platform API usage

---

## 📊 Fonctionnalités principales

### ✅ Implémentées
- ✅ Authentification multi-rôles (owner, admin, member)
- ✅ Gestion complète des membres (CRUD)
- ✅ Gestion des abonnements et paiements
- ✅ QR codes d'accès personnalisés
- ✅ Scanner QR pour validation d'accès
- ✅ Store avec gestion produits
- ✅ Internationalisation (FR/EN/AR)
- ✅ Mode sombre/clair
- ✅ Responsive design (watch/mobile/desktop)
- ✅ OTA updates (Android)
- ✅ Notifications push (Firebase)
- ✅ Cache offline basique

### 🚧 En cours
- 🚧 Version web complète (limitations actuelles)
- 🚧 PWA avancée (offline mode)
- 🚧 App iOS (en attente déploiement)

### 📋 Backlog
- Planning et réservations avancées
- Statistiques et rapports détaillés
- Export PDF des documents
- Intégration paiement en ligne
- Chat support
- Notifications in-app personnalisées

---

## 🛠️ Scripts de développement

### PowerShell
```powershell
# Déploiement web
.\deploy-web.ps1

# Bump version
.\bump-version.ps1

# Setup Play Store
.\setup-play-store-secrets.ps1

# Test design system
.\test-design-system.ps1
```

### Makefile
```bash
make build-android    # Build APK
make build-ios        # Build iOS
make test            # Run tests
make format          # Format code
```

---

## 📞 Support & Contact

- **Email**: support@team-oustad.com
- **API PProd**: https://api-pprod.team-oustad.com
- **App Web**: https://app.team-oustad.com

---

## 📝 Notes de développement

### Changements récents (Janvier 2026)
1. **Ajout champ address** - Obligatoire pour création admin/membre
2. **Flutter Web déployé** - Version pprod accessible mais limitée
3. **Corrections Platform API** - Guards kIsWeb pour compatibilité web
4. **Refresh profil** - Force refresh API pour récupérer displayId

### Considérations futures
- **iOS App**: Nécessite compte développeur Apple ($99/an)
- **Web Access Control**: Implémenter restrictions d'accès en attendant iOS
- **PWA Enhancement**: Améliorer cache et offline capabilities
- **Backend Migration**: Considérer Firebase comme alternative complète

---

*Dernière mise à jour: 3 janvier 2026*
