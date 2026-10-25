# Guide du Système de Thème Moderne

## 📱 Vue d'ensemble

L'application Team Oustad dispose maintenant d'un système de thème moderne et cohérent avec support du mode clair et sombre. Ce guide explique comment utiliser le nouveau design system.

## 🎨 Structure du Thème

### Fichiers Principaux

```
lib/core/theme/
├── app_colors.dart         # Palette de couleurs
├── app_text_styles.dart    # Styles de texte
├── app_theme.dart          # Configuration des thèmes
├── theme_provider.dart     # Gestion du changement de thème
└── theme.dart              # Export centralisé
```

## 🌈 Palette de Couleurs

### Couleurs Primaires
```dart
AppColors.primary           // #e89547 (Orange/Gold)
AppColors.primaryLight      // #f4a261
AppColors.primaryDark       // #d97706
```

### Mode Sombre
```dart
AppColors.darkBackground    // #0f1419
AppColors.darkSurface       // #1a1f2e
AppColors.darkCard          // #2d3748
AppColors.darkElevated      // #374151
```

### Mode Clair
```dart
AppColors.lightBackground   // #F8F9FA
AppColors.lightSurface      // #FFFFFF
AppColors.lightCard         // #FFFFFF
AppColors.lightElevated     // #F3F4F6
```

### Couleurs Sémantiques
```dart
AppColors.success           // Vert (#10B981)
AppColors.error             // Rouge (#EF4444)
AppColors.warning           // Orange (#F59E0B)
AppColors.info              // Bleu (#3B82F6)
```

## 📝 Styles de Texte

### Headers
```dart
AppTextStyles.h1            // 32px, Bold
AppTextStyles.h2            // 28px, Bold
AppTextStyles.h3            // 24px, Bold
AppTextStyles.h4            // 20px, Semi-Bold
AppTextStyles.h5            // 18px, Semi-Bold
AppTextStyles.h6            // 16px, Semi-Bold
```

### Body & Autres
```dart
AppTextStyles.body1         // 16px, Normal
AppTextStyles.body2         // 14px, Normal
AppTextStyles.caption       // 12px, Normal
AppTextStyles.button        // 16px, Semi-Bold
AppTextStyles.overline      // 12px, Semi-Bold, Letterspacing
```

## 🧩 Composants Modernes

### 1. ModernButton
Bouton standardisé avec plusieurs variantes.

```dart
ModernButton(
  text: 'Se connecter',
  icon: Icons.login,
  onPressed: () {},
  isLoading: false,
  fullWidth: true,
  variant: ModernButtonVariant.primary,
)
```

**Variantes disponibles:**
- `primary` - Bouton principal (fond orange)
- `secondary` - Bouton secondaire (contour orange)
- `text` - Bouton texte
- `danger` - Bouton danger (rouge)
- `success` - Bouton succès (vert)

### 2. ModernCard
Card moderne avec bordures arrondies et ombres.

```dart
ModernCard(
  padding: EdgeInsets.all(16),
  onTap: () {},
  elevated: true,
  child: Column(
    children: [
      Text('Contenu de la carte'),
    ],
  ),
)
```

### 3. ModernTextField
Input field cohérent avec le design system.

```dart
ModernTextField(
  controller: emailController,
  label: 'Email',
  hint: 'Entrez votre email',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
)
```

### 4. StatusBadge
Badge pour afficher des statuts visuels.

```dart
StatusBadge(
  text: 'Actif',
  type: StatusBadgeType.success,
  icon: Icons.check_circle,
)
```

**Types disponibles:**
- `success` - Vert
- `error` - Rouge
- `warning` - Orange
- `info` - Bleu
- `primary` - Orange primaire

### 5. ThemeToggleButton
Bouton pour changer entre mode clair et sombre.

```dart
ThemeToggleButton(
  themeProvider: themeProvider,
)
```

## 🔄 Changement de Thème

### Dans votre Widget

```dart
// Récupérer le ThemeProvider
ThemeProvider? themeProvider;
try {
  themeProvider = ThemeProviderScope.of(context);
} catch (e) {
  // ThemeProviderScope non trouvé
}

// Utiliser dans les actions
actions: [
  if (themeProvider != null)
    ThemeToggleButton(themeProvider: themeProvider),
],
```

