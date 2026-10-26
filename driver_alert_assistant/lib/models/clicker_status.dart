/// What the auto clicker is doing, as reported by the Android side.
enum ClickerRunState { stopped, running, paused, emergencyStopped, unknown }

/// Control buttons on the Home screen and the floating panel.
enum ClickerCommand {
  start,
  pause,
  resume,
  stop,
  emergencyStop,
  clearEmergency,
}

/// Answer to a [ClickerCommand].
enum CommandResult {
  ok,
  blockedEmergency,
  blockedNoService,
  notAllowedNow,
  unknownCommand,

  /// The Android side could not be reached.
  failed,
}

class ClickerStatus {
  const ClickerStatus({
    required this.state,
    this.serviceEnabled = false,
    this.panelVisible = false,
    this.message,
  });

  static const ClickerStatus unknown = ClickerStatus(
    state: ClickerRunState.unknown,
  );

  final ClickerRunState state;

  /// True when the accessibility service is turned on and connected.
  final bool serviceEnabled;

  /// True when the floating panel is on screen.
  final bool panelVisible;

  /// Last important message, e.g. why the clicker stopped.
  final String? message;

  bool get isEmergency => state == ClickerRunState.emergencyStopped;

  /// Reads the map sent by Android. Unexpected values become "unknown"
  /// instead of crashing.
  factory ClickerStatus.fromMap(Object? raw) {
    if (raw is! Map) return unknown;
    final stateName = raw['state'];
    final message = raw['message'];
    return ClickerStatus(
      state: ClickerRunState.values.firstWhere(
        (s) => s.name == stateName && s != ClickerRunState.unknown,
        orElse: () => ClickerRunState.unknown,
      ),
      serviceEnabled: raw['serviceEnabled'] == true,
      panelVisible: raw['panelVisible'] == true,
      message: message is String && message.isNotEmpty ? message : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClickerStatus &&
      other.state == state &&
      other.serviceEnabled == serviceEnabled &&
      other.panelVisible == panelVisible &&
      other.message == message;

  @override
  int get hashCode => Object.hash(state, serviceEnabled, panelVisible, message);
}

/// Maps the Android result name (e.g. "BLOCKED_EMERGENCY") to [CommandResult].
CommandResult commandResultFromName(Object? name) {
  switch (name) {
    case 'OK':
      return CommandResult.ok;
    case 'BLOCKED_EMERGENCY':
      return CommandResult.blockedEmergency;
    case 'BLOCKED_NO_SERVICE':
      return CommandResult.blockedNoService;
    case 'NOT_ALLOWED_NOW':
      return CommandResult.notAllowedNow;
    case 'UNKNOWN_COMMAND':
      return CommandResult.unknownCommand;
    default:
      return CommandResult.failed;
  }
}
