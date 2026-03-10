/// Centralised route path constants.
/// Use [AppRoutes.xxx] constants for simple routes and the static builder
/// methods (e.g. [AppRoutes.roomGame]) wherever a roomId is required.
class AppRoutes {
  AppRoutes._();

  // ── Simple routes ────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String createRoom = '/create-room';
  static const String joinRoom = '/join-room';

  // ── Route templates (GoRouter path: definitions — keep :roomId syntax) ──
  static const String roomWaitingTemplate = '/room/:roomId/waiting';
  static const String roomCountdownTemplate = '/room/:roomId/countdown';
  static const String roomRoleRevealTemplate = '/room/:roomId/role-reveal';
  static const String roomGameTemplate = '/room/:roomId/game';
  static const String roomGameOverTemplate = '/room/:roomId/game-over';

  // ── Route builders (context.go / context.push navigation) ────────────────
  static String roomWaiting(String roomId) => '/room/$roomId/waiting';
  static String roomCountdown(String roomId) => '/room/$roomId/countdown';
  static String roomRoleReveal(String roomId) => '/room/$roomId/role-reveal';
  static String roomGame(String roomId) => '/room/$roomId/game';
  static String roomGameOver(String roomId) => '/room/$roomId/game-over';
}
