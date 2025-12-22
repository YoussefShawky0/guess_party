import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class SubmitHint {
  final GameRepository repository;

  SubmitHint(this.repository);

  Future<Either<Failure, void>> call({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    // Validate hint
    if (hint.trim().isEmpty) {
      return Left(ValidationFailure('لا يمكن إرسال تلميح فارغ'));
    }

    if (hint.length < 2) {
      return Left(ValidationFailure('التلميح يجب أن يكون حرفين على الأقل'));
    }

    if (hint.length > 200) {
      return Left(ValidationFailure('التلميح طويل جداً (الحد الأقصى 200 حرف)'));
    }

    return await repository.submitHint(
      roundId: roundId,
      playerId: playerId,
      hint: hint.trim(),
    );
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}