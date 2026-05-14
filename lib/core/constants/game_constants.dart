class GameConstants {
  static const int maxPlayers = 4;
  static const int minPlayers = 4;
  static const int defaultRounds = 5;
  static const int hintPhaseDurationSeconds = 300;
  static const int votingPhaseDurationSeconds = 60;
  static const int resultsPhaseDurationSeconds = 30;

  static const String gameModeOnline = 'online';
  static const String gameModeLocal = 'local';

  static const List<String> categories = [
    'football_players',
    'islamic_figures',
    'daily_products',
    'places',
    'foods',
    'animals',
  ];

  static const Map<String, String> categoryNames = {
    'football_players': 'Football Players',
    'islamic_figures': 'Islamic Figures',
    'daily_products': 'Daily Products',
    'places': 'Places',
    'foods': 'Foods',
    'animals': 'Animals',
  };
}
