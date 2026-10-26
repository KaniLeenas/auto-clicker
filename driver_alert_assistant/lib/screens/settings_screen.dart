import 'package:flutter/material.dart';

import '../app/app.dart';
import '../models/app_settings.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final settings = controller.settings;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionTitle('Safety'),
              SwitchListTile(
                title: const Text('Ask me when unsure'),
                subtitle: const Text(
                  'If the screen can\'t be read clearly, ask me '
                  'instead of skipping',
                ),
                value: settings.askWhenUnsure,
                onChanged: (on) =>
                    controller.update((s) => s.copyWith(askWhenUnsure: on)),
              ),
              SwitchListTile(
                title: const Text('Vibrate on start and stop'),
                value: settings.vibrationOn,
                onChanged: (on) =>
                    controller.update((s) => s.copyWith(vibrationOn: on)),
              ),
              const Divider(),
              const _SectionTitle('Timing'),
              ListTile(
                title: const Text('Wait before starting'),
                subtitle: Text('${settings.startDelaySeconds} seconds'),
              ),
              Slider(
                min: AppSettings.minStartDelaySeconds.toDouble(),
                max: AppSettings.maxStartDelaySeconds.toDouble(),
                divisions:
                    AppSettings.maxStartDelaySeconds -
                    AppSettings.minStartDelaySeconds,
                value: settings.startDelaySeconds.toDouble(),
                label: '${settings.startDelaySeconds} s',
                onChanged: (value) => controller.update(
                  (s) => s.copyWith(startDelaySeconds: value.round()),
                ),
              ),
              const Divider(),
              const _SectionTitle('Screen colours'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeChoice>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeChoice.system,
                      label: Text('Phone'),
                    ),
                    ButtonSegment(
                      value: ThemeChoice.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(value: ThemeChoice.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeChoice},
                  onSelectionChanged: (choice) => controller.update(
                    (s) => s.copyWith(themeChoice: choice.first),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset all settings'),
                onTap: () => _confirmReset(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About this app'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: ClickerApp.title,
                  applicationVersion: '1.0.0',
                  children: const [
                    Text(
                      'Clicks for you based on rules you set. It only '
                      'clicks when it can clearly check your rules, and '
                      'never tries to get around another app\'s security '
                      'or rules. All data stays on this phone.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all settings?'),
        content: const Text('All settings go back to their first values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yes == true) await controller.resetToDefaults();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
