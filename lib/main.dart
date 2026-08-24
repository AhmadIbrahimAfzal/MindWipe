import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindwipe/core/services/audio_service.dart';
import 'package:mindwipe/core/constants/supabase_config.dart';
import 'app.dart';

/// The entry point of MindWipe.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioFeedback.init();

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
