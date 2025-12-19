import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignInGuest {
  final AuthRepository repository;

  SignInGuest(this.repository);

  ResultFuture<Player> call(String username) {
    return repository.signInAsGuest(username);
  }
}