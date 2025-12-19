import 'package:equatable/equatable.dart';
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
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}