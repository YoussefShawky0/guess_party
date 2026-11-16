import 'package:equatable/equatable.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final UserInfo userInfo;

  const HomeLoaded({required this.userInfo});

  @override
  List<Object?> get props => [userInfo];
}

class HomeError extends HomeState {
  final AppErrorCode code;

  const HomeError({required this.code});

  @override
  List<Object?> get props => [code];
}

class HomeSignedOut extends HomeState {}
