import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthLifecycleEvent {
  signedIn,
  signedOut,
  intentionalSignedOut,
  passwordRecovery,
}

abstract interface class AuthSessionService {
  String? get currentUserId;
  String get currentUsername;
  String? get currentEmail;
  bool get isAnonymous;
  bool get isLegacyAccount;
  bool get isEmailVerified;
  bool get hasPasswordRecoverySession;
  Stream<String?> get userIdChanges;
  Stream<AuthLifecycleEvent> get lifecycleEvents;
  Future<void> signOut();
  void consumePasswordRecoverySession();
}

class SupabaseAuthSessionService implements AuthSessionService {
  SupabaseAuthSessionService(this._client);

  final SupabaseClient _client;
  bool _hasPasswordRecoverySession = false;
  bool _intentionalSignOutRequested = false;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String get currentUsername =>
      _client.auth.currentUser?.userMetadata?['display_name'] as String? ??
      _client.auth.currentUser?.userMetadata?['username'] as String? ??
      'Guest';

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  bool get isAnonymous => _client.auth.currentUser?.isAnonymous ?? false;

  @override
  bool get isLegacyAccount =>
      !isAnonymous &&
      (currentEmail?.toLowerCase().endsWith('@guessparty.com') ?? false);

  @override
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  @override
  bool get hasPasswordRecoverySession => _hasPasswordRecoverySession;

  @override
  Stream<String?> get userIdChanges => _client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();

  @override
  Stream<AuthLifecycleEvent> get lifecycleEvents => _client
      .auth
      .onAuthStateChange
      .map((state) {
        switch (state.event) {
          case AuthChangeEvent.passwordRecovery:
            _hasPasswordRecoverySession = true;
            return AuthLifecycleEvent.passwordRecovery;
          case AuthChangeEvent.signedOut:
            _hasPasswordRecoverySession = false;
            final intentional = _intentionalSignOutRequested;
            _intentionalSignOutRequested = false;
            return intentional
                ? AuthLifecycleEvent.intentionalSignedOut
                : AuthLifecycleEvent.signedOut;
          case AuthChangeEvent.signedIn:
            return AuthLifecycleEvent.signedIn;
          default:
            return null;
        }
      })
      .where((event) => event != null)
      .cast<AuthLifecycleEvent>();

  @override
  void consumePasswordRecoverySession() {
    _hasPasswordRecoverySession = false;
  }

  @override
  Future<void> signOut() async {
    _intentionalSignOutRequested = true;
    try {
      await _client.auth.signOut();
    } catch (_) {
      _intentionalSignOutRequested = false;
      rethrow;
    }
  }
}
