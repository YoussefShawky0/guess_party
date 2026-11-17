import 'package:equatable/equatable.dart';
import 'package:guess_party/core/error/app_error_code.dart';

/// [message] is for logs and Sentry only. Players are shown [code], localized
/// by the view with `localizedErrorMessage`.
abstract class Failure extends Equatable {
  final String message;
  final AppErrorCode code;
  const Failure(this.message, {this.code = AppErrorCode.unknown});

  @override
  List<Object> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  /// Builds a failure from a caught error, classifying it by [appErrorCodeFrom].
  ServerFailure.from(Object error)
    : super(error.toString(), code: appErrorCodeFrom(error));
}

class EmailVerificationRequiredFailure extends Failure {
  const EmailVerificationRequiredFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}
