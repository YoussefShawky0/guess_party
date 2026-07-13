import 'package:get_it/get_it.dart';
import 'package:guess_party/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:guess_party/features/auth/data/datasources/auth_api_client.dart';
import 'package:guess_party/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:guess_party/features/auth/domain/repositories/auth_repository.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_in_guest.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_in_legacy_with_password.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_up_with_password.dart';
import 'package:guess_party/features/auth/domain/usecases/request_password_reset.dart';
import 'package:guess_party/features/auth/domain/usecases/begin_account_upgrade.dart';
import 'package:guess_party/features/auth/domain/usecases/set_verified_account_password.dart';
import 'package:guess_party/features/auth/domain/usecases/update_recovered_password.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';
import 'package:guess_party/features/game/data/repositories/game_repository_impl.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/advance_to_voting.dart';
import 'package:guess_party/features/game/domain/usecases/create_next_round.dart';
import 'package:guess_party/features/game/domain/usecases/extend_local_role_reveal.dart';
import 'package:guess_party/features/game/domain/usecases/finalize_voting.dart';
import 'package:guess_party/features/game/domain/usecases/finish_game.dart';
import 'package:guess_party/features/game/domain/usecases/get_local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/usecases/get_current_round.dart';
import 'package:guess_party/features/game/domain/usecases/get_game_state.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';
import 'package:guess_party/features/home/data/datasources/home_remote_data_source.dart';
import 'package:guess_party/features/home/data/repositories/home_repository_impl.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/domain/usecases/get_current_user.dart';
import 'package:guess_party/features/home/domain/usecases/sign_out.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/data/repositories/room_repository_impl.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/join_room.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_players.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/core/data/supabase_server_clock.dart';
import 'package:guess_party/core/services/server_clock.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/chat/data/repositories/supabase_chat_repository.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============= Theme =============
  final themeCubit = ThemeCubit();
  await themeCubit.loadSavedTheme();
  sl.registerSingleton<ThemeCubit>(themeCubit);

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
  sl.registerFactory(
    () => AuthCubit(
      signInGuest: sl(),
      signUpWithPassword: sl(),
      signInWithPasswordUseCase: sl(),
      signInLegacyWithPasswordUseCase: sl(),
      requestPasswordResetUseCase: sl(),
      beginAccountUpgradeUseCase: sl(),
      setVerifiedAccountPasswordUseCase: sl(),
      updateRecoveredPasswordUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInGuest(sl()));
  sl.registerLazySingleton(() => SignUpWithPassword(sl()));
  sl.registerLazySingleton(() => SignInWithPassword(sl()));
  sl.registerLazySingleton(() => SignInLegacyWithPassword(sl()));
  sl.registerLazySingleton(() => RequestPasswordReset(sl()));
  sl.registerLazySingleton(() => BeginAccountUpgrade(sl()));
  sl.registerLazySingleton(() => SetVerifiedAccountPassword(sl()));
  sl.registerLazySingleton(() => UpdateRecoveredPassword(sl()));

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

  sl.registerFactory(() => HomeCubit(getCurrentUser: sl(), signOut: sl()));

  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

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

  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => GetRoomDetails(sl()));
  sl.registerLazySingleton(() => GetRoomPlayers(sl()));
  sl.registerLazySingleton(() => GetRoomByCode(sl()));
  sl.registerLazySingleton(() => StartGame(sl()));
  sl.registerLazySingleton(() => UpdatePlayerStatus(sl()));
  sl.registerLazySingleton(() => MarkStalePlayersOffline(sl()));
  sl.registerLazySingleton(() => LeaveRoom(sl()));
  sl.registerLazySingleton(() => JoinRoom(sl()));
  sl.registerLazySingleton(() => WatchRoomDetails(sl()));
  sl.registerLazySingleton(() => WatchRoomPlayers(sl()));

  sl.registerFactory(
    () => RoomCubit(
      createRoom: sl(),
      getRoomDetails: sl(),
      getRoomPlayers: sl(),
      getRoomByCode: sl(),
      startGame: sl(),
      updatePlayerStatus: sl(),
      markStalePlayersOffline: sl(),
      leaveRoom: sl(),
      joinRoomCommand: sl(),
      watchRoomDetails: sl(),
      watchRoomPlayers: sl(),
    ),
  );

  // ============= Game Feature =============

  sl.registerLazySingleton<GameRemoteDataSource>(
    () => GameRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<GameRepository>(
    () =>
        GameRepositoryImpl(remoteDataSource: sl(), roomRemoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetCurrentRound(sl()));
  sl.registerLazySingleton(() => SubmitHint(sl()));
  sl.registerLazySingleton(() => SubmitVote(sl()));
  sl.registerLazySingleton(() => GetGameState(repository: sl()));
  sl.registerLazySingleton(() => AdvanceToVoting(sl()));
  sl.registerLazySingleton(() => FinalizeVoting(sl()));
  sl.registerLazySingleton(() => CreateNextRound(sl()));
  sl.registerLazySingleton(() => FinishGame(sl()));
  sl.registerLazySingleton(() => ExtendLocalRoleReveal(sl()));
  sl.registerLazySingleton(() => GetLocalRoleRevealData(sl()));

  sl.registerFactory(
    () => GameCubit(
      getGameState: sl(),
      submitHint: sl(),
      submitVote: sl(),
      advanceToVoting: sl(),
      finalizeVotingUseCase: sl(),
      createNextRound: sl(),
      finishGameUseCase: sl(),
      extendLocalRoleReveal: sl(),
      gameRepository: sl(),
      timeSyncService: sl(),
    ),
  );

  sl.registerFactory(
    () => LocalRoleRevealCubit(
      getLocalRoleRevealData: sl(),
      extendLocalRoleReveal: sl(),
    ),
  );
}
