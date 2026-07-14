import 'package:equatable/equatable.dart';

class ChatCursor extends Equatable {
  const ChatCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  @override
  List<Object> get props => [createdAt, id];
}
