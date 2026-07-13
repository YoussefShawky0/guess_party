import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_model.dart';
import 'auth_api_client.dart';

abstract class AuthRemoteDataSource {
  Future<PlayerModel> signInAsGuest(String username);
  Future<String> getCurrentUserId();
  Future<PlayerModel> signUpWithPassword(
    String email,
    String displayName,
    String password,
  );
  Future<PlayerModel> signInWithPassword(String email, String password);
  Future<PlayerModel> signInLegacyWithPassword(
    String username,
    String password,
  );
  Future<void> requestPasswordReset(String email);
  Future<String> beginAccountUpgrade(String email, String displayName);
  Future<void> setVerifiedAccountPassword(String password);
  Future<void> updateRecoveredPassword(String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApiClient authApi;

  AuthRemoteDataSourceImpl({required this.authApi});

  @override
  Future<PlayerModel> signInAsGuest(String username) async {
    try {
      // Sign in anonymously (requires Anonymous Auth enabled in Supabase)
      final user = await authApi.signInAnonymously(username);
      return _playerFromUser(user, fallbackDisplayName: username);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<String> getCurrentUserId() async {
    final user = authApi.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return user.id;
  }

  @override
  Future<PlayerModel> signUpWithPassword(
    String email,
    String displayName,
    String password,
  ) async {
    final user = await authApi.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      displayName: displayName.trim(),
    );
    return _playerFromUser(user, fallbackDisplayName: displayName);
  }

  @override
  Future<PlayerModel> signInWithPassword(String email, String password) async {
    final user = await authApi.signInWithEmail(
      email: email.trim().toLowerCase(),
      password: password,
    );
    return _playerFromUser(user, fallbackDisplayName: email.split('@').first);
  }

  @override
  Future<PlayerModel> signInLegacyWithPassword(
    String username,
    String password,
  ) => signInWithPassword(
    '${username.trim().toLowerCase()}@$legacyAccountDomain',
    password,
  );

  @override
  Future<void> requestPasswordReset(String email) =>
      authApi.requestPasswordReset(email.trim().toLowerCase());

  @override
  Future<String> beginAccountUpgrade(String email, String displayName) async {
    final currentUser = authApi.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'Please sign in before upgrading or migrating an account.',
      );
    }
    if (!currentUser.isAnonymous && !currentUser.isLegacyAccount) {
      throw const AuthException('This account already uses a real email.');
    }

    final originalUserId = currentUser.id;
    final updatedUser = await authApi.updateEmail(
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
    );
    if (updatedUser.id != originalUserId) {
      throw const AuthException(
        'Account upgrade was stopped because the user identity changed.',
      );
    }
    return originalUserId;
  }

  @override
  Future<void> setVerifiedAccountPassword(String password) async {
    final currentUser = authApi.currentUser;
    if (currentUser == null || !currentUser.isEmailVerified) {
      throw const AuthException(
        'Verify your email before setting an account password.',
      );
    }
    await authApi.updatePassword(password);
  }

  @override
  Future<void> updateRecoveredPassword(String password) async {
    if (authApi.currentUser == null) {
      throw const AuthException('The recovery session is no longer valid.');
    }
    await authApi.updatePassword(password);
  }

  static PlayerModel _playerFromUser(
    AuthUserSnapshot user, {
    required String fallbackDisplayName,
  }) => PlayerModel(
    id: user.id,
    roomId: '',
    userId: user.id,
    username: user.displayName.isEmpty
        ? fallbackDisplayName.trim()
        : user.displayName,
    score: 0,
    isHost: false,
  );
}
