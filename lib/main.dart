import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// The entry point of MindWipe.
///
/// 🧠 LEARN: Every Flutter app starts here. [main()] is the first function
/// Dart calls when your app launches.
///
/// [WidgetsFlutterBinding.ensureInitialized()] must be called before any
/// Flutter APIs are used (like setting system UI styles). It initializes
/// the binding between Dart and the native platform.
///
/// [SystemChrome] lets us control native OS UI elements — here we make
/// the status bar transparent and the navigation bar match our dark theme.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Make the system navigation bar blend with our dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000), // Pure black navigation bar
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: MindWipeApp(),
    ),
  );
}