### Basculer Manuellement

```dart
final themeProvider = ThemeProviderScope.of(context);
await themeProvider.toggleTheme();

// Ou définir un mode spécifique
await themeProvider.setThemeMode(ThemeMode.light);
await themeProvider.setThemeMode(ThemeMode.dark);
```

## 🎯 Bonnes Pratiques

### 1. Utiliser le Theme de Context
```dart
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;

// Couleurs adaptatives
final backgroundColor = isDark 
  ? AppColors.darkBackground 
  : AppColors.lightBackground;
```

### 2. Utiliser les Composants Modernes
```dart
// ❌ Éviter
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFe89547),
    // ... configuration manuelle
  ),
  child: Text('Bouton'),
)

// ✅ Préférer
ModernButton(
  text: 'Bouton',
  onPressed: () {},
)
```

### 3. Cohérence des Couleurs
```dart
// ❌ Éviter les couleurs en dur
Container(
  color: Color(0xFF1a1f2e),
)

// ✅ Utiliser la palette
Container(
  color: theme.colorScheme.surface,
)
```

### 4. Typography Cohérente
```dart
// ❌ Éviter
Text(
  'Titre',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)

// ✅ Utiliser les styles prédéfinis
Text(
  'Titre',
  style: AppTextStyles.h3,
)
```

## 🚀 Migration d'Écrans Existants

### Étapes de Migration

1. **Importer le système de thème**
```dart
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import '../../main.dart';
```

2. **Remplacer les couleurs en dur**
```dart
// Avant
const Color(0xFF1a1f2e)

// Après
theme.colorScheme.surface
// ou
AppColors.darkSurface
```

3. **Utiliser les composants modernes**
```dart
// Remplacer ElevatedButton par ModernButton
// Remplacer Card par ModernCard
// Remplacer TextField par ModernTextField
```

4. **Ajouter le bouton de thème**
```dart
@override
Widget build(BuildContext context) {
  ThemeProvider? themeProvider;
  try {
    themeProvider = ThemeProviderScope.of(context);
  } catch (e) {}
  
  return Scaffold(
    appBar: AppBar(
      actions: [
        if (themeProvider != null)
          ThemeToggleButton(themeProvider: themeProvider),
      ],
    ),
  );
}
```

## 📱 Exemple Complet

```dart
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import '../../main.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ThemeProvider? themeProvider;
    try {
      themeProvider = ThemeProviderScope.of(context);
    } catch (e) {}

    return Scaffold(
      appBar: AppBar(
        title: Text('Exemple', style: AppTextStyles.h3),
        actions: [
          if (themeProvider != null)
            ThemeToggleButton(themeProvider: themeProvider),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Bienvenue', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Description',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            // Card moderne
            ModernCard(
              child: Column(
                children: [
                  StatusBadge(
                    text: 'Actif',
                    type: StatusBadgeType.success,
                    icon: Icons.check,
                  ),
                  const SizedBox(height: 16),
                  Text('Contenu de la carte'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Input field
            ModernTextField(
              label: 'Email',
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 16),
            
            // Boutons
            ModernButton(
              text: 'Action Principale',
              icon: Icons.check,
              onPressed: () {},
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            ModernButton(
              text: 'Action Secondaire',
              variant: ModernButtonVariant.secondary,
              onPressed: () {},
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎨 Personnalisation Avancée

### Créer des Variantes de Couleur

```dart
// Dans votre widget
final primaryLight = AppColors.primary.withOpacity(0.2);
final successDark = AppColors.success.withOpacity(0.8);
```

### Adapter au Contexte

```dart
final adaptiveColor = theme.brightness == Brightness.dark
  ? AppColors.darkTextPrimary
  : AppColors.lightTextPrimary;
```

## 📚 Ressources

- **Fichiers du système:** `lib/core/theme/`
- **Composants:** `lib/widgets/common/`
- **Exemples:** `lib/screens/auth/login_screen.dart`

---

**Note:** Le système de thème est persistant - le choix de l'utilisateur est sauvegardé et restauré au redémarrage de l'application.
