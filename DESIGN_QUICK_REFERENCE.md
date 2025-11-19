# 🎨 Système de Design - Aperçu Rapide

## Palette de Couleurs

### Couleur Primaire
```
🟠 #e89547 - Orange/Gold (inchangée)
🟠 #f4a261 - Orange Clair
🟠 #d97706 - Orange Foncé
```

### Mode Sombre (Par Défaut)
```
⬛ #0f1419 - Background
⬛ #1a1f2e - Surface
⬛ #2d3748 - Cards
⬛ #374151 - Elevated
```

### Mode Clair
```
⬜ #F8F9FA - Background
⬜ #FFFFFF - Surface
⬜ #FFFFFF - Cards
⬜ #F3F4F6 - Elevated
```

### Couleurs Sémantiques
```
🟢 #10B981 - Succès
🔴 #EF4444 - Erreur
🟡 #F59E0B - Avertissement
🔵 #3B82F6 - Information
```

## Typographie

```
H1: 32px Bold           - Titres principaux
H2: 28px Bold           - Sous-titres importants
H3: 24px Bold           - Titres de section
H4: 20px Semi-Bold      - Sous-sections
H5: 18px Semi-Bold      - Labels importants
H6: 16px Semi-Bold      - Labels standard

Body1: 16px Normal      - Texte principal
Body2: 14px Normal      - Texte secondaire
Caption: 12px Normal    - Légendes, notes

Button: 16px Semi-Bold  - Boutons
Overline: 12px Bold     - Labels spéciaux
```

## Composants

### ModernButton
```dart
// Primaire (orange, plein)
ModernButton(
  text: 'Connexion',
  icon: Icons.login,
  onPressed: () {},
  variant: ModernButtonVariant.primary,
)

// Secondaire (contour orange)
ModernButton(
  text: 'Annuler',
  variant: ModernButtonVariant.secondary,
  onPressed: () {},
)

// Danger (rouge)
ModernButton(
  text: 'Supprimer',
  variant: ModernButtonVariant.danger,
  onPressed: () {},
)

// Succès (vert)
ModernButton(
  text: 'Valider',
  variant: ModernButtonVariant.success,
  onPressed: () {},
)

// Texte uniquement
ModernButton(
  text: 'En savoir plus',
  variant: ModernButtonVariant.text,
  onPressed: () {},
)
```

### ModernCard
```dart
ModernCard(
  onTap: () {},
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Titre'),
      Text('Description'),
    ],
  ),
)
```

### ModernTextField
```dart
ModernTextField(
  controller: controller,
  label: 'Email',
  hint: 'votre@email.com',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
)
```

### StatusBadge
```dart
// Succès (vert)
StatusBadge(
  text: 'Actif',
  type: StatusBadgeType.success,
  icon: Icons.check_circle,
)

// Erreur (rouge)
StatusBadge(
  text: 'Expiré',
  type: StatusBadgeType.error,
  icon: Icons.error,
)

// Avertissement (orange)
StatusBadge(
  text: 'Expire bientôt',
  type: StatusBadgeType.warning,
  icon: Icons.warning,
)

// Info (bleu)
StatusBadge(
  text: 'Nouveau',
  type: StatusBadgeType.info,
  icon: Icons.info,
)

// Primaire (orange)
StatusBadge(
  text: 'Premium',
  type: StatusBadgeType.primary,
  icon: Icons.star,
)
```

## Espacements Standards

```
Très petit: 4px
Petit: 8px
Moyen: 12px
Normal: 16px
Grand: 24px
Très grand: 32px
Extra grand: 48px
```

## Bordures

```
Petit: 8px  (badges, petits éléments)
Moyen: 12px (boutons, inputs)
Grand: 16px (cards)
Très grand: 20px (modals, dialogs)
Circulaire: 24px (actions rapides)
```

## Élévations

```
Mode Sombre:
- Card: 2 (ombre noire 30%)
- Dialog: 8 (ombre noire 30%)

Mode Clair:
- Card: 1 (ombre noire 10%)
- Dialog: 8 (ombre noire 10%)
```

## Icônes

```
Petite: 16px (dans badges)
Standard: 24px (navigation, actions)
Grande: 32px (stat cards)
Très grande: 48-64px (états vides, illustrations)
```

## Zones de Toucher

```
Minimum: 48x48px (standard Material Design)
Boutons: 56px hauteur minimum
Icons: 48x48px zone cliquable
```

## Animations

```
Changement de thème: 300ms
Transitions: 200-300ms
Micro-interactions: 150ms
```

## Accessibilité

### Contrastes
```
Mode Sombre:
- Texte principal: blanc sur #1a1f2e (ratio: 15:1) ✅
- Texte secondaire: gris clair sur #1a1f2e (ratio: 8:1) ✅
- Primaire: #e89547 sur #1a1f2e (ratio: 5.5:1) ✅

Mode Clair:
- Texte principal: #111827 sur blanc (ratio: 18:1) ✅
- Texte secondaire: #4B5563 sur blanc (ratio: 9:1) ✅
- Primaire: #e89547 sur blanc (ratio: 3.5:1) ⚠️
```

### Tailles Minimum
```
Texte: 14px minimum (sauf caption à 12px)
Zones tactiles: 48x48px minimum
Espacement entre éléments cliquables: 8px minimum
```

## Changement de Thème

```dart
// Obtenir le ThemeProvider
final themeProvider = ThemeProviderScope.of(context);

// Basculer
await themeProvider.toggleTheme();

// Définir explicitement
await themeProvider.setThemeMode(ThemeMode.light);
await themeProvider.setThemeMode(ThemeMode.dark);

// Vérifier le mode actuel
final isDark = themeProvider.isDarkMode;
```

## Persistance

Le choix du thème est automatiquement sauvegardé dans SharedPreferences et restauré au démarrage de l'application.

---

**🎯 Pour plus de détails, consultez:**
- `THEME_SYSTEM_GUIDE.md` - Guide complet
- `DESIGN_SYSTEM_UPDATE.md` - Nouveautés et changements
