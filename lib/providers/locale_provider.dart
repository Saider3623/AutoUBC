import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  /// Languages of the interface; Ukrainian is the default.
  static const supportedLanguageCodes = ['uk', 'en'];

  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider();

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code');
    // A language that is no longer offered (or none saved) falls back to
    // Ukrainian.
    final languageCode =
        supportedLanguageCodes.contains(saved) ? saved! : 'uk';
    _locale = Locale(languageCode);
    Intl.defaultLocale = languageCode;
    if (saved != languageCode) {
      await prefs.setString('language_code', languageCode);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    Intl.defaultLocale = locale.languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }
}
