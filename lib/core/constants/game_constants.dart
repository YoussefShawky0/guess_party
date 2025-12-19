class GameConstants {
  static const int maxPlayers = 4;
  static const int minPlayers = 4;
  static const int defaultRounds = 5;
  static const int hintPhaseDurationSeconds = 300;
  static const int votingPhaseDurationSeconds = 60;

  static const List<String> categories = [
    'football_players',
    'islamic_figures',
    'daily_products',
  ];

  static const Map<String, String> categoryNames = {
    'football_players': 'لاعيبة كورة',
    'islamic_figures': 'شخصيات إسلامية',
    'daily_products': 'منتجات يومية',
  };
}
