import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guess_party/features/auth/presentation/views/auth_view.dart';
import 'package:guess_party/features/auth/presentation/views/login_view.dart';
import 'package:guess_party/features/auth/presentation/views/reset_password_view.dart';
import 'package:guess_party/features/auth/presentation/views/account_upgrade_view.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';
import 'package:guess_party/features/game/presentation/views/game_over_view.dart';
import 'package:guess_party/features/game/presentation/views/game_view.dart';
import 'package:guess_party/features/game/presentation/views/local_mode_game_screen.dart';
import 'package:guess_party/features/game/presentation/views/local_role_reveal_view.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/views/home_view.dart';
import 'package:guess_party/features/home/presentation/views/settings_view.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/countdown_cubit.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/features/room/presentation/views/countdown_view.dart';
import 'package:guess_party/features/room/presentation/views/create_room_view.dart';
import 'package:guess_party/features/room/presentation/views/join_room_view.dart';
import 'package:guess_party/features/room/presentation/views/waiting_room_view.dart';
import 'package:guess_party/shared/presentation/views/splash_screen.dart';
import 'package:guess_party/l10n/l10n.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.pageNotFound,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.routeLabel(state.uri.toString()),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      //splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            SplashScreen(session: sl<AuthSessionService>()),
      ),
      //auth flow
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: AuthView(
            sessionEnded:
                state.uri.queryParameters['reason'] == 'session-ended',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const LoginView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: ResetPasswordView(session: sl<AuthSessionService>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountUpgrade,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: AccountUpgradeView(session: sl<AuthSessionService>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<HomeCubit>()..loadUserInfo(),
          child: HomeView(config: sl<AppConfig>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => SettingsView(
          themeCubit: sl<ThemeCubit>(),
          localeCubit: sl<LocaleCubit>(),
          config: sl<AppConfig>(),
          homeRepository: sl<HomeRepository>(),
        ),
      ),
      //room flow
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (context, state) {
          final session = sl<AuthSessionService>();
          if (session.currentUserId == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.createRoom)),
              body: Center(child: Text(context.l10n.userNotAuthenticated)),
            );
          }
          return BlocProvider(
            create: (_) => sl<RoomCubit>(),
            child: CreateRoomView(
              username: session.currentUsername,
              roomQueryService: sl<RoomQueryService>(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<RoomCubit>(),
          child: JoinRoomView(session: sl<AuthSessionService>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.roomWaitingTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return BlocProvider(
            create: (_) => sl<RoomCubit>()
              ..loadRoomDetails(roomId: roomId)
              ..watchRoomStatus(roomId: roomId),
            child: WaitingRoomView(
              roomId: roomId,
              currentUserIdResolver: () =>
                  sl<AuthSessionService>().currentUserId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomCountdownTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return BlocProvider(
            create: (_) => CountdownCubit(
              gameRepository: sl<GameRepository>(),
              roomRepository: sl<RoomRepository>(),
              roomId: roomId,
            ),
            child: CountdownScreen(roomId: roomId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomRoleRevealTemplate,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final preservedScores = extra?['playerScores'] as Map<String, int>?;
          return BlocProvider(
            create: (_) => sl<LocalRoleRevealCubit>()..load(roomId),
            child: LocalRoleRevealScreen(
              roomId: roomId,
              preservedScores: preservedScores,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomGameTemplate,
        redirect: (context, state) async {
          final roomId = state.pathParameters['roomId']!;
          try {
            final status = await sl<RoomQueryService>().getRoomStatus(roomId);
            if (status == null || status == 'finished') {
              return AppRoutes.home;
            }
          } catch (_) {
            // If we can't check, let the game screen handle it
          }
          return null; // No redirect — proceed to game
        },
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final preservedScores = extra?['playerScores'] as Map<String, int>?;
          return RepositoryProvider<ChatRepository>.value(
            value: sl<ChatRepository>(),
            child: GameView(
              roomId: roomId,
              preservedScores: preservedScores,
              session: sl<AuthSessionService>(),
              roomRepository: sl<RoomRepository>(),
              createGameCubit: () => sl<GameCubit>(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomLocalGameTemplate,
        redirect: (context, state) async {
          final roomId = state.pathParameters['roomId']!;
          try {
            final status = await sl<RoomQueryService>().getRoomStatus(roomId);
            if (status == null || status == 'finished') {
              return AppRoutes.home;
            }
          } catch (_) {
            // If we can't check, let the game screen handle it
          }
          return null;
        },
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final preservedScores = extra?['playerScores'] as Map<String, int>?;
          final session = sl<AuthSessionService>();
          return BlocProvider(
            create: (_) => sl<GameCubit>()
              ..loadGameState(
                roomId: roomId,
                currentPlayerId: session.currentUserId ?? '',
                preservedScores: preservedScores,
              ),
            child: LocalModeGameScreen(roomId: roomId, session: session),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomGameOverTemplate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final players = extra?['players'];
          final playerScores = extra?['playerScores'];
          if (extra == null ||
              players is! List<Player> ||
              playerScores is! Map<String, int>) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.gameDataUnavailable,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return GameOverView(
            players: players,
            playerScores: playerScores,
            adService: sl<InterstitialAdService>(),
          );
        },
      ),
    ],
  );
}
