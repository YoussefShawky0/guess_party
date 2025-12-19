import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignUpWithPassword {
  final AuthRepository repository;

  SignUpWithPassword(this.repository);

  ResultFuture<Player> call({
    required String username,
    required String password,
  }) {
    return repository.signUpWithPassword(
      username: username,
      password: password,
    );
  }
}
