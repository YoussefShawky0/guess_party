import 'package:get_it/get_it.dart';
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
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
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

final sl = GetIt.instance;

Future<void> init({required AppConfig config}) async {
  sl.registerSingleton<AppConfig>(config);
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
