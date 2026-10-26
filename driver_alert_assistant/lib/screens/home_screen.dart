import 'package:flutter/material.dart';

import '../app/app.dart';
import '../app/theme.dart';
import '../models/clicker_status.dart';
import '../state/clicker_controller.dart';
import '../state/settings_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings, required this.clicker});

  final SettingsController settings;
  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ClickerApp.title)),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, clicker]),
        builder: (context, _) {
          final status = clicker.status;
          final s = settings.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (status.isEmergency) ...[
                _EmergencyBanner(clicker: clicker),
                const SizedBox(height: 16),
              ],
              if (clicker.bridgeError) ...[
                const _InfoCard(
                  icon: Icons.error_outline,
                  title: 'Can\'t reach the clicker service.',
                  subtitle: 'Close the app fully and open it again.',
                ),
                const SizedBox(height: 16),
              ],
              if (settings.lastSaveFailed) ...[
                const _InfoCard(
                  icon: Icons.warning_amber,
                  title: 'Could not save your last change.',
                  subtitle: 'It will be lost when the app closes. Try again.',
                ),
                const SizedBox(height: 16),
              ],
              if (status.message != null && !status.isEmergency) ...[
                _InfoCard(icon: Icons.info_outline, title: status.message!),
                const SizedBox(height: 16),
              ],
              _StatusCard(status: status),
              const SizedBox(height: 16),
              if (!status.serviceEnabled) ...[
                _PermissionCard(clicker: clicker),
                const SizedBox(height: 16),
              ],
              _PanelButton(clicker: clicker),
              const SizedBox(height: 12),
              _Controls(clicker: clicker),
              const SizedBox(height: 8),
              Text(
                'Running does not click anything yet. '
                'Click points and rules come in later updates.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _EmergencyStopButton(clicker: clicker),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(
                        'Wait ${s.startDelaySeconds} seconds before starting',
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        s.askWhenUnsure
                            ? Icons.help_outline
                            : Icons.warning_amber,
                      ),
                      title: Text(
                        s.askWhenUnsure
                            ? 'Asks you when unsure: ON'
                            : 'Asks you when unsure: OFF',
                      ),
                      subtitle: s.askWhenUnsure
                          ? null
                          : const Text('Unclear screens are skipped.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Only works where Android and the other app allow it. '
                'Use it within each app\'s rules.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Short, driver-friendly text for a command result. Null means "say nothing".
String? resultMessage(CommandResult result) {
  switch (result) {
    case CommandResult.ok:
      return null;
    case CommandResult.blockedEmergency:
      return 'Emergency Stop is ON. Turn it off first.';
    case CommandResult.blockedNoService:
      return 'Turn on accessibility for Smart Auto Clicker first.';
    case CommandResult.notAllowedNow:
      return 'Not possible right now.';
    case CommandResult.unknownCommand:
    case CommandResult.failed:
      return 'Something went wrong. Try again.';
  }
}

void _showResult(BuildContext context, CommandResult result) {
  final text = resultMessage(result);
  if (text == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final ClickerStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (String title, IconData icon, Color color) = switch (status.state) {
      ClickerRunState.running => (
        'Auto clicker is RUNNING',
        Icons.play_circle,
        scheme.primaryContainer,
      ),
      ClickerRunState.paused => (
        'Auto clicker is PAUSED',
        Icons.pause_circle,
        scheme.tertiaryContainer,
      ),
      ClickerRunState.emergencyStopped => (
        'EMERGENCY STOP',
        Icons.stop_circle,
        scheme.errorContainer,
      ),
      ClickerRunState.stopped => (
        'Auto clicker is STOPPED',
        Icons.touch_app_outlined,
        scheme.surfaceContainer,
      ),
      ClickerRunState.unknown => (
        'Status unknown',
        Icons.help_outline,
        scheme.surfaceContainer,
      ),
    };
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    status.serviceEnabled
                        ? 'Accessibility: ON'
                        : 'Accessibility: OFF',
                  ),
                  Text(
                    status.panelVisible
                        ? 'Floating panel: shown'
                        : 'Floating panel: hidden',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.clicker});

  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Turn on accessibility',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Android needs this so the floating panel can show over '
              'other apps. Later it also lets the app see buttons and '
              'tap for you, only using your rules. Nothing leaves this '
              'phone.',
            ),
            const SizedBox(height: 8),
            const Text(
              'In Settings, open Installed apps (or Downloaded apps), '
              'choose Smart Auto Clicker and turn it on.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final opened = await clicker.openAccessibilitySettings();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open Settings. Open it by hand.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Open Accessibility settings'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showRestrictedHelp(context),
              child: const Text('The switch is greyed out?'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRestrictedHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow restricted settings'),
        content: const Text(
          'Android 13 and newer block accessibility for apps not '
          'installed from the Play Store, until you allow it:\n\n'
          '1. Try to turn on the switch once (it will be blocked).\n'
          '2. Open App info for Smart Auto Clicker.\n'
          '3. Tap ⋮ (top right) → Allow restricted settings.\n'
          '4. Go back and turn on accessibility.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clicker.openAppInfo();
            },
            child: const Text('Open App info'),
          ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.clicker});

  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    final status = clicker.status;
    if (status.panelVisible) {
      return OutlinedButton.icon(
        onPressed: () async {
          final hidden = await clicker.hidePanel();
          if (!hidden && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stop the auto clicker first.')),
            );
          }
        },
        icon: const Icon(Icons.visibility_off),
        label: const Text('Hide floating panel'),
      );
    }
    return OutlinedButton.icon(
      onPressed: status.serviceEnabled ? clicker.showPanel : null,
      icon: const Icon(Icons.picture_in_picture_alt),
      label: const Text('Show floating panel'),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.clicker});

  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    final state = clicker.status.state;
    final canStart =
        state == ClickerRunState.stopped && clicker.status.serviceEnabled;
    final active =
        state == ClickerRunState.running || state == ClickerRunState.paused;

    Future<void> send(ClickerCommand command) async {
      final result = await clicker.send(command);
      if (!context.mounted) return;
      _showResult(context, result);
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: canStart ? () => send(ClickerCommand.start) : null,
            child: const Text('Start'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: state == ClickerRunState.paused
              ? FilledButton.tonal(
                  onPressed: () => send(ClickerCommand.resume),
                  child: const Text('Resume'),
                )
              : FilledButton.tonal(
                  onPressed: state == ClickerRunState.running
                      ? () => send(ClickerCommand.pause)
                      : null,
                  child: const Text('Pause'),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: active ? () => send(ClickerCommand.stop) : null,
            child: const Text('Stop'),
          ),
        ),
      ],
    );
  }
}

class _EmergencyStopButton extends StatelessWidget {
  const _EmergencyStopButton({required this.clicker});

  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.danger,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(64),
      ),
      onPressed: () async {
        final result = await clicker.send(ClickerCommand.emergencyStop);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == CommandResult.ok
                  ? 'Emergency Stop: everything stopped.'
                  : 'Emergency Stop could not reach the clicker service. '
                        'Close the app fully.',
            ),
          ),
        );
      },
      icon: const Icon(Icons.stop_circle, size: 28),
      label: const Text('EMERGENCY STOP'),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.clicker});

  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Emergency Stop is ON',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Text(
              'Everything is stopped. Nothing will start again '
              'until you turn this off.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Turn off Emergency Stop'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off Emergency Stop?'),
        content: const Text(
          'The auto clicker will stay stopped. You can start it again yourself.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final result = await clicker.send(ClickerCommand.clearEmergency);
    if (!context.mounted) return;
    _showResult(context, result);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
      ),
    );
  }
}
