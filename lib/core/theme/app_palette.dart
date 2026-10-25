import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Couleurs d'accent dépendantes du thème — à utiliser pour tout ce qui est
/// posé SUR une surface : texte, icônes, bordures, spinners, liens.
///
/// Pourquoi : l'or #E8961E, l'émeraude, le warning et l'info ne font que
/// 2,1–2,5:1 sur blanc. En mode clair on utilise donc une version « encre »
/// foncée (≥ 4,5:1 sur blanc) ; en mode sombre les teintes vives restent.
///
/// Les APLATS (fond de bouton, FAB, puce sélectionnée) gardent les constantes
/// vives de [AppColors] avec [onPrimary] pour le texte posé dessus.
///
/// Usage : `context.palette.primary`.
///
/// Règles d'usage des 3 accents :
///   • Or (primary)     — action & marque : CTA principal (1 par écran),
///                         onglet/nav sélectionné, focus, liens, chiffres clés.
///                         Jamais pour un statut.
///   • Émeraude (success) — état positif uniquement : abonnement actif,
///                         check-in validé, présent, objectif atteint.
///                         Jamais décoratif.
///   • Violet (premium) — premium & mise en avant secondaire : offres,
///                         badges, rôle propriétaire, 2ᵉ série de graphe.
///                         Jamais pour un CTA qui concurrence l'or.
///   Le warning est orange (≠ or) pour ne pas être confondu avec la marque.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color premium;

  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.premium,
  });

  static const AppPalette light = AppPalette(
    primary: AppColors.primaryInk,
    onPrimary: AppColors.onPrimary,
    success: AppColors.successInk,
    warning: AppColors.warningInk,
    error: AppColors.errorInk,
    info: AppColors.infoInk,
    premium: AppColors.premiumInk,
  );

  // Mode sombre : inchangé pour l'instant (sera revu après validation du clair)
  static const AppPalette dark = AppPalette(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    premium: AppColors.accentViolet,
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? premium,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      premium: premium ?? this.premium,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
