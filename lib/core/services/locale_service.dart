import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app locale and persist user language preferences
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  Locale _currentLocale = const Locale('fr', 'FR'); // Default to French
  
  Locale get currentLocale => _currentLocale;
  
  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // French
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
  ];
  
  /// Initialize and load saved locale from preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString(_localeKey);
    
    if (savedLocaleCode != null) {
      // Parse saved locale (format: "fr_FR", "en_US", "ar_SA")
      final parts = savedLocaleCode.split('_');
      if (parts.length == 2) {
        final locale = Locale(parts[0], parts[1]);
        if (supportedLocales.contains(locale)) {
          _currentLocale = locale;
          notifyListeners();
        }
      }
    }
  }
  
  /// Change the app locale
  Future<void> setLocale(Locale locale) async {
    debugPrint('LocaleService: setLocale called with $locale');
    if (!supportedLocales.contains(locale)) {
      debugPrint('LocaleService: Locale $locale not supported');
      return;
    }
    
    if (_currentLocale == locale) {
      debugPrint('LocaleService: Locale already set to $locale');
      return;
    }
    
    // Persist to preferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
      debugPrint('LocaleService: Locale saved to preferences: ${locale.languageCode}_${locale.countryCode}');
    } catch (e) {
      debugPrint('LocaleService: Error saving locale: $e');
    }
    
    // Then update and notify
    _currentLocale = locale;
    debugPrint('LocaleService: Locale updated to $_currentLocale, notifying listeners');
    notifyListeners();
  }
  
  /// Get locale display name
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }
  
  /// Get locale flag emoji
  String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌐';
    }
  }
  
  /// Check if current locale is RTL (Right-to-Left)
  bool get isRTL => _currentLocale.languageCode == 'ar';
}
