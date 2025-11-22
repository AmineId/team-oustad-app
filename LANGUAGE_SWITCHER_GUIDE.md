# Guide du Changement de Langue / Language Switcher Guide

## Vue d'ensemble / Overview

Ce guide explique comment utiliser et personnaliser le système de changement de langue dans l'application Team Fitness.

This guide explains how to use and customize the language switching system in the Team Fitness app.

---

## 🌍 Langues Supportées / Supported Languages

| Langue / Language | Code | Drapeau / Flag | Support RTL |
|------------------|------|----------------|-------------|
| Français         | fr_FR | 🇫🇷             | Non / No    |
| English          | en_US | 🇬🇧             | Non / No    |
| العربية (Arabic) | ar_SA | 🇸🇦             | Oui / Yes   |

---

## 🎯 Localisation des Fichiers / File Locations

### Services
- **LocaleService**: `lib/core/services/locale_service.dart`
  - Gestion de l'état de la locale
  - Persistance avec SharedPreferences
  - Méthodes d'aide pour noms et drapeaux

### Localisation
- **AppLocalizations**: `lib/core/l10n/app_localizations.dart`
  - Traductions pour les 3 langues
  - Delegate de localisation Flutter
  - Clés de traduction communes

### Widgets
- **LanguageSwitcherButton**: `lib/widgets/common/language_switcher_button.dart`
  - Bouton de changement de langue
  - Bottom sheet de sélection
  - UI moderne et animations

---

## 📝 Ajouter de Nouvelles Traductions / Adding New Translations

### Étape 1: Modifier app_localizations.dart

```dart
// Dans lib/core/l10n/app_localizations.dart
static final Map<String, Map<String, String>> _localizedValues = {
  'fr': {
    'home': 'Accueil',
    'my_new_key': 'Ma nouvelle traduction',  // ← Ajouter ici
  },
  'en': {
    'home': 'Home',
    'my_new_key': 'My new translation',  // ← Ajouter ici
  },
  'ar': {
    'home': 'الرئيسية',
    'my_new_key': 'ترجمتي الجديدة',  // ← Ajouter ici
  },
};
```

### Étape 2: Ajouter un getter

```dart
// Dans la classe AppLocalizations
String get myNewKey => translate('my_new_key');
```

### Étape 3: Utiliser dans le code

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.myNewKey);
```

---

## 🌐 Ajouter une Nouvelle Langue / Adding a New Language

### Étape 1: Ajouter la locale supportée

```dart
// Dans lib/core/services/locale_service.dart
static const List<Locale> supportedLocales = [
  Locale('fr', 'FR'),
  Locale('en', 'US'),
  Locale('ar', 'SA'),
  Locale('es', 'ES'),  // ← Nouvelle langue (Espagnol)
];
```

### Étape 2: Ajouter les traductions

```dart
// Dans lib/core/l10n/app_localizations.dart
static final Map<String, Map<String, String>> _localizedValues = {
  'fr': { /* ... */ },
  'en': { /* ... */ },
  'ar': { /* ... */ },
  'es': {  // ← Nouvelle langue
    'home': 'Inicio',
    'my_card': 'Mi Tarjeta',
    'my_planning': 'Mi Planificación',
    'my_profile': 'Mi Perfil',
    // ... autres traductions
  },
};
```

### Étape 3: Mettre à jour les méthodes d'aide

```dart
// Dans locale_service.dart
String getLocaleName(Locale locale) {
  switch (locale.languageCode) {
    case 'fr': return 'Français';
    case 'en': return 'English';
    case 'ar': return 'العربية';
    case 'es': return 'Español';  // ← Ajouter
    default: return locale.languageCode;
  }
}

String getLocaleFlag(Locale locale) {
  switch (locale.languageCode) {
    case 'fr': return '🇫🇷';
    case 'en': return '🇬🇧';
    case 'ar': return '🇸🇦';
    case 'es': return '🇪🇸';  // ← Ajouter
    default: return '🌐';
  }
}
```

### Étape 4: Mettre à jour le delegate

```dart
// Dans lib/core/l10n/app_localizations.dart
@override
bool isSupported(Locale locale) {
  return ['fr', 'en', 'ar', 'es'].contains(locale.languageCode);  // ← Ajouter 'es'
}
```

---

## 🔧 Utilisation Programmatique / Programmatic Usage

### Changer la langue / Change Language

```dart
// Obtenir le service
final localeService = LocaleServiceScope.of(context);

