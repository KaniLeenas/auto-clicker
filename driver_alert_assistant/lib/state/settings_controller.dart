import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_store.dart';

/// Holds the current settings for the screens and saves every change.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store, this._settings);

  /// Loads saved settings. If loading fails, starts with safe defaults.
  static Future<SettingsController> load(SettingsStore store) async {
    AppSettings settings;
    try {
      settings = await store.load();
    } catch (_) {
      settings = const AppSettings();
    }
    return SettingsController(store, settings);
  }

  final SettingsStore _store;
  AppSettings _settings;
  bool _lastSaveFailed = false;

  AppSettings get settings => _settings;

  /// True when the last change could not be saved on the phone.
  bool get lastSaveFailed => _lastSaveFailed;

  Future<void> update(AppSettings Function(AppSettings current) change) {
    return _apply(change(_settings));
  }

  /// Puts every setting back to its default value.
  Future<void> resetToDefaults() => _apply(const AppSettings());

  Future<void> _apply(AppSettings next) async {
    _settings = next;
    notifyListeners();
    try {
      await _store.save(next);
      _lastSaveFailed = false;
    } catch (_) {
      _lastSaveFailed = true;
    }
    notifyListeners();
  }
}
