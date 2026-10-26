import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/clicker_bridge.dart';
import 'services/settings_store.dart';
import 'state/clicker_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load(SharedPrefsSettingsStore());
  final clicker = ClickerController(MethodChannelClickerBridge());
  await clicker.init();

  // Keep the Android side in step with settings it needs (vibration).
  var lastVibration = settings.settings.vibrationOn;
  clicker.updateSettings(vibrationOn: lastVibration);
  settings.addListener(() {
    final on = settings.settings.vibrationOn;
    if (on == lastVibration) return;
    lastVibration = on;
    clicker.updateSettings(vibrationOn: on);
  });

  runApp(ClickerApp(settings: settings, clicker: clicker));
}
