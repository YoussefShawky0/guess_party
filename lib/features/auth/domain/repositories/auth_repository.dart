import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';

abstract class AuthRepository {
  ResultFuture<Player> signInAsGuest(String username);
  ResultFuture<String> getCurrentUserId();

  ResultFuture<Player> signUpWithPassword({
    required String email,
    required String displayName,
    required String password,
  });

  ResultFuture<Player> signInWithPassword({
    required String email,
    required String password,
  });

  ResultFuture<Player> signInLegacyWithPassword({
    required String username,
    required String password,
  });

  ResultVoid requestPasswordReset(String email);
  ResultFuture<String> beginAccountUpgrade({
    required String email,
    required String displayName,
  });
  ResultVoid setVerifiedAccountPassword(String password);
  ResultVoid updateRecoveredPassword(String password);
}
