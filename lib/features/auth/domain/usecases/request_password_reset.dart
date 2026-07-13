import '../../../../core/utils/typedef.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordReset {
  const RequestPasswordReset(this.repository);

  final AuthRepository repository;

  ResultVoid call(String email) => repository.requestPasswordReset(email);
}
