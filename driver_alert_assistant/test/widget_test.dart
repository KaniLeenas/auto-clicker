import 'package:driver_alert_assistant/app/app.dart';
import 'package:driver_alert_assistant/models/app_settings.dart';
import 'package:driver_alert_assistant/models/clicker_status.dart';
import 'package:driver_alert_assistant/screens/settings_screen.dart';
import 'package:driver_alert_assistant/services/settings_store.dart';
import 'package:driver_alert_assistant/state/clicker_controller.dart';
import 'package:driver_alert_assistant/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_clicker_bridge.dart';

class TestApp {
  TestApp(this.store, this.bridge);
  final MemorySettingsStore store;
  final FakeClickerBridge bridge;
}

Future<TestApp> pumpApp(
  WidgetTester tester, {
  AppSettings? saved,
  FakeClickerBridge? bridge,
}) async {
  // A tall phone-like screen, so every row of the Home list is built.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);

  final store = MemorySettingsStore(saved);
  final fake = bridge ?? FakeClickerBridge();
  final settings = await SettingsController.load(store);
  final clicker = ClickerController(fake);
  await clicker.init();
  await tester.pumpWidget(ClickerApp(settings: settings, clicker: clicker));
  await tester.pumpAndSettle();
  return TestApp(store, fake);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

bool isEnabled(WidgetTester tester, String label) {
  final button = tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.bySubtype<ButtonStyleButton>(),
    ),
  );
  return button.onPressed != null;
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

