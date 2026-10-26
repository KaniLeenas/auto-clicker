import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/clicker_status.dart';
import '../services/clicker_bridge.dart';

/// Keeps the screens up to date with the Android clicker state and sends
/// control commands. Any error talking to Android is caught and shown,
/// never thrown at the screens.
class ClickerController extends ChangeNotifier {
  ClickerController(this._bridge);

  final ClickerBridge _bridge;
  StreamSubscription<ClickerStatus>? _subscription;
  ClickerStatus _status = ClickerStatus.unknown;
  bool _bridgeError = false;

  ClickerStatus get status => _status;

  /// True when the Android part of the app could not be reached.
  bool get bridgeError => _bridgeError;

  Future<void> init() async {
    _subscription = _bridge.statusStream.listen(
      _setStatus,
      onError: (Object _) => _setError(),
    );
    await refresh();
  }

  Future<void> refresh() async {
    try {
      _setStatus(await _bridge.getStatus());
    } catch (_) {
      _setError();
    }
  }

  Future<CommandResult> send(ClickerCommand command) async {
    try {
      final result = await _bridge.command(command);
      await refresh();
      return result;
    } catch (_) {
      _setError();
      return CommandResult.failed;
    }
  }

  Future<bool> showPanel() => _call(_bridge.showPanel);

  Future<bool> hidePanel() => _call(_bridge.hidePanel);

  Future<bool> openAccessibilitySettings() =>
      _call(_bridge.openAccessibilitySettings, refreshAfter: false);

  Future<bool> openAppInfo() => _call(_bridge.openAppInfo, refreshAfter: false);

  Future<void> updateSettings({required bool vibrationOn}) async {
    try {
      await _bridge.updateSettings(vibrationOn: vibrationOn);
    } catch (_) {
      _setError();
    }
  }

  Future<bool> _call(
    Future<bool> Function() action, {
    bool refreshAfter = true,
  }) async {
    try {
      final ok = await action();
      if (refreshAfter) await refresh();
      return ok;
    } catch (_) {
      _setError();
      return false;
    }
  }

  void _setStatus(ClickerStatus status) {
    _status = status;
    _bridgeError = false;
    notifyListeners();
  }

  void _setError() {
    _bridgeError = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
