import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/presentation/views/game_over_view.dart';
import 'package:guess_party/features/room/data/models/room_model.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/rematch_invite_cubit.dart';
import 'package:guess_party/l10n/app_localizations.dart';

class _FakeAds implements InterstitialAdService {
  int shows = 0;

  @override
  Future<void> initialize() async {}

  @override
  void preload() {}

  @override
  Future<void> showAfterGameIfReady() async => shows++;
}

class _FakeRepo implements RoomRepository {
  Completer<Room> roomCompleter = Completer<Room>();
  int roomFetches = 0;
  final invites = StreamController<List<RoomInvite>>.broadcast();
  final List<bool> responses = [];

  @override
  ResultFuture<Room> getRoomDetails({required String roomId}) async {
    roomFetches++;
    return Right(await roomCompleter.future);
  }

  @override
  Stream<List<RoomInvite>> watchMyRematchInvites({
    required String previousRoomId,
    required String userId,
  }) => invites.stream;

  @override
  ResultFuture<RoomSession?> respondToRematchInvite({
    required String roomId,
    required bool accept,
  }) async {
    responses.add(accept);
    if (!accept) return const Right(null);
    const room = RoomModel(
      id: 'new-room',
      hostId: 'h',
      category: 'movies',
      maxRounds: 3,
      currentRound: 0,
      roomCode: '111111',
      status: 'waiting',
      usedCharacterIds: [],
      maxPlayers: 6,
      roundDuration: 60,
      gameMode: 'online',
    );
    const player = PlayerModel(
      id: 'p',
      roomId: 'new-room',
      userId: 'u2',
      username: 'Guest',
      score: 0,
      isHost: false,
    );
    return const Right(
      RoomSession(room: room, currentPlayer: player, players: [player]),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _room = Room(
  id: 'old-room',
  hostId: 'u1',
  category: 'movies',
  maxRounds: 4,
  currentRound: 4,
  roomCode: '123456',
  status: 'finished',
  usedCharacterIds: [],
  maxPlayers: 6,
  roundDuration: 420,
  gameMode: 'online',
);

const _players = [
  Player(
    id: 'p1',
    roomId: 'old-room',
    userId: 'u1',
    username: 'Sam',
    score: 3,
    isHost: true,
  ),
  Player(
    id: 'p2',
    roomId: 'old-room',
    userId: 'u2',
    username: 'Guest',
    score: 1,
    isHost: false,
  ),
];

Future<(GoRouter, _FakeRepo, _FakeAds, List<Object?>)> _pump(
  WidgetTester tester, {
  required String userId,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  final ads = _FakeAds();
  final extras = <Object?>[];
  final router = GoRouter(
    initialLocation: '/over',
    routes: [
      GoRoute(
        path: '/over',
        builder: (_, __) => GameOverView(
          players: _players,
          playerScores: const {'p1': 3, 'p2': 1},
          adService: ads,
          roomId: 'old-room',
          currentUserId: userId,
          roomRepository: repo,
          createRematchInviteCubit: () => RematchInviteCubit(
            repository: repo,
            previousRoomId: 'old-room',
            userId: userId,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (_, state) {
          extras.add(state.extra);
          return const Scaffold(body: Text('Create'));
        },
      ),
      GoRoute(
        path: AppRoutes.roomWaitingTemplate,
        builder: (_, __) => const Scaffold(body: Text('Waiting')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
  await tester.pumpAndSettle();
  return (router, repo, ads, extras);
}

RoomInvite _invite() => const RoomInvite(
  roomId: 'new-room',
  previousRoomId: 'old-room',
  userId: 'u2',
  username: 'Guest',
  status: RoomInviteStatus.pending,
);

void main() {
  testWidgets('host sees Play Again, guest does not', (tester) async {
    final (router, _, _, _) = await _pump(tester, userId: 'u1');
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.byKey(const Key('rematch-invite-card')), findsNothing);
    router.dispose();

    final (router2, _, _, _) = await _pump(tester, userId: 'u2');
    expect(find.text('Play Again'), findsNothing);
    router2.dispose();
  });

  testWidgets('Play Again is single-flight and opens Create Room with seed', (
    tester,
  ) async {
    final (router, repo, ads, extras) = await _pump(tester, userId: 'u1');

    await tester.tap(find.text('Play Again'));
    await tester.pump();
    await tester.tap(find.text('Back to Home'));
    await tester.tap(find.text('Play Again'));
    await tester.pump();

    expect(repo.roomFetches, 1);
    expect(find.text('Home'), findsNothing);

    repo.roomCompleter.complete(_room);
    await tester.pumpAndSettle();

    expect(ads.shows, 1);
    expect(find.text('Create'), findsOneWidget);
    final seed = extras.single as RematchSeed;
    expect(seed.previousRoomId, 'old-room');
    expect(seed.category, 'movies');
    expect(seed.roundDuration, 420);
    router.dispose();
  });

  testWidgets('guest sees the invite card; Join accepts and goes to waiting', (
    tester,
  ) async {
    final (router, repo, ads, _) = await _pump(tester, userId: 'u2');
    expect(find.byKey(const Key('rematch-invite-card')), findsNothing);

    repo.invites.add([_invite()]);
    await tester.pumpAndSettle();
    expect(find.text('Sam wants to play again'), findsOneWidget);

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(repo.responses, [true]);
    expect(ads.shows, 1);
    expect(find.text('Waiting'), findsOneWidget);
    router.dispose();
  });

  testWidgets('No thanks hides the card and stays on Game Over', (
    tester,
  ) async {
    final (router, repo, _, _) = await _pump(tester, userId: 'u2');
    repo.invites.add([_invite()]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();

    expect(repo.responses, [false]);
    expect(find.byKey(const Key('rematch-invite-card')), findsNothing);
    expect(find.text('Back to Home'), findsOneWidget);
    router.dispose();
  });
}
