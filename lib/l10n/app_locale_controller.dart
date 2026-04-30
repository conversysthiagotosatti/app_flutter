import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefKey = 'app_locale_language_code';

/// Persisted UI language codes (aligned with portal `AppLanguage` / [LanguageSwitcher]).
/// `null` = follow system locale.
class AppLocaleController extends ChangeNotifier {
  Locale? _override;

  Locale? get localeOverride => _override;

  /// Menu value for [CheckedPopupMenuItem]: `system`, `pt`, `ptPT`, `en`, `es`, `de`.
  String get menuSelectionCode {
    final l = _override;
    if (l == null) return 'system';
    if (l.languageCode == 'pt') {
      if (l.countryCode == 'PT') return 'ptPT';
      return 'pt';
    }
    return l.languageCode;
  }

  Future<void> loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_kLocalePrefKey);
    final decoded = _localeFromPersisted(c);
    if (decoded == null && c != null && c.isNotEmpty) {
      await p.remove(_kLocalePrefKey);
    }
    _override = decoded;
    notifyListeners();
  }

  /// `null` = use [localeResolutionCallback] (device locale).
  Future<void> setLocaleOverride(Locale? locale) async {
    _override = locale;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(_kLocalePrefKey);
    } else {
      await p.setString(_kLocalePrefKey, _persistCodeFor(locale));
    }
  }

  /// Same options as portal [LanguageSwitcher] (+ system).
  Future<void> applyMenuCode(String code) async {
    switch (code) {
      case 'system':
        await setLocaleOverride(null);
        break;
      case 'pt':
        await setLocaleOverride(const Locale('pt'));
        break;
      case 'ptPT':
        await setLocaleOverride(
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'PT'),
        );
        break;
      case 'en':
        await setLocaleOverride(const Locale('en'));
        break;
      case 'es':
        await setLocaleOverride(const Locale('es'));
        break;
      case 'de':
        await setLocaleOverride(const Locale('de'));
        break;
    }
  }

  static String _persistCodeFor(Locale l) {
    if (l.languageCode == 'pt') {
      if (l.countryCode == 'PT') return 'ptPT';
      return 'pt';
    }
    return l.languageCode;
  }

  static Locale? _localeFromPersisted(String? s) {
    if (s == null || s.isEmpty) return null;
    switch (s) {
      case 'pt':
        return const Locale('pt');
      case 'ptPT':
        return const Locale.fromSubtags(languageCode: 'pt', countryCode: 'PT');
      case 'en':
        return const Locale('en');
      case 'es':
        return const Locale('es');
      case 'de':
        return const Locale('de');
      default:
        return null;
    }
  }
}

/// Picks the [supported] entry that best matches [target] (exact country, then language).
Locale matchSupportedLocale(Locale target, List<Locale> supported) {
  for (final l in supported) {
    if (l.languageCode == target.languageCode &&
        (l.countryCode ?? '') == (target.countryCode ?? '')) {
      return l;
    }
  }
  if (target.languageCode == 'pt' && target.countryCode == 'PT') {
    for (final l in supported) {
      if (l.languageCode == 'pt' && l.countryCode == 'PT') return l;
    }
  }
  for (final l in supported) {
    if (l.languageCode == target.languageCode) return l;
  }
  return const Locale('pt');
}
