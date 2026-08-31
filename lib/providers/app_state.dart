import 'package:flutter/foundation.dart';
import '../l10n/strings.dart';
import '../services/database_helper.dart';

enum NavTab { home, catalog, growth, help }

/// Handles UI-level state: active tab, language, theme, overlay visibility.
///
/// Language and theme are persisted to SQLite so an artisan who picks Hindi
/// does not have to pick it again on every launch. Load them with [restore]
/// before the first frame and pass them to the constructor — reading them
/// afterwards would show a flash of English/light first.
class AppState extends ChangeNotifier {
  static const _keyLanguage = 'language';
  static const _keyDarkMode = 'dark_mode';

  final _db = DatabaseHelper.instance;

  Language _language;
  NavTab _tab = NavTab.home;
  bool _isDark;

  // The backing fields are private and a named parameter cannot start with an
  // underscore, so `this._language` is not available here.
  // ignore_for_file: prefer_initializing_formals
  AppState({
    Language language = Language.en,
    bool isDark = false,
  })  : _language = language,
        _isDark = isDark;

  /// Reads persisted preferences. Falls back to defaults if the database is
  /// unavailable — preferences must never be the reason the app fails to start.
  static Future<AppState> restore() async {
    try {
      final settings = await DatabaseHelper.instance.readAllSettings();
      return AppState(
        language: settings[_keyLanguage] == Language.hi.name
            ? Language.hi
            : Language.en,
        isDark: settings[_keyDarkMode] == 'true',
      );
    } catch (e) {
      debugPrint('⚠️ Could not restore preferences: $e — using defaults.');
      return AppState();
    }
  }

  Language get language => _language;
  NavTab get tab => _tab;
  bool get isDark => _isDark;

  DashboardStrings get strings => kStrings[_language]!;

  /// Persists a preference without letting a write failure surface in the UI.
  void _persist(String key, String value) {
    _db.writeSetting(key, value).catchError((Object e) {
      debugPrint('⚠️ Could not save preference $key: $e');
    });
  }

  void setLanguage(Language lang) {
    if (_language == lang) return;
    _language = lang;
    _persist(_keyLanguage, lang.name);
    notifyListeners();
  }

  void setTab(NavTab t) {
    if (_tab == t) return;
    _tab = t;
    notifyListeners();
  }

  void toggleDark() {
    _isDark = !_isDark;
    _persist(_keyDarkMode, _isDark.toString());
    notifyListeners();
  }

}
