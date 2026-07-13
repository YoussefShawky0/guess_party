import '../../../../core/utils/typedef.dart';
import '../repositories/auth_repository.dart';

class UpdateRecoveredPassword {
  const UpdateRecoveredPassword(this.repository);

  final AuthRepository repository;

  ResultVoid call(String password) =>
      repository.updateRecoveredPassword(password);
}
