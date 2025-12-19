import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignInWithPassword {
  final AuthRepository repository;

  SignInWithPassword(this.repository);

  ResultFuture<Player> call({
    required String username,
    required String password,
  }) {
    return repository.signInWithPassword(
      username: username,
      password: password,
    );
  }
}
