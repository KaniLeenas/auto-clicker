import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Saves and loads [AppSettings] on the phone.
abstract class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

/// Stores settings as JSON in Android SharedPreferences.
class SharedPrefsSettingsStore implements SettingsStore {
  SharedPrefsSettingsStore({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const String storageKey = 'clicker_settings_v1';

  final Future<SharedPreferences> _prefs;

  @override
  Future<AppSettings> load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return AppSettings.fromJson(decoded);
      }
    } on FormatException {
      // Broken saved data: fall through to safe defaults.
    }
    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await _prefs;
    final ok = await prefs.setString(storageKey, jsonEncode(settings.toJson()));
    if (!ok) {
      throw StateError('Could not save settings');
    }
  }
}

/// Keeps settings in memory only. Used by tests.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.saved]);

  AppSettings? saved;
  int saveCount = 0;
  bool failSaves = false;

  @override
  Future<AppSettings> load() async => saved ?? const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {
    if (failSaves) throw StateError('Save failed');
    saved = settings;
    saveCount++;
  }
}
