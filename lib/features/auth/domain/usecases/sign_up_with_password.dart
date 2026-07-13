import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignUpWithPassword {
  final AuthRepository repository;

  SignUpWithPassword(this.repository);

  ResultFuture<Player> call({
    required String email,
    required String displayName,
    required String password,
  }) {
    return repository.signUpWithPassword(
      email: email,
      displayName: displayName,
      password: password,
    );
  }
}
