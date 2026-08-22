import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state representation.
///
/// 🧠 LEARN: We model three states:
/// - [guest]: Anonymous Supabase session — the user dropped in without signing up.
/// - [authenticated]: The user linked a real identity (Google/Apple).
/// - [unauthenticated]: No session at all (initial cold start before anon sign-in).
enum AuthStatus { unauthenticated, guest, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  final AuthStatus status;
  final User? user;

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  String? get email => user?.email;
  String get displayId => user?.id.substring(0, 8) ?? 'offline';
}

/// Manages Supabase authentication lifecycle.
///
/// 🧠 LEARN: Guest-First Flow:
/// 1. On app launch, we call [signInAnonymously] to get an invisible session.
/// 2. The user never sees a login wall — they go straight to their tasks.
/// 3. Later, from the Account screen, they can "upgrade" by linking Google/Apple.
/// 4. Supabase converts the anonymous user into a permanent account,
///    preserving all their data (the user ID stays the same).
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to Supabase auth state changes
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) {
      _updateState(data.session);
    });

    // Check current session
    final session = supabase.auth.currentSession;
    return _buildState(session);
  }

  AuthState _buildState(Session? session) {
    if (session == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    final user = session.user;
    // Anonymous users have no linked identities
    final isAnonymous = user.identities?.isEmpty ?? true;
    return AuthState(
      status: isAnonymous ? AuthStatus.guest : AuthStatus.authenticated,
      user: user,
    );
  }

  void _updateState(Session? session) {
    state = _buildState(session);
  }

  /// Signs in anonymously — called once on first launch.
  Future<void> ensureSession() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession != null) return;

    await supabase.auth.signInAnonymously();
  }

  /// Links Google OAuth to the current anonymous account.
  Future<void> linkGoogle() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.mindwipe.mindwipe://login-callback',
    );
  }

  /// Links Apple Sign-In to the current anonymous account.
  Future<void> linkApple() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.mindwipe.mindwipe://login-callback',
    );
  }

  /// Signs out and returns to guest state.
  Future<void> signOut() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    // Re-create anonymous session
    await ensureSession();
  }
}

/// Riverpod provider for authentication state.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
