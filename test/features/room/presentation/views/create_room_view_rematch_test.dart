import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/features/room/presentation/views/create_room_view.dart';
import 'package:guess_party/l10n/app_localizations.dart';

class _FakeQuery implements RoomQueryService {
  @override
  Future<String?> getRoomStatus(String roomId) async => 'finished';

  @override
  Future<Map<String, String>> getActiveCategories() async => {
    'animals': 'Animals',
    'movies': 'Movies',
  };
}

class _FakeRepo implements RoomRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingCubit extends RoomCubit {
  _RecordingCubit() : super(repository: _FakeRepo());

  final calls = <Map<String, Object?>>[];

  @override
  Future<void> createRematch({
    required RematchSeed seed,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String username,
    List<String>? localPlayerNames,
  }) async {
    calls.add({
      'previous': seed.previousRoomId,
      'category': category,
      'rounds': maxRounds,
      'players': maxPlayers,
      'duration': roundDuration,
      'names': localPlayerNames,
    });
  }
}

Future<_RecordingCubit> _pump(WidgetTester tester, RematchSeed seed) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = _RecordingCubit();
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<RoomCubit>.value(
        value: cubit,
        child: CreateRoomView(
          username: 'Sam',
          roomQueryService: _FakeQuery(),
          rematch: seed,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('online seed pre-fills and Create calls createRematch', (
    tester,
  ) async {
    final cubit = await _pump(
      tester,
      const RematchSeed(
        previousRoomId: 'old',
        gameMode: 'online',
        category: 'movies',
        maxRounds: 7,
        maxPlayers: 6,
        roundDuration: 420,
      ),
    );

    expect(find.text('Play Again'), findsOneWidget); // title

    await tester.tap(find.text('Create Room').last);
    await tester.pump();

    expect(cubit.calls, [
      {
        'previous': 'old',
        'category': 'movies',
        'rounds': 7,
        'players': 6,
        'duration': 420,
        'names': null,
      },
    ]);
  });

  testWidgets('local seed pre-fills names and cannot switch mode', (
    tester,
  ) async {
    final cubit = await _pump(
      tester,
      const RematchSeed(
        previousRoomId: 'old',
        gameMode: 'local',
        category: 'gone',
        maxRounds: 3,
        maxPlayers: 4,
        roundDuration: 300,
        localNames: ['Sam', 'Ann', 'Bob', 'Cy'],
      ),
    );

    expect(find.text('Ann'), findsOneWidget);

    // Tapping the Online card must not change the mode.
    await tester.tap(find.text('Online'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Ann'), findsOneWidget);

    await tester.tap(find.text('Create Room').last);
    await tester.pump();

    expect(cubit.calls.single['category'], 'animals'); // fallback to first
    expect(cubit.calls.single['names'], ['Sam', 'Ann', 'Bob', 'Cy']);
  });
}
