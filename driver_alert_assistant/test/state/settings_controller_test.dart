import 'package:driver_alert_assistant/models/app_settings.dart';
import 'package:driver_alert_assistant/services/settings_store.dart';
import 'package:driver_alert_assistant/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements SettingsStore {
  @override
  Future<AppSettings> load() => Future.error(StateError('disk error'));

  @override
  Future<void> save(AppSettings settings) async {}
}

void main() {
  group('SettingsController', () {
    test('loading error starts with defaults', () async {
      final c = await SettingsController.load(_BrokenStore());
      expect(c.settings, const AppSettings());
    });

    test('update saves the change', () async {
      final store = MemorySettingsStore();
      final c = await SettingsController.load(store);
      await c.update((s) => s.copyWith(startDelaySeconds: 7));
      expect(store.saved?.startDelaySeconds, 7);
      expect(c.lastSaveFailed, isFalse);
    });

    test('reset puts defaults back and saves', () async {
      final store = MemorySettingsStore(
        const AppSettings(askWhenUnsure: false, startDelaySeconds: 20),
      );
      final c = await SettingsController.load(store);
      await c.resetToDefaults();
      expect(c.settings, const AppSettings());
      expect(store.saved, const AppSettings());
    });

    test('save failure is reported but change is kept in memory', () async {
      final store = MemorySettingsStore()..failSaves = true;
      final c = await SettingsController.load(store);
      await c.update((s) => s.copyWith(vibrationOn: false));
      expect(c.settings.vibrationOn, isFalse);
      expect(c.lastSaveFailed, isTrue);
    });
  });
}