void main() {
  group('Home', () {
    testWidgets('shows app name, status and Emergency Stop', (tester) async {
      await pumpApp(tester);
      expect(find.text('Smart Auto Clicker'), findsOneWidget);
      expect(find.text('Auto clicker is STOPPED'), findsOneWidget);
      expect(find.text('Accessibility: ON'), findsOneWidget);
      expect(find.text('EMERGENCY STOP'), findsOneWidget);
    });

    testWidgets('accessibility off: help card shown, Start disabled', (
      tester,
    ) async {
      final app = await pumpApp(
        tester,
        bridge: FakeClickerBridge(serviceEnabled: false),
      );
      expect(find.text('Turn on accessibility'), findsOneWidget);
      expect(isEnabled(tester, 'Start'), isFalse);
      expect(isEnabled(tester, 'Show floating panel'), isFalse);

      await tapText(tester, 'Open Accessibility settings');
      expect(app.bridge.calls, contains('openAccessibilitySettings'));
    });

    testWidgets('restricted settings help opens App info', (tester) async {
      final app = await pumpApp(
        tester,
        bridge: FakeClickerBridge(serviceEnabled: false),
      );
      await tapText(tester, 'The switch is greyed out?');
      expect(find.text('Allow restricted settings'), findsOneWidget);
      await tester.tap(find.text('Open App info'));
      await tester.pumpAndSettle();
      expect(app.bridge.calls, contains('openAppInfo'));
    });

    testWidgets('Start, Pause, Resume, Stop', (tester) async {
      await pumpApp(tester);

      await tapText(tester, 'Start');
      expect(find.text('Auto clicker is RUNNING'), findsOneWidget);
      expect(isEnabled(tester, 'Start'), isFalse);

      await tapText(tester, 'Pause');
      expect(find.text('Auto clicker is PAUSED'), findsOneWidget);

      await tapText(tester, 'Resume');
      expect(find.text('Auto clicker is RUNNING'), findsOneWidget);

      await tapText(tester, 'Stop');
      expect(find.text('Auto clicker is STOPPED'), findsOneWidget);
    });

    testWidgets('show and hide floating panel', (tester) async {
      await pumpApp(tester);
      await tapText(tester, 'Show floating panel');
      expect(find.text('Floating panel: shown'), findsOneWidget);
      await tapText(tester, 'Hide floating panel');
      expect(find.text('Floating panel: hidden'), findsOneWidget);
    });

    testWidgets('panel cannot be hidden while running', (tester) async {
      await pumpApp(
        tester,
        bridge: FakeClickerBridge(
          state: ClickerRunState.running,
          panelVisible: true,
        ),
      );
      await tapText(tester, 'Hide floating panel');
      expect(find.text('Stop the auto clicker first.'), findsOneWidget);
      expect(find.text('Floating panel: shown'), findsOneWidget);
    });
  });

  group('Emergency Stop', () {
    testWidgets('stops a running clicker and blocks Start', (tester) async {
      final app = await pumpApp(
        tester,
        bridge: FakeClickerBridge(state: ClickerRunState.running),
      );

      await tapText(tester, 'EMERGENCY STOP');

      expect(app.bridge.state, ClickerRunState.emergencyStopped);
      expect(find.text('Emergency Stop is ON'), findsOneWidget);
      expect(find.text('Emergency Stop: everything stopped.'), findsOneWidget);
      expect(isEnabled(tester, 'Start'), isFalse);
    });

    testWidgets('turning it off asks first and stays stopped', (tester) async {
      final app = await pumpApp(
        tester,
        bridge: FakeClickerBridge(state: ClickerRunState.emergencyStopped),
      );

      await tapText(tester, 'Turn off Emergency Stop');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Stop is ON'), findsOneWidget);

      await tapText(tester, 'Turn off Emergency Stop');
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Stop is ON'), findsNothing);
      expect(app.bridge.state, ClickerRunState.stopped);
      expect(find.text('Auto clicker is STOPPED'), findsOneWidget);
    });

    testWidgets('pressed on the floating panel shows in the app', (
      tester,
    ) async {
      final app = await pumpApp(
        tester,
        bridge: FakeClickerBridge(state: ClickerRunState.running),
      );
      app.bridge
        ..state = ClickerRunState.emergencyStopped
        ..push();
      await tester.pumpAndSettle();
      expect(find.text('Emergency Stop is ON'), findsOneWidget);
    });
  });

  testWidgets('message from Android is shown', (tester) async {
    await pumpApp(
      tester,
      bridge: FakeClickerBridge(
        message: 'Stopped because accessibility was turned off.',
      ),
    );
    expect(
      find.text('Stopped because accessibility was turned off.'),
      findsOneWidget,
    );
  });

  testWidgets('bridge error is shown', (tester) async {
    await pumpApp(tester, bridge: FakeClickerBridge()..failCalls = true);
    expect(find.text('Can\'t reach the clicker service.'), findsOneWidget);
    expect(find.text('Status unknown'), findsOneWidget);
  });

  group('Settings', () {
    testWidgets('Ask me when unsure can be turned off and shows on Home', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openSettings(tester);
      await tester.tap(find.text('Ask me when unsure'));
      await tester.pumpAndSettle();
      expect(app.store.saved?.askWhenUnsure, isFalse);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Asks you when unsure: OFF'));
      expect(find.text('Unclear screens are skipped.'), findsOneWidget);
    });

    testWidgets('Start delay is shown on Home', (tester) async {
      await pumpApp(tester, saved: const AppSettings(startDelaySeconds: 12));
      await tester.ensureVisible(find.text('Wait 12 seconds before starting'));
    });

    testWidgets('Dark screen colours can be chosen', (tester) async {
      final app = await pumpApp(tester);
      await openSettings(tester);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(app.store.saved?.themeChoice, ThemeChoice.dark);
      final mApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(mApp.themeMode, ThemeMode.dark);
    });

    testWidgets('Reset all settings asks first and resets', (tester) async {
      final app = await pumpApp(
        tester,
        saved: const AppSettings(askWhenUnsure: false, startDelaySeconds: 20),
      );
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.text('Reset all settings'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset all settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(app.store.saved, const AppSettings());
    });

    testWidgets('Warns when a change cannot be saved', (tester) async {
      final app = await pumpApp(tester);
      app.store.failSaves = true;
      await openSettings(tester);
      await tester.tap(find.text('Vibrate on start and stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save your last change.'), findsOneWidget);
    });
  });
}
