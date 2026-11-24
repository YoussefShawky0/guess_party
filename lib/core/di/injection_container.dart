import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:guess_party/core/data/audioplayers_cue_player.dart';
import 'package:guess_party/core/data/device_game_feedback.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guess_party/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:guess_party/features/auth/data/datasources/auth_api_client.dart';
import 'package:guess_party/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:guess_party/features/auth/domain/repositories/auth_repository.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';
import 'package:guess_party/features/game/data/repositories/game_repository_impl.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';
import 'package:guess_party/features/home/data/datasources/home_remote_data_source.dart';
import 'package:guess_party/features/home/data/repositories/home_repository_impl.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/data/repositories/room_repository_impl.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/rematch_invite_cubit.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/features/room/presentation/cubit/room_invites_cubit.dart';
import 'package:guess_party/features/stats/data/datasources/stats_remote_data_source.dart';
import 'package:guess_party/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:guess_party/features/stats/data/shared_prefs_seen_badges_store.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/features/stats/domain/seen_badges_store.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/core/data/supabase_server_clock.dart';
import 'package:guess_party/core/services/server_clock.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/chat/data/repositories/supabase_chat_repository.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:guess_party/core/data/google_interstitial_ad_service.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';

final sl = GetIt.instance;

/// Sounds and haptics must never stop the app from starting: any failure
/// falls back to silent feedback.
Future<GameFeedback> _createGameFeedback() async {
  try {
    final feedback = DeviceGameFeedback(
      preferences: await SharedPreferences.getInstance(),
      player: AudioplayersCuePlayer(),
    );
    unawaited(feedback.preload());
    return feedback;
  } catch (error, stackTrace) {
    unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    return SilentGameFeedback();
  }
}

Future<void> init({required AppConfig config}) async {
  sl.registerSingleton<AppConfig>(config);
  // Ads are Android-only for now: iOS has no AdMob app ID configured yet.
  final adUnitId = config.adMobInterstitialUnitId;
  sl.registerSingleton<InterstitialAdService>(
    adUnitId != null && defaultTargetPlatform == TargetPlatform.android
        ? GoogleInterstitialAdService(adUnitId: adUnitId)
        : const DisabledInterstitialAdService(),
  );
  sl.registerSingleton<GameFeedback>(await _createGameFeedback());
  // ============= Theme =============
  final themeCubit = ThemeCubit();
  await themeCubit.loadSavedTheme();
  sl.registerSingleton<ThemeCubit>(themeCubit);

  final localeCubit = LocaleCubit();
  await localeCubit.loadSavedLocale();
  sl.registerSingleton<LocaleCubit>(localeCubit);

  // Supabase Client
  final supabase = Supabase.instance.client;
  sl.registerLazySingleton<SupabaseClient>(() => supabase);
  sl.registerLazySingleton<AuthSessionService>(
    () => SupabaseAuthSessionService(sl()),
  );
  sl.registerLazySingleton<RoomQueryService>(
    () => SupabaseRoomQueryService(sl()),
  );
  sl.registerLazySingleton<ServerClock>(() => SupabaseServerClock(sl()));
  sl.registerLazySingleton(() => TimeSyncService(sl()));
  sl.registerLazySingleton<ChatRepository>(() => SupabaseChatRepository(sl()));

  // ============= Auth Feature =============
  //Auth Cubit
  sl.registerFactory(() => AuthCubit(repository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), authSessionService: sl()),
  );
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(authApi: sl()),
  );
  sl.registerLazySingleton<AuthApiClient>(() => SupabaseAuthApiClient(sl()));

  // ============= Home Feature =============

  sl.registerFactory(() => HomeCubit(repository: sl()));

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(
      supabaseClient: sl(),
      authSessionService: sl(),
    ),
  );

  // ============= Room Feature =============

  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerFactory(() => RoomCubit(repository: sl()));

  sl.registerFactoryParam<
    RematchInviteCubit,
    ({String previousRoomId, String userId}),
    void
  >(
    (args, _) => RematchInviteCubit(
      repository: sl(),
      previousRoomId: args.previousRoomId,
      userId: args.userId,
    ),
  );

  sl.registerFactoryParam<RoomInvitesCubit, String, void>(
    (roomId, _) => RoomInvitesCubit(repository: sl(), roomId: roomId),
  );

  // ============= Stats Feature =============

  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<SeenBadgesStore>(() => SharedPrefsSeenBadgesStore());

  sl.registerFactory(
    () => PlayerStatsCubit(repository: sl(), seenBadgesStore: sl()),
  );

  // ============= Game Feature =============

  sl.registerLazySingleton<GameRemoteDataSource>(
    () => GameRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<GameRepository>(
    () =>
        GameRepositoryImpl(remoteDataSource: sl(), roomRemoteDataSource: sl()),
  );

  sl.registerFactory(
    () => GameCubit(gameRepository: sl(), timeSyncService: sl()),
  );

  sl.registerFactory(() => LocalRoleRevealCubit(repository: sl()));
}
