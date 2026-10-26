import 'package:driver_alert_assistant/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('defaults are safe', () {
      const s = AppSettings();
      expect(s.askWhenUnsure, isTrue);
      expect(s.vibrationOn, isTrue);
      expect(s.startDelaySeconds, 3);
      expect(s.themeChoice, ThemeChoice.system);
    });

    test('JSON round trip keeps every value', () {
      const s = AppSettings(
        askWhenUnsure: false,
        vibrationOn: false,
        startDelaySeconds: 10,
        themeChoice: ThemeChoice.dark,
      );
      expect(AppSettings.fromJson(s.toJson()), s);
    });

    test('missing or wrong values fall back to defaults', () {
      final s = AppSettings.fromJson({
        'askWhenUnsure': 'yes',
        'startDelaySeconds': '3',
        'themeChoice': 'purple',
      });
      expect(s, const AppSettings());
    });

    test('start delay is kept within limits', () {
      expect(
        AppSettings.fromJson({'startDelaySeconds': -5}).startDelaySeconds,
        AppSettings.minStartDelaySeconds,
      );
      expect(
        const AppSettings().copyWith(startDelaySeconds: 999).startDelaySeconds,
        AppSettings.maxStartDelaySeconds,
      );
    });

    test('saved data includes a schema version', () {
      expect(const AppSettings().toJson()['schemaVersion'], 1);
    });
  });
}
