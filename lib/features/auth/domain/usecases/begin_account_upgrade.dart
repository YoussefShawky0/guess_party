import '../../../../core/utils/typedef.dart';
import '../repositories/auth_repository.dart';

class BeginAccountUpgrade {
  const BeginAccountUpgrade(this.repository);

  final AuthRepository repository;

  ResultFuture<String> call({
    required String email,
    required String displayName,
  }) => repository.beginAccountUpgrade(email: email, displayName: displayName);
}
