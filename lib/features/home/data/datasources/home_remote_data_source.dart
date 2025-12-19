import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HomeRemoteDataSource {
  Future<UserInfo> getCurrentUser();
  Future<void> signOut();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient supabaseClient;

  HomeRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserInfo> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      final username = user.userMetadata?['username'] ?? 'Guest';

      return UserInfo(
        id: user.id,
        username: username,
        isAnonymous: user.isAnonymous,
      );
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
