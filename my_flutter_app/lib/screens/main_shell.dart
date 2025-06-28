import 'package:flutter/material.dart';
import '../navigation/bottom_navigation_bar_professional.dart';
import 'home_screen_fixed.dart';
import 'insights_dashboard_enhanced.dart';
import 'settings_screen_professional.dart';
import 'parenting_info_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final String userStyle = 'Secure + Assertive'; // Replace with actual logic

  List<Widget> get _screens => [
    HomeScreen(key: const PageStorageKey('HomeScreen')),
    InsightsDashboardEnhanced(key: const PageStorageKey('InsightsDashboard')),
    ParentingInfoScreen(key: const PageStorageKey('ParentingInfoScreen')),
    SettingsScreenProfessional(
      key: const PageStorageKey('SettingsScreen'),
      sensitivity: 0.5,
      onSensitivityChanged: (_) {},
      tone: 'Polite',
      onToneChanged: (_) {},
    ),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.pushNamed(context, '/settings');
      },
    );
  }
}
