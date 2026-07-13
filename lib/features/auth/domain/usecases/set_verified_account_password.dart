import '../../../../core/utils/typedef.dart';
import '../repositories/auth_repository.dart';

class SetVerifiedAccountPassword {
  const SetVerifiedAccountPassword(this.repository);

  final AuthRepository repository;

  ResultVoid call(String password) =>
      repository.setVerifiedAccountPassword(password);
}
