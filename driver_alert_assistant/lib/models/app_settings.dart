/// Screen colour choice the user can pick in Settings.
enum ThemeChoice { system, light, dark }

/// App-wide settings saved on the phone.
///
/// Click points, conditions and timing per target app are added later as
/// profiles. The Emergency Stop state is kept on the Android side so the
/// floating panel can use it even when this screen is closed.
class AppSettings {
  const AppSettings({
    this.askWhenUnsure = true,
    this.vibrationOn = true,
    this.startDelaySeconds = defaultStartDelaySeconds,
    this.themeChoice = ThemeChoice.system,
  });

  /// Bumped when the saved format changes, so old data can be upgraded.
  static const int schemaVersion = 1;

  static const int defaultStartDelaySeconds = 3;
  static const int minStartDelaySeconds = 0;
  static const int maxStartDelaySeconds = 30;

  /// When the screen cannot be read clearly, ask the user instead of
  /// clicking.
  final bool askWhenUnsure;

  /// Vibrate when the auto clicker starts or stops.
  final bool vibrationOn;

  /// Seconds to wait after pressing Start before the first action.
  final int startDelaySeconds;

  final ThemeChoice themeChoice;

  AppSettings copyWith({
    bool? askWhenUnsure,
    bool? vibrationOn,
    int? startDelaySeconds,
    ThemeChoice? themeChoice,
  }) {
    return AppSettings(
      askWhenUnsure: askWhenUnsure ?? this.askWhenUnsure,
      vibrationOn: vibrationOn ?? this.vibrationOn,
      startDelaySeconds: clampStartDelay(
        startDelaySeconds ?? this.startDelaySeconds,
      ),
      themeChoice: themeChoice ?? this.themeChoice,
    );
  }

  static int clampStartDelay(int seconds) {
    if (seconds < minStartDelaySeconds) return minStartDelaySeconds;
    if (seconds > maxStartDelaySeconds) return maxStartDelaySeconds;
    return seconds;
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'askWhenUnsure': askWhenUnsure,
    'vibrationOn': vibrationOn,
    'startDelaySeconds': startDelaySeconds,
    'themeChoice': themeChoice.name,
  };

  /// Reads saved settings. Any missing or wrong value falls back to its
  /// default, so bad saved data can never crash the app.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    const defaults = AppSettings();
    bool readBool(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    final delay = json['startDelaySeconds'];
    final themeName = json['themeChoice'];

    return AppSettings(
      askWhenUnsure: readBool('askWhenUnsure', defaults.askWhenUnsure),
      vibrationOn: readBool('vibrationOn', defaults.vibrationOn),
      startDelaySeconds: delay is int
          ? clampStartDelay(delay)
          : defaults.startDelaySeconds,
      themeChoice: ThemeChoice.values.firstWhere(
        (choice) => choice.name == themeName,
        orElse: () => defaults.themeChoice,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.askWhenUnsure == askWhenUnsure &&
      other.vibrationOn == vibrationOn &&
      other.startDelaySeconds == startDelaySeconds &&
      other.themeChoice == themeChoice;

  @override
  int get hashCode =>
      Object.hash(askWhenUnsure, vibrationOn, startDelaySeconds, themeChoice);
}
