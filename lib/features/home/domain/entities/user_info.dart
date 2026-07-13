import 'package:equatable/equatable.dart';

class UserInfo extends Equatable {
  final String id;
  final String username;
  final bool isAnonymous;
  final String? email;
  final bool isLegacyAccount;

  const UserInfo({
    required this.id,
    required this.username,
    required this.isAnonymous,
    required this.email,
    required this.isLegacyAccount,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    isAnonymous,
    email,
    isLegacyAccount,
  ];
}
