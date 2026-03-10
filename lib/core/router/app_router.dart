import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/auth/presentation/views/auth_view.dart';
import 'package:guess_party/features/auth/presentation/views/login_view.dart';
import 'package:guess_party/features/game/presentation/views/game_over_view.dart';
import 'package:guess_party/features/game/presentation/views/game_view.dart';
import 'package:guess_party/features/game/presentation/views/local_role_reveal_view.dart';
import 'package:guess_party/features/home/presentation/views/home_view.dart';
import 'package:guess_party/features/home/presentation/views/settings_view.dart';
import 'package:guess_party/features/room/presentation/views/countdown_view.dart';
import 'package:guess_party/features/room/presentation/views/create_room_view.dart';
import 'package:guess_party/features/room/presentation/views/join_room_view.dart';
import 'package:guess_party/features/room/presentation/views/waiting_room_view.dart';
import 'package:guess_party/shared/presentation/views/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Route: ${state.uri}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        builder: (context, state) => const JoinRoomView(),
      ),
      GoRoute(
        path: AppRoutes.roomWaitingTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return WaitingRoomView(roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.roomCountdownTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CountdownScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.roomRoleRevealTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final preservedScores = extra?['playerScores'] as Map<String, int>?;
          return LocalRoleRevealScreen(
            roomId: roomId,
            preservedScores: preservedScores,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomGameTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final preservedScores = extra?['playerScores'] as Map<String, int>?;
          return GameView(roomId: roomId, preservedScores: preservedScores);
        },
      ),
      GoRoute(
        path: AppRoutes.roomGameOverTemplate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Game data unavailable.')),
            );
          }
          return GameOverView(
            players: extra['players'] as List<Player>,
            playerScores: extra['playerScores'] as Map<String, int>,
          );
        },
      ),
    ],
  );
}
