import 'package:get_it/get_it.dart';
import 'package:guess_party/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:guess_party/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:guess_party/features/auth/domain/repositories/auth_repository.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_in_guest.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:guess_party/features/auth/domain/usecases/sign_up_with_password.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guess_party/features/home/data/datasources/home_remote_data_source.dart';
import 'package:guess_party/features/home/data/repositories/home_repository_impl.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/domain/usecases/get_current_user.dart';
import 'package:guess_party/features/home/domain/usecases/sign_out.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/data/repositories/room_repository_impl.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/domain/usecases/add_player_to_room.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Supabase Client
  final supabase = Supabase.instance.client;
  sl.registerLazySingleton<SupabaseClient>(() => supabase);

  // ============= Auth Feature =============
  //Auth Cubit
  sl.registerFactory(
    () => AuthCubit(
      signInGuest: sl(),
      signUpWithPassword: sl(),
      signInWithPasswordUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInGuest(sl()));
  sl.registerLazySingleton(() => SignUpWithPassword(sl()));
  sl.registerLazySingleton(() => SignInWithPassword(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  // ============= Home Feature =============

  sl.registerFactory(() => HomeCubit(getCurrentUser: sl(), signOut: sl()));

  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // ============= Room Feature =============

  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => AddPlayerToRoom(sl()));
  sl.registerLazySingleton(() => GetRoomDetails(sl()));
  sl.registerLazySingleton(() => GetRoomPlayers(sl()));
  sl.registerLazySingleton(() => GetRoomByCode(sl()));
  sl.registerLazySingleton(() => StartGame(sl()));
  sl.registerLazySingleton(() => UpdatePlayerStatus(sl()));
  sl.registerLazySingleton(() => LeaveRoom(sl()));

  sl.registerFactory(
    () => RoomCubit(
      createRoom: sl(),
      addPlayerToRoom: sl(),
      getRoomDetails: sl(),
      getRoomPlayers: sl(),
      getRoomByCode: sl(),
      startGame: sl(),
      updatePlayerStatus: sl(),
      leaveRoom: sl(),
    ),
  );
}
