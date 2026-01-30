import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/features/auth/presentation/views/auth_view.dart';
import 'package:guess_party/features/auth/presentation/views/login_view.dart';
import 'package:guess_party/features/game/presentation/views/game_view.dart';
import 'package:guess_party/features/game/presentation/views/local_role_reveal_view.dart';
import 'package:guess_party/features/home/presentation/views/home_view.dart';
import 'package:guess_party/features/room/presentation/views/countdown_view.dart';
import 'package:guess_party/features/room/presentation/views/create_room_view.dart';
import 'package:guess_party/features/room/presentation/views/join_room_view.dart';
import 'package:guess_party/features/room/presentation/views/waiting_room_view.dart';
import 'package:guess_party/shared/presentation/views/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true, // Enable debug logging
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
              Text(
                'Route: ${state.uri}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: '/join-room',
        builder: (context, state) => const JoinRoomView(),
      ),
      GoRoute(
        path: '/room/:roomId/waiting',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return WaitingRoomView(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/room/:roomId/countdown',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CountdownScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/room/:roomId/role-reveal',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return LocalRoleRevealScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/room/:roomId/game',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return GameView(roomId: roomId);
        },
      ),
    ],
  );
}
