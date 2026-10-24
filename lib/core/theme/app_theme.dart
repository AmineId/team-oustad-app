import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Couleurs
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,            // blanc passe 4.5:1 sur #E07B2A sombre
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.darkBackground,
      tertiary: AppColors.accentViolet,   // 3ème couleur identité — premium
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkCard,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkElevated,
    ),
    
    scaffoldBackgroundColor: AppColors.darkBackground,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.darkTextPrimary),
    ),
    
    // Cards — bordure subtile pour séparer card (#172840) du surface (#0F1E30)
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: AppTextStyles.body2.copyWith(color: AppColors.darkTextSecondary),
      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.darkTextTertiary),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.darkTextSecondary,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.caption,
    ),
    
    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
    
    // Icons
    iconTheme: const IconThemeData(
      color: AppColors.darkTextSecondary,
      size: 24,
    ),
    
    // Text
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: AppColors.darkTextPrimary),
      displayMedium: AppTextStyles.h2.copyWith(color: AppColors.darkTextPrimary),
      displaySmall: AppTextStyles.h3.copyWith(color: AppColors.darkTextPrimary),
      headlineMedium: AppTextStyles.h4.copyWith(color: AppColors.darkTextPrimary),
      headlineSmall: AppTextStyles.h5.copyWith(color: AppColors.darkTextPrimary),
      titleLarge: AppTextStyles.h6.copyWith(color: AppColors.darkTextPrimary),
      bodyLarge: AppTextStyles.body1.copyWith(color: AppColors.darkTextPrimary),
      bodyMedium: AppTextStyles.body2.copyWith(color: AppColors.darkTextSecondary),
      bodySmall: AppTextStyles.caption.copyWith(color: AppColors.darkTextTertiary),
      labelLarge: AppTextStyles.button.copyWith(color: AppColors.darkTextPrimary),
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: AppTextStyles.body2.copyWith(color: AppColors.darkTextPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: const ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: const ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );

  // Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Couleurs
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,             // blanc passe sur #E07B2A (4.5:1 ok)
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      tertiary: AppColors.accentViolet,    // 3ème couleur identité — premium
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightCard,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightElevated,
    ),
    
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 1,  // Légère élévation pour séparer du fond
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.lightTextPrimary),
      shadowColor: AppColors.lightShadow,
    ),
    
    // Cards — lightCard (#F8F9FB) sur fond lightBackground (#ECEFF3) = séparation visible
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 1,
      shadowColor: AppColors.lightShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Buttons (avec élévation pour mode clair)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,  // Élévation pour meilleure visibilité
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    // Input fields — fond légèrement off-white pour se distinguer du fond blanc
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: AppTextStyles.body2.copyWith(color: AppColors.lightTextSecondary),
      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.lightTextTertiary),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.lightTextSecondary,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextSecondary,  // Meilleur contraste
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.caption,
    ),
    
    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),
    
    // Icons
    iconTheme: const IconThemeData(
      color: AppColors.lightTextPrimary,  // Contraste amélioré pour les icônes
      size: 24,
    ),
    
    // Text
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: AppColors.lightTextPrimary),
      displayMedium: AppTextStyles.h2.copyWith(color: AppColors.lightTextPrimary),
      displaySmall: AppTextStyles.h3.copyWith(color: AppColors.lightTextPrimary),
      headlineMedium: AppTextStyles.h4.copyWith(color: AppColors.lightTextPrimary),
      headlineSmall: AppTextStyles.h5.copyWith(color: AppColors.lightTextPrimary),
      titleLarge: AppTextStyles.h6.copyWith(color: AppColors.lightTextPrimary),
      bodyLarge: AppTextStyles.body1.copyWith(color: AppColors.lightTextPrimary),
      bodyMedium: AppTextStyles.body2.copyWith(color: AppColors.lightTextSecondary),
      bodySmall: AppTextStyles.caption.copyWith(color: AppColors.lightTextTertiary),
      labelLarge: AppTextStyles.button.copyWith(color: AppColors.lightTextPrimary),
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightCard,
      contentTextStyle: AppTextStyles.body2.copyWith(color: AppColors.lightTextPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,  // Élévation pour meilleure visibilité
    ),
    
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightBorder.withValues(alpha: 0.3)),
      ),
      elevation: 12,
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: const ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: const ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
