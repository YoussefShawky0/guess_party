import '../../../../core/utils/typedef.dart';
import '../entities/player.dart';
import '../repositories/auth_repository.dart';

class SignInWithPassword {
  final AuthRepository repository;

  SignInWithPassword(this.repository);

  ResultFuture<Player> call({required String email, required String password}) {
    return repository.signInWithPassword(email: email, password: password);
  }
}
