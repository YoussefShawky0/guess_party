import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_model.dart';

abstract class AuthRemoteDataSource {
  Future<PlayerModel> signInAsGuest(String username);
  Future<String> getCurrentUserId();
  Future<PlayerModel> signUpWithPassword(String username, String password);
  Future<PlayerModel> signInWithPassword(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<PlayerModel> signInAsGuest(String username) async {
    try {
      // Sign in anonymously (requires Anonymous Auth enabled in Supabase)
      final authResponse = await client.auth.signInAnonymously(
        data: {'username': username, 'is_guest': true},
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in');
      }

      return PlayerModel(
        id: authResponse.user!.id,
        roomId: '',
        userId: authResponse.user!.id,
        username: username,
        score: 0,
        isHost: false,
      );
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<String> getCurrentUserId() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return user.id;
  }

  @override
  Future<PlayerModel> signUpWithPassword(
    String username,
    String password,
  ) async {
    try {
      final email = '${username.toLowerCase()}@guessparty.com';

      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'is_guest': false},
        emailRedirectTo: null,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign up');
      }

      return PlayerModel(
        id: authResponse.user!.id,
        roomId: '',
        userId: authResponse.user!.id,
        username: username,
        score: 0,
        isHost: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PlayerModel> signInWithPassword(
    String username,
    String password,
  ) async {
    try {
      final email = '${username.toLowerCase()}@guessparty.com';

      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in');
      }

      final savedUsername =
          authResponse.user!.userMetadata?['username'] ?? username;

      return PlayerModel(
        id: authResponse.user!.id,
        roomId: '',
        userId: authResponse.user!.id,
        username: savedUsername,
        score: 0,
        isHost: false,
      );
    } catch (e) {
      rethrow;
    }
  }
}
