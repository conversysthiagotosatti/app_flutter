import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefKey = 'app_locale_language_code';

/// Persisted UI language: `pt`, `en`, or follow system when null.
class AppLocaleController extends ChangeNotifier {
  Locale? _override;

  Locale? get localeOverride => _override;

  Future<void> loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_kLocalePrefKey);
    if (c != null && (c == 'pt' || c == 'en')) {
      _override = Locale(c);
      notifyListeners();
    }
  }

  /// `null` = use [localeResolutionCallback] (device locale).
  Future<void> setLocaleOverride(Locale? locale) async {
    _override = locale;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(_kLocalePrefKey);
    } else {
      await p.setString(_kLocalePrefKey, locale.languageCode);
    }
  }
}
