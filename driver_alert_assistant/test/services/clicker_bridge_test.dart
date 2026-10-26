import 'package:driver_alert_assistant/models/clicker_status.dart';
import 'package:driver_alert_assistant/services/clicker_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('smart_clicker/control');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getStatus':
          return {
            'state': 'paused',
            'serviceEnabled': true,
            'panelVisible': true,
            'message': null,
          };
        case 'command':
          return call.arguments['name'] == 'start' ? 'BLOCKED_EMERGENCY' : 'OK';
        case 'showPanel':
          return false;
        default:
          return null;
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('getStatus reads the Android map', () async {
    final status = await MethodChannelClickerBridge().getStatus();
    expect(
      status,
      const ClickerStatus(
        state: ClickerRunState.paused,
        serviceEnabled: true,
        panelVisible: true,
      ),
    );
  });

  test('command sends the name and maps the result', () async {
    final bridge = MethodChannelClickerBridge();
    expect(
      await bridge.command(ClickerCommand.start),
      CommandResult.blockedEmergency,
    );
    expect(await bridge.command(ClickerCommand.stop), CommandResult.ok);
    expect(calls.first.arguments, {'name': 'start'});
  });

  test('showPanel passes on false', () async {
    expect(await MethodChannelClickerBridge().showPanel(), isFalse);
  });

  test('updateSettings sends vibration', () async {
    await MethodChannelClickerBridge().updateSettings(vibrationOn: false);
    expect(calls.single.method, 'updateSettings');
    expect(calls.single.arguments, {'vibrationOn': false});
  });

  group('ClickerStatus.fromMap', () {
    test('bad data becomes unknown, never a crash', () {
      expect(ClickerStatus.fromMap(null), ClickerStatus.unknown);
      expect(ClickerStatus.fromMap('running'), ClickerStatus.unknown);
      expect(
        ClickerStatus.fromMap({'state': 'flying', 'serviceEnabled': 'yes'}),
        ClickerStatus.unknown,
      );
    });

    test('empty message is ignored', () {
      expect(
        ClickerStatus.fromMap({'state': 'stopped', 'message': ''}).message,
        isNull,
      );
    });
  });

  test('unknown result names become failed', () {
    expect(commandResultFromName('SOMETHING_NEW'), CommandResult.failed);
    expect(commandResultFromName(null), CommandResult.failed);
  });
}
