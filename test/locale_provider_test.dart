import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autoubc/providers/locale_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to Ukrainian before and after loading preferences', () async {
    final provider = LocaleProvider();
    addTearDown(provider.dispose);
    expect(provider.locale, const Locale('uk'));
    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('uk'));
  });

  test('preserves English across restarts', () async {
    final provider = LocaleProvider();
    addTearDown(provider.dispose);
    await provider.setLocale(const Locale('en'));
    final restored = LocaleProvider();
    addTearDown(restored.dispose);
    await restored.loadSavedLocale();
    expect(restored.locale, const Locale('en'));
  });

  test('replaces an unsupported saved or selected language with Ukrainian',
      () async {
    SharedPreferences.setMockInitialValues({'language_code': 'de'});
    final provider = LocaleProvider();
    addTearDown(provider.dispose);
    await provider.loadSavedLocale();
    expect(provider.locale, const Locale('uk'));
    await provider.setLocale(const Locale('fr'));
    expect(provider.locale, const Locale('uk'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language_code'), 'uk');
  });
}
