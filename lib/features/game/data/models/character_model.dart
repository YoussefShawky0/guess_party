import 'package:guess_party/features/game/domain/entities/character.dart';

class CharacterModel extends Character {
  const CharacterModel({
    required super.id,
    required super.name,
    required super.emoji,
    required super.category,
    required super.difficulty,
    required super.isActive,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '❓',
      category: json['category'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
      'difficulty': difficulty,
      'is_active': isActive,
    };
  }

  Character toEntity() {
    return Character(
      id: id,
      name: name,
      emoji: emoji,
      category: category,
      difficulty: difficulty,
      isActive: isActive,
    );
  }
}
