import 'package:equatable/equatable.dart';

class Character extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String difficulty;
  final bool isActive;

  const Character({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.difficulty,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, emoji, category, difficulty, isActive];
}
