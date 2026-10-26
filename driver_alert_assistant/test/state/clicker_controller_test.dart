import 'package:driver_alert_assistant/models/clicker_status.dart';
import 'package:driver_alert_assistant/state/clicker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_clicker_bridge.dart';

void main() {
  group('ClickerController', () {
    test('init loads status from Android', () async {
      final bridge = FakeClickerBridge(panelVisible: true);
      final c = ClickerController(bridge);
      await c.init();
      expect(c.status.state, ClickerRunState.stopped);
      expect(c.status.panelVisible, isTrue);
      expect(c.bridgeError, isFalse);
    });

    test('commands update status', () async {
      final bridge = FakeClickerBridge();
      final c = ClickerController(bridge);
      await c.init();

      expect(await c.send(ClickerCommand.start), CommandResult.ok);
      expect(c.status.state, ClickerRunState.running);
      expect(await c.send(ClickerCommand.pause), CommandResult.ok);
      expect(c.status.state, ClickerRunState.paused);
      expect(await c.send(ClickerCommand.stop), CommandResult.ok);
      expect(c.status.state, ClickerRunState.stopped);
    });

    test('start is blocked without accessibility', () async {
      final c = ClickerController(FakeClickerBridge(serviceEnabled: false));
      await c.init();
      expect(
        await c.send(ClickerCommand.start),
        CommandResult.blockedNoService,
      );
      expect(c.status.state, ClickerRunState.stopped);
    });

    test('changes from the floating panel reach the app', () async {
      final bridge = FakeClickerBridge();
      final c = ClickerController(bridge);
      await c.init();

      bridge.state = ClickerRunState.emergencyStopped;
      bridge.push();
      await Future<void>.delayed(Duration.zero);

      expect(c.status.isEmergency, isTrue);
    });

    test('bridge failure is reported, not thrown', () async {
      final bridge = FakeClickerBridge()..failCalls = true;
      final c = ClickerController(bridge);
      await c.init();
      expect(c.bridgeError, isTrue);
      expect(await c.send(ClickerCommand.start), CommandResult.failed);
      expect(await c.showPanel(), isFalse);
    });

    test('bridge error clears when Android answers again', () async {
      final bridge = FakeClickerBridge()..failCalls = true;
      final c = ClickerController(bridge);
      await c.init();
      bridge.failCalls = false;
      await c.refresh();
      expect(c.bridgeError, isFalse);
    });

    test('settings are passed to Android', () async {
      final bridge = FakeClickerBridge();
      final c = ClickerController(bridge);
      await c.updateSettings(vibrationOn: false);
      expect(bridge.lastVibrationOn, isFalse);
    });
  });
}
