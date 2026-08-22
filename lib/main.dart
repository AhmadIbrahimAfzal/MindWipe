import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindwipe/core/constants/supabase_config.dart';
import 'app.dart';

/// The entry point of MindWipe.
///
/// 🧠 LEARN: We now initialize Supabase before running the app.
/// This sets up the network client, auth session listener, and
/// real-time websocket connection. The app still loads instantly
/// because Supabase init is non-blocking for the UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase SDK
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Make the system navigation bar blend with our dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: MindWipeApp(),
    ),
  );
}
