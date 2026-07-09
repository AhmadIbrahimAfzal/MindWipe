import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/inbox/presentation/screens/inbox_screen.dart';

/// The root [MaterialApp] widget for MindWipe.
///
/// 🧠 LEARN: This is where the entire app's configuration lives:
/// - [theme] sets the visual identity (colors, typography, component styles)
/// - [home] sets the first screen users see
/// - [debugShowCheckedModeBanner] hides the debug ribbon in the corner
///
/// In Phase 4, we'll replace [home] with [go_router] for multi-screen navigation.
class MindWipeApp extends StatelessWidget {
  const MindWipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindWipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InboxScreen(),
    );
  }
}
