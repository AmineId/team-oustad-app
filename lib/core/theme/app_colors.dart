import 'package:flutter/material.dart';

/// Palette de couleurs de l'application
class AppColors {
  // Couleur primaire (orange/gold)
  static const Color primary = Color(0xFFe89547);
  static const Color primaryLight = Color(0xFFf4a261);
  static const Color primaryDark = Color(0xFFd97706);

  // Couleur d'accent (violet — troisième couleur)
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFF9F67F5);
  
  // Couleurs de fond - Mode sombre (tons harmonieux)
  static const Color darkBackground = Color(0xFF1a202c);  // Bleu-gris profond
  static const Color darkSurface = Color(0xFF2d3748);     // Surface légèrement plus claire
  static const Color darkCard = Color(0xFF374151);        // Cartes avec bon contraste
  static const Color darkElevated = Color(0xFF475569);
  
  // Couleurs de fond - Mode clair (meilleur contraste)
  static const Color lightBackground = Color(0xFFECEFF3);  // Gris plus visible pour le fond
  static const Color lightSurface = Color(0xFFFFFFFF);     // Blanc pour la surface
  static const Color lightCard = Color(0xFFFFFFFF);        // Blanc pour les cartes
  static const Color lightElevated = Color(0xFFE2E8F0);    // Gris plus prononcé
  
  // Couleurs de texte - Mode sombre
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF9CA3AF);
  
  // Couleurs de texte - Mode clair (contraste optimal)
  static const Color lightTextPrimary = Color(0xFF1E293B);   // Encore plus foncé pour maximum contraste
  static const Color lightTextSecondary = Color(0xFF334155); // Plus sombre pour meilleure lisibilité
  static const Color lightTextTertiary = Color(0xFF475569);  // Renforcé pour tertiaire
  
  // Couleurs sémantiques
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  
  // Couleurs de bordure
  static const Color darkBorder = Color(0xFF475569);
  static const Color lightBorder = Color(0xFF94A3B8);  // Contraste amélioré en mode clair
  
  // Ombres
  static Color darkShadow = Colors.black.withValues(alpha: 0.3);
  static Color lightShadow = Colors.black.withValues(alpha: 0.15);  // Ombre plus visible
}



