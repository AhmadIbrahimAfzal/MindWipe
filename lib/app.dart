import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'package:mindwipe/features/navigation/presentation/screens/main_shell.dart';
import 'package:mindwipe/features/onboarding/presentation/screens/onboarding_screen.dart';

/// The root [MaterialApp] widget for MindWipe.
///
/// On first launch, shows the 3-slide onboarding flow.
/// On subsequent launches, goes directly to MainShell.
class MindWipeApp extends StatelessWidget {
  const MindWipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindWipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: _hasSeenOnboarding(),
        builder: (context, snapshot) {
          // While loading, show a black screen to avoid flash
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFF000000),
              body: SizedBox.shrink(),
            );
          }
          if (snapshot.data == true) {
            return const MainShell();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }
}
