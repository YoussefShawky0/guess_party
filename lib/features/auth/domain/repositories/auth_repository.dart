import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';

abstract class AuthRepository {
  ResultFuture<Player> signInAsGuest(String username);
  ResultFuture<String> getCurrentUserId();

  ResultFuture<Player> signUpWithPassword({
    required String username,
    required String password,
  });

  ResultFuture<Player> signInWithPassword({
    required String username,
    required String password,
  });
}
