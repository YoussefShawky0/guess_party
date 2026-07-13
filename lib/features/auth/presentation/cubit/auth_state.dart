import 'package:equatable/equatable.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

const passwordResetRequestMessage =
    'If an account exists for that email, a password reset link has been sent.';

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Player player;

  const AuthSuccess(this.player);

  @override
  List<Object?> get props => [player];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthMessage extends AuthState {
  const AuthMessage(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
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
