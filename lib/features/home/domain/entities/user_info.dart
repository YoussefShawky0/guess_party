import 'package:equatable/equatable.dart';

class UserInfo extends Equatable {
  final String id;
  final String username;
  final bool isAnonymous;

  const UserInfo({
    required this.id,
    required this.username,
    required this.isAnonymous,
  });

  @override
  List<Object?> get props => [id, username, isAnonymous];
}
