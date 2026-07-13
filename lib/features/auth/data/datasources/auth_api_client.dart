import 'package:supabase_flutter/supabase_flutter.dart';

const authCallbackUrl = 'io.supabase.guessparty://login-callback';
const legacyAccountDomain = 'guessparty.com';

class EmailVerificationRequiredException implements Exception {
  const EmailVerificationRequiredException();
}

class AuthUserSnapshot {
  const AuthUserSnapshot({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.isEmailVerified,
  });

  final String id;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final bool isEmailVerified;

  bool get isLegacyAccount =>
      !isAnonymous &&
      (email?.toLowerCase().endsWith('@$legacyAccountDomain') ?? false);
}

abstract interface class AuthApiClient {
  AuthUserSnapshot? get currentUser;

  Future<AuthUserSnapshot> signInAnonymously(String displayName);
  Future<AuthUserSnapshot> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AuthUserSnapshot> updateEmail({
    required String email,
    required String displayName,
  });
  Future<AuthUserSnapshot> updatePassword(String password);
  Future<void> requestPasswordReset(String email);
}

class SupabaseAuthApiClient implements AuthApiClient {
  SupabaseAuthApiClient(this._client);

  final SupabaseClient _client;

  @override
  AuthUserSnapshot? get currentUser => _snapshot(_client.auth.currentUser);

  @override
  Future<AuthUserSnapshot> signInAnonymously(String displayName) async {
    final response = await _client.auth.signInAnonymously(
      data: _metadata(displayName, isGuest: true),
    );
    return _requireUser(response.user);
  }

  @override
  Future<AuthUserSnapshot> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: _metadata(displayName, isGuest: false),
      emailRedirectTo: authCallbackUrl,
    );
    if (response.session == null) {
      throw const EmailVerificationRequiredException();
    }
    return _requireUser(response.user);
  }

  @override
  Future<AuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _requireUser(response.user);
  }

  @override
  Future<AuthUserSnapshot> updateEmail({
    required String email,
    required String displayName,
  }) async {
    final response = await _client.auth.updateUser(
      UserAttributes(
        email: email,
        data: _metadata(displayName, isGuest: false),
      ),
      emailRedirectTo: authCallbackUrl,
    );
    return _requireUser(response.user);
  }

  @override
  Future<AuthUserSnapshot> updatePassword(String password) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: password),
    );
    return _requireUser(response.user);
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: authCallbackUrl);

  static Map<String, dynamic> _metadata(
    String displayName, {
    required bool isGuest,
  }) => {
    'display_name': displayName,
    'username': displayName,
    'is_guest': isGuest,
  };

  static AuthUserSnapshot _requireUser(User? user) {
    final snapshot = _snapshot(user);
    if (snapshot == null) {
      throw const AuthException('Authentication did not return a user.');
    }
    return snapshot;
  }

  static AuthUserSnapshot? _snapshot(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata;
    final displayName =
        metadata?['display_name'] as String? ??
        metadata?['username'] as String? ??
        user.email?.split('@').first ??
        'Guest';
    return AuthUserSnapshot(
      id: user.id,
      email: user.email,
      displayName: displayName,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }
}
