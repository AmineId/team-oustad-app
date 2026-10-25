import 'package:flutter/material.dart';

/// Palette "Midnight Gold" — TeamOustad
///
/// 3 couleurs identité :
///   1. Amber Gold  (#E8961E) — primaire / CTA / logo
///   2. Emerald     (#10B981) — énergie / succès / actif
///   3. Violet      (#8B5CF6) — premium / badges / secondaire
///
/// Mode sombre : Midnight Navy (nuance bleue profonde = premium, distinctif)
/// Mode clair  : Warm Stone (neutres chauds, cartes blanches, or seul accent fort)
class AppColors {
  // ── 1. Amber Gold — couleur primaire / logo ─────────────────────────
  static const Color primary      = Color(0xFFE8961E); // Amber gold vrai
  static const Color primaryLight = Color(0xFFF5B040); // surbrillance
  static const Color primaryDark  = Color(0xFFC4781A); // pressé / ombre

  // ── 2. Emerald — énergie / succès ───────────────────────────────────
  static const Color accentGreen      = Color(0xFF10B981); // Emerald 500
  static const Color accentGreenLight = Color(0xFF34D399); // Emerald 400
  static const Color accentGreenDark  = Color(0xFF059669); // Emerald 600

  // ── 3. Violet — premium / secondaire ────────────────────────────────
  static const Color accentViolet      = Color(0xFF8B5CF6); // Violet 500 (plus vif)
  static const Color accentVioletLight = Color(0xFFA78BFA); // Violet 400
  static const Color accentVioletDark  = Color(0xFF6D28D9); // Violet 700

  // ── Encres mode clair — accents posés sur blanc (≥ 4,5:1) ───────────
  // Voir AppPalette : ne pas utiliser directement, passer par context.palette
  static const Color primaryInk = Color(0xFF9A5F08); // Bronze gold — 5,2:1
  static const Color successInk = Color(0xFF047857); // Emerald 700 — 5,5:1
  static const Color warningInk = Color(0xFFC2410C); // Orange 700 — 5,2:1 (≠ or)
  static const Color errorInk   = Color(0xFFB91C1C); // Red 700 — 6,5:1
  static const Color infoInk    = Color(0xFF0369A1); // Sky 700 — 5,9:1
  static const Color premiumInk = Color(0xFF7C3AED); // Violet 600 — 5,7:1

  /// Texte sur aplat or (#E8961E) : charbon = 7,3:1 (le blanc ne fait que 2,4:1)
  static const Color onPrimary = Color(0xFF1C1917);

  // ── Alias legacy ────────────────────────────────────────────────────
  static const Color accent      = accentViolet;
  static const Color accentLight = accentVioletLight;

  // ── Fond dark — Midnight Navy (3 niveaux lisibles, teinte bleue chaude) ──
  // Les 3 niveaux sont espacés de ~8–10 % de luminosité pour une séparation claire
  static const Color darkBackground = Color(0xFF07111E); // Midnight — quasi-noir navy
  static const Color darkSurface    = Color(0xFF0F1E30); // Deep Navy — +7 pts
  static const Color darkCard       = Color(0xFF172840); // Steel Navy — +6 pts
  static const Color darkElevated   = Color(0xFF1E3550); // Modal / dropdown

  // ── Fond light — Warm Stone (neutres chauds, en accord avec l'or) ────
  // Pas de bleu dans les neutres : un gris froid sous de l'or crée une dissonance
  static const Color lightBackground = Color(0xFFF5F2EC); // Pierre claire — cartes blanches ressortent
  static const Color lightSurface    = Color(0xFFFFFFFF); // Blanc pur (pages, appbar, cartes)
  static const Color lightCard       = Color(0xFFFAF8F4); // Inputs / dialogs
  static const Color lightElevated   = Color(0xFFECE7DF); // Séparateurs / pistes

  // ── Texte dark ──────────────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFF0F6FF); // Blanc froid — 12:1 sur darkCard
  static const Color darkTextSecondary = Color(0xFFC4D4E3); // Bleu-gris clair — 5:1
  static const Color darkTextTertiary  = Color(0xFF8BA4BB); // Légendes — 3:1

  // ── Texte light ─────────────────────────────────────────────────────
  static const Color lightTextPrimary   = Color(0xFF1C1917); // Charbon chaud — 17:1 sur blanc
  static const Color lightTextSecondary = Color(0xFF44403C); // Pierre foncée — 10:1
  static const Color lightTextTertiary  = Color(0xFF655C52); // Légendes — 6,5:1 (5,9 sur fond)

  // ── Sémantiques ─────────────────────────────────────────────────────
  static const Color success      = accentGreen;
  static const Color successLight = accentGreenLight;
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFF87171);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info         = Color(0xFF38BDF8); // Sky blue — plus frais
  static const Color infoLight    = Color(0xFF7DD3FC);

  // ── Bordures ────────────────────────────────────────────────────────
  static const Color darkBorder  = Color(0xFF162336); // subtil sur darkSurface
  static const Color lightBorder = Color(0xFFE3DCD0); // discret — la carte blanche suffit à séparer

  // ── Ombres ──────────────────────────────────────────────────────────
  static Color darkShadow  = const Color(0xFF000D1A).withValues(alpha: 0.50);
  static Color lightShadow = const Color(0xFF1C1917).withValues(alpha: 0.08);
}



