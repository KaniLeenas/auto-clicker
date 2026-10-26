import 'dart:async';

import 'package:driver_alert_assistant/models/clicker_status.dart';
import 'package:driver_alert_assistant/services/clicker_bridge.dart';

/// In-memory stand-in for the Android side, following the same rules as
/// the Kotlin ClickerStateMachine.
class FakeClickerBridge implements ClickerBridge {
  FakeClickerBridge({
    this.state = ClickerRunState.stopped,
    this.serviceEnabled = true,
    this.panelVisible = false,
    this.message,
  });

  ClickerRunState state;
  bool serviceEnabled;
  bool panelVisible;
  String? message;
  bool? lastVibrationOn;
  bool failCalls = false;
  final List<String> calls = [];
  final _controller = StreamController<ClickerStatus>.broadcast();

  ClickerStatus get current => ClickerStatus(
    state: state,
    serviceEnabled: serviceEnabled,
    panelVisible: panelVisible,
    message: message,
  );

  /// Simulates a change made on the floating panel.
  void push() => _controller.add(current);

  void _check(String name) {
    calls.add(name);
    if (failCalls) throw StateError('bridge down');
  }

  @override
  Stream<ClickerStatus> get statusStream => _controller.stream;

  @override
  Future<ClickerStatus> getStatus() async {
    _check('getStatus');
    return current;
  }

  @override
  Future<CommandResult> command(ClickerCommand command) async {
    _check('command:${command.name}');
    final active =
        state == ClickerRunState.running || state == ClickerRunState.paused;
    switch (command) {
      case ClickerCommand.start:
        if (state == ClickerRunState.emergencyStopped) {
          return CommandResult.blockedEmergency;
        }
        if (!serviceEnabled) return CommandResult.blockedNoService;
        if (state != ClickerRunState.stopped) {
          return CommandResult.notAllowedNow;
        }
        state = ClickerRunState.running;
      case ClickerCommand.pause:
        if (state != ClickerRunState.running) {
          return CommandResult.notAllowedNow;
        }
        state = ClickerRunState.paused;
      case ClickerCommand.resume:
        if (state != ClickerRunState.paused) return CommandResult.notAllowedNow;
        state = ClickerRunState.running;
      case ClickerCommand.stop:
        if (active) state = ClickerRunState.stopped;
      case ClickerCommand.emergencyStop:
        state = ClickerRunState.emergencyStopped;
      case ClickerCommand.clearEmergency:
        if (state != ClickerRunState.emergencyStopped) {
          return CommandResult.notAllowedNow;
        }
        state = ClickerRunState.stopped;
    }
    return CommandResult.ok;
  }

  @override
  Future<bool> showPanel() async {
    _check('showPanel');
    if (!serviceEnabled) return false;
    panelVisible = true;
    return true;
  }

  @override
  Future<bool> hidePanel() async {
    _check('hidePanel');
    if (state == ClickerRunState.running || state == ClickerRunState.paused) {
      return false;
    }
    panelVisible = false;
    return true;
  }

  @override
  Future<void> updateSettings({required bool vibrationOn}) async {
    _check('updateSettings');
    lastVibrationOn = vibrationOn;
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    _check('openAccessibilitySettings');
    return true;
  }

  @override
  Future<bool> openAppInfo() async {
    _check('openAppInfo');
    return true;
  }

  Future<void> close() => _controller.close();
}
