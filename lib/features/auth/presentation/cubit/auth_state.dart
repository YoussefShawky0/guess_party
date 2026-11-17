import 'package:equatable/equatable.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Player player;

  const AuthSuccess(this.player);

  @override
  List<Object?> get props => [player];
}

class AuthError extends AuthState {
  final AppErrorCode code;

  const AuthError(this.code);

  @override
  List<Object?> get props => [code];
}

class AuthMessage extends AuthState {
  const AuthMessage(this.code);

  /// A notice (for example [AppErrorCode.passwordResetRequested]), not an error.
  final AppErrorCode code;

  @override
  List<Object?> get props => [code];
}

class AuthUpgradePending extends AuthState {
  const AuthUpgradePending(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}
