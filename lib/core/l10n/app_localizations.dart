import 'package:flutter/material.dart';

/// Simple localization delegate for the app
/// This provides translations for French, English, and Arabic
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // Translation keys and values
  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'home': 'Accueil',
      'my_card': 'Ma Carte',
      'my_planning': 'Mon Planning',
      'my_profile': 'Mon Profil',
      'welcome': 'Bienvenue',
      'language': 'Langue',
      'select_language': 'Sélectionner la langue',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
    },
    'en': {
      'home': 'Home',
      'my_card': 'My Card',
      'my_planning': 'My Schedule',
      'my_profile': 'My Profile',
      'welcome': 'Welcome',
      'language': 'Language',
      'select_language': 'Select Language',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
    },
    'ar': {
      'home': 'الرئيسية',
      'my_card': 'بطاقتي',
      'my_planning': 'جدولي',
      'my_profile': 'ملفي الشخصي',
      'welcome': 'مرحباً',
      'language': 'اللغة',
      'select_language': 'اختر اللغة',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Convenience getters for common translations
  String get home => translate('home');
  String get myCard => translate('my_card');
  String get myPlanning => translate('my_planning');
  String get myProfile => translate('my_profile');
  String get welcome => translate('welcome');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get french => translate('french');
  String get english => translate('english');
  String get arabic => translate('arabic');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'ar'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
