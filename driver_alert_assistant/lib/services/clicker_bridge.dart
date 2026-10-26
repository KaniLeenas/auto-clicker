import 'package:flutter/services.dart';

import '../models/clicker_status.dart';

/// Talks to the Android (Kotlin) part of the auto clicker.
abstract class ClickerBridge {
  Stream<ClickerStatus> get statusStream;
  Future<ClickerStatus> getStatus();
  Future<CommandResult> command(ClickerCommand command);

  /// Returns false when accessibility is off.
  Future<bool> showPanel();

  /// Returns false while the clicker is running or paused.
  Future<bool> hidePanel();
  Future<void> updateSettings({required bool vibrationOn});
  Future<bool> openAccessibilitySettings();
  Future<bool> openAppInfo();
}

class MethodChannelClickerBridge implements ClickerBridge {
  MethodChannelClickerBridge({MethodChannel? control, EventChannel? status})
    : _control = control ?? const MethodChannel('smart_clicker/control'),
      _status = status ?? const EventChannel('smart_clicker/status');

  final MethodChannel _control;
  final EventChannel _status;

  @override
  Stream<ClickerStatus> get statusStream =>
      _status.receiveBroadcastStream().map(ClickerStatus.fromMap);

  @override
  Future<ClickerStatus> getStatus() async =>
      ClickerStatus.fromMap(await _control.invokeMethod<Object?>('getStatus'));

  @override
  Future<CommandResult> command(ClickerCommand command) async =>
      commandResultFromName(
        await _control.invokeMethod<Object?>('command', {'name': command.name}),
      );

  @override
  Future<bool> showPanel() async =>
      await _control.invokeMethod<bool>('showPanel') ?? false;

  @override
  Future<bool> hidePanel() async =>
      await _control.invokeMethod<bool>('hidePanel') ?? false;

  @override
  Future<void> updateSettings({required bool vibrationOn}) => _control
      .invokeMethod<void>('updateSettings', {'vibrationOn': vibrationOn});

  @override
  Future<bool> openAccessibilitySettings() async =>
      await _control.invokeMethod<bool>('openAccessibilitySettings') ?? false;

  @override
  Future<bool> openAppInfo() async =>
      await _control.invokeMethod<bool>('openAppInfo') ?? false;
}
