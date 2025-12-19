import 'package:go_router/go_router.dart';
import 'package:guess_party/features/auth/presentation/views/auth_view.dart';
import 'package:guess_party/features/auth/presentation/views/login_view.dart';
import 'package:guess_party/features/home/presentation/views/home_view.dart';
import 'package:guess_party/features/room/presentation/views/countdown_screen.dart';
import 'package:guess_party/features/room/presentation/views/create_room_view.dart';
import 'package:guess_party/features/room/presentation/views/join_room_view.dart';
import 'package:guess_party/features/room/presentation/views/waiting_room_view.dart';
import 'package:guess_party/shared/presentation/views/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
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
    ],
  );
}