// Changer vers l'anglais
await localeService.setLocale(Locale('en', 'US'));

// Changer vers l'arabe
await localeService.setLocale(Locale('ar', 'SA'));
```

### Obtenir la langue actuelle / Get Current Language

```dart
final localeService = LocaleServiceScope.of(context);
Locale currentLocale = localeService.currentLocale;
print('Current language: ${currentLocale.languageCode}');
```

### Vérifier si RTL / Check if RTL

```dart
final localeService = LocaleServiceScope.of(context);
if (localeService.isRTL) {
  print('Current language is Right-to-Left');
}
```

### Écouter les changements / Listen to Changes

```dart
final localeService = LocaleServiceScope.of(context);
localeService.addListener(() {
  print('Language changed to: ${localeService.currentLocale}');
});
```

---

## 🎨 Personnalisation du Design / Design Customization

### Modifier les couleurs du bouton / Modify Button Colors

Dans `language_switcher_button.dart`:

```dart
// Changer la couleur du gradient
gradient: LinearGradient(
  colors: [
    Colors.blue.withValues(alpha: 0.15),  // ← Personnaliser
    Colors.blue.withValues(alpha: 0.08),  // ← Personnaliser
  ],
),
```

### Modifier la taille du bouton / Modify Button Size

```dart
// Changer le padding
padding: const EdgeInsets.symmetric(
  horizontal: 16,  // ← Personnaliser
  vertical: 10,    // ← Personnaliser
),

// Changer la taille des icônes
const Icon(
  Icons.language_rounded,
  size: 24,  // ← Personnaliser
),
```

### Personnaliser le bottom sheet / Customize Bottom Sheet

```dart
// Modifier le radius
borderRadius: const BorderRadius.only(
  topLeft: Radius.circular(32),   // ← Personnaliser
  topRight: Radius.circular(32),  // ← Personnaliser
),
```

---

## 🧪 Tests / Testing

### Test manuel / Manual Testing

1. **Test de changement de langue:**
   - Ouvrir l'interface membre
   - Cliquer sur le bouton de langue (🌐 🇫🇷)
   - Sélectionner chaque langue
   - Vérifier que l'UI se met à jour

2. **Test de persistance:**
   - Changer la langue
   - Fermer l'application
   - Rouvrir l'application
   - Vérifier que la langue est conservée

3. **Test RTL:**
   - Sélectionner l'arabe
   - Vérifier que le layout est inversé
   - Vérifier que le texte est aligné à droite

4. **Test de thème:**
   - Tester en mode clair
   - Tester en mode sombre
   - Vérifier que les couleurs s'adaptent

### Tests unitaires / Unit Tests

```dart
// Exemple de test pour LocaleService
testWidgets('LocaleService changes locale', (tester) async {
  final service = LocaleService();
  await service.initialize();
  
  expect(service.currentLocale, equals(Locale('fr', 'FR')));
  
  await service.setLocale(Locale('en', 'US'));
  expect(service.currentLocale, equals(Locale('en', 'US')));
});
```

---

## 🐛 Dépannage / Troubleshooting

### Problème: Le bouton n'apparaît pas

**Solution:**
- Vérifier que `LocaleServiceScope` est dans l'arbre des widgets
- Vérifier l'import: `import '../../main.dart';`

### Problème: Les traductions ne changent pas

**Solution:**
- Vérifier que `AppLocalizations.delegate` est dans `localizationsDelegates`
- Vérifier que la clé existe dans toutes les langues

### Problème: L'arabe ne s'affiche pas en RTL

**Solution:**
- Vérifier que `Directionality` est utilisé si nécessaire
- Vérifier la propriété `isRTL` du LocaleService

### Problème: La langue n'est pas sauvegardée

**Solution:**
- Vérifier que SharedPreferences est initialisé
- Vérifier les permissions d'écriture

---

## 📚 Ressources / Resources

### Documentation Flutter
- [Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Material Design Guidelines](https://material.io/design/platform-guidance/android-platform-guidance.html)

### Codes de langue ISO
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [ISO 3166-1 Country Codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)

---

## 🤝 Contribution

Pour contribuer au système de localisation:

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-langue`)
3. Ajouter les traductions
4. Commit (`git commit -m 'Ajout de la langue X'`)
5. Push (`git push origin feature/nouvelle-langue`)
6. Créer une Pull Request

---

## 📄 Licence

Ce système de localisation fait partie de l'application Team Fitness.

---

**Dernière mise à jour:** 22 Novembre 2025
**Version:** 1.0.0
