import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../state/clicker_controller.dart';
import '../state/settings_controller.dart';
import 'theme.dart';

class ClickerApp extends StatelessWidget {
  const ClickerApp({super.key, required this.settings, required this.clicker});

  static const String title = 'Smart Auto Clicker';

  final SettingsController settings;
  final ClickerController clicker;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: AppTheme.modeFor(settings.settings.themeChoice),
        home: HomeShell(settings: settings, clicker: clicker),
      ),
    );
  }
}

/// Bottom tabs: Home and Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.settings, required this.clicker});

  final SettingsController settings;
  final ClickerController clicker;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The user may come back from Android Settings after turning on
    // accessibility, so check the status again.
    _lifecycle = AppLifecycleListener(onResume: widget.clicker.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(settings: widget.settings, clicker: widget.clicker),
          SettingsScreen(controller: widget.settings),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
