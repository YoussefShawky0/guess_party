import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignInLegacyWithPassword {
  const SignInLegacyWithPassword(this.repository);

  final AuthRepository repository;

  ResultFuture<Player> call({
    required String username,
    required String password,
  }) => repository.signInLegacyWithPassword(
    username: username,
    password: password,
  );
}
