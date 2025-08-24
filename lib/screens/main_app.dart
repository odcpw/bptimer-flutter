/// MainApp - Core navigation and screen management
/// 
/// Provides bottom navigation between Timer, SMAs, Statistics, and Settings.
/// Matches the PWA's tab-based interface with consistent theming.

library;

import 'package:flutter/material.dart';
import 'timer_screen.dart';
import 'sma_screen.dart';
import 'stats_screen.dart';
import 'about_screen.dart';
import '../utils/constants.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey _statsScreenKey = GlobalKey();

  // App screens will be built in build method to access _statsScreenKey

  // Navigation items - PWA order: Timer → SMAs → Statistics → About
  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.timer),
      label: 'Timer',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.notifications_active),
      label: 'SMAs',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'Statistics',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.info_outline),
      label: 'About',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: UIConstants.mediumAnimationMs),
      curve: Curves.easeInOut,
    );
  }

  /// Handle page view changes (swipe navigation)
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // When switching to Statistics tab, trigger a refresh to ensure latest data
    if (index == 2) {
      final state = _statsScreenKey.currentState;
      // Use dynamic call to avoid private state type coupling
      (state as dynamic?)?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build screens in build method to access _statsScreenKey
    final screens = [
      const TimerScreen(),
      const SMAScreen(),
      StatsScreen(key: _statsScreenKey),
      const AboutScreen(),
    ];
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navigationItems,
        backgroundColor: const Color(0xFF2a2a2a),
        selectedItemColor: const Color(0xFF20b2aa),
        unselectedItemColor: const Color(0xFF888888),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
