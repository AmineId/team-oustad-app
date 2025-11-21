# Fastlane Configuration

Configuration Fastlane pour le déploiement automatique vers Google Play Console.

## 📁 Fichiers

- `Fastfile` - Définit les lanes (actions) de déploiement
- `Appfile` - Configuration de l'app (package name, service account)
- `service-account-key.json` - Clé du service account (⚠️ NON COMMITÉ)

## 🚀 Lanes Disponibles

### `internal` - Déployer vers Internal Testing

```bash
cd android
fastlane internal
```

Build et déploie l'app vers le test interne de Google Play.

### `beta` - Déployer vers Beta

```bash
cd android
fastlane beta
```

Build et déploie l'app vers la beta publique.

### `promote_to_beta` - Promouvoir Internal → Beta

```bash
cd android
fastlane promote_to_beta
```

Promeut une version existante du test interne vers la beta.

## 🔐 Configuration

### Prérequis

1. **Service Account JSON** - Placez le fichier dans `fastlane/service-account-key.json`
2. **Keystore** - Configurez `key.properties` à la racine du dossier android

### Variables d'Environnement

Dans GitHub Actions, les variables suivantes sont configurées :

```yaml
SUPPLY_JSON_KEY: fastlane/service-account-key.json
SUPPLY_PACKAGE_NAME: team.fitness.team_fitness_app
```

## 📦 Installation Locale

Si vous voulez tester Fastlane localement :

```bash
# Installer Ruby (si pas déjà installé)
# Windows: https://rubyinstaller.org/

# Installer Fastlane
gem install fastlane

# Vérifier l'installation
fastlane --version
```

## 🔄 Utilisation dans CI/CD

Le workflow GitHub Actions utilise automatiquement Fastlane :

```yaml
- name: 📤 Deploy to Internal Testing
  working-directory: android
  run: fastlane internal
  env:
    SUPPLY_JSON_KEY: fastlane/service-account-key.json
    SUPPLY_PACKAGE_NAME: team.fitness.team_fitness_app
```

## 🛡️ Sécurité

⚠️ **IMPORTANT** : Le fichier `service-account-key.json` contient des credentials sensibles.

- ✅ Fichier dans `.gitignore`
- ✅ Utilisé uniquement en CI/CD via secrets GitHub
- ✅ Nettoyé automatiquement après chaque déploiement

## 📚 Documentation

- [Fastlane](https://docs.fastlane.tools/)
- [Fastlane Supply (Play Store)](https://docs.fastlane.tools/actions/supply/)
- [Guide complet](../GOOGLE_PLAY_SETUP.md)
