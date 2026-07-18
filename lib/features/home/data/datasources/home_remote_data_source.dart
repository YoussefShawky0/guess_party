import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth_session_service.dart';

abstract class HomeRemoteDataSource {
  Future<UserInfo> getCurrentUser();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AuthSessionService authSessionService;

  HomeRemoteDataSourceImpl({
    required this.supabaseClient,
    required this.authSessionService,
  });

  @override
  Future<UserInfo> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      final username =
          user.userMetadata?['display_name'] ??
          user.userMetadata?['username'] ??
          'Guest';
      final email = user.email;

      return UserInfo(
        id: user.id,
        username: username,
        isAnonymous: user.isAnonymous,
        email: email,
        isLegacyAccount:
            !user.isAnonymous &&
            (email?.toLowerCase().endsWith('@guessparty.com') ?? false),
      );
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await authSessionService.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await supabaseClient.rpc('delete_current_account');
      await authSessionService.signOut();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
