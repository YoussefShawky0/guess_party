import 'package:equatable/equatable.dart';

class Character extends Equatable {
  final String id;

  /// Arabic name (the original content language).
  final String name;

  /// English name; null for rows added before English names existed.
  final String? nameEn;
  final String emoji;
  final String category;
  final String difficulty;
  final bool isActive;

  const Character({
    required this.id,
    required this.name,
    this.nameEn,
    required this.emoji,
    required this.category,
    required this.difficulty,
    required this.isActive,
  });

  /// The name to show for [languageCode]; falls back to Arabic.
  String displayName(String languageCode) {
    final en = nameEn?.trim();
    return languageCode == 'en' && en != null && en.isNotEmpty ? en : name;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameEn,
    emoji,
    category,
    difficulty,
    isActive,
  ];
}
