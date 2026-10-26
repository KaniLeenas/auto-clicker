import 'package:driver_alert_assistant/models/app_settings.dart';
import 'package:driver_alert_assistant/services/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefsSettingsStore', () {
    test('returns defaults when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsSettingsStore();
      expect(await store.load(), const AppSettings());
    });

    test('saves and loads settings', () async {
      SharedPreferences.setMockInitialValues({});
      const s = AppSettings(vibrationOn: false, startDelaySeconds: 15);
      await SharedPrefsSettingsStore().save(s);
      expect(await SharedPrefsSettingsStore().load(), s);
    });

    test('broken saved data gives defaults instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSettingsStore.storageKey: '{not json',
      });
      expect(await SharedPrefsSettingsStore().load(), const AppSettings());
    });

    test('saved data that is not an object gives defaults', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSettingsStore.storageKey: '[1, 2, 3]',
      });
      expect(await SharedPrefsSettingsStore().load(), const AppSettings());
    });
  });
}
