/// SplashScreen - PWA-matching splash screen with logo and loading animation
/// 
/// Shows BPtimer logo, title, and loading spinner for 2 seconds before
/// transitioning to the main app. Matches PWA splash screen design exactly.

library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'main_app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize spinning animation
    _spinController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    // Start spinning
    _spinController.repeat();
    
    // Navigate to main app after splash duration
    Future.delayed(const Duration(milliseconds: UIConstants.splashScreenDurationMs), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainApp(),
            transitionDuration: const Duration(milliseconds: UIConstants.mediumAnimationMs),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f), // Dark background matching PWA
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Full logo like PWA (no cropping)
                Image.asset(
                  'assets/images/icon-512.png',
                  width: 128,
                  height: 128,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Balanced Practice Timer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
