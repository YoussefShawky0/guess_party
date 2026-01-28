import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final RoomRemoteDataSource roomRemoteDataSource;
  final SupabaseClient client;

  GameRepositoryImpl({
    required this.remoteDataSource,
    required this.roomRemoteDataSource,
    required this.client,
  });

  @override
  Future<Either<Failure, RoundInfo>> getCurrentRound({
    required String roomId,
  }) async {
    try {
      final roundModel = await remoteDataSource.getCurrentRound(roomId: roomId);
      return Right(roundModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameState>> getGameState({
    required String roomId,
    required String currentPlayerId,
  }) async {
    try {
      print('📥 Fetching game state for room: $roomId');

      print('  1️⃣ Getting current round...');
      final roundModel = await remoteDataSource.getCurrentRound(roomId: roomId);
      print(
        '  ✅ Round fetched: ${roundModel.roundNumber}, Phase: ${roundModel.phase}',
      );

      print('  2️⃣ Getting room players...');
      final playerModels = await remoteDataSource.getRoomPlayers(
        roomId: roomId,
      );
      final players = playerModels.map((m) => m.toEntity()).toList();
      print('  ✅ ${players.length} players fetched');

      print('  3️⃣ Getting player scores...');
      final scores = await remoteDataSource.getPlayerScores(roomId: roomId);
      print('  ✅ Scores fetched for ${scores.length} players');

      print('  4️⃣ Getting room details...');
      final room = await roomRemoteDataSource.getRoomDetails(roomId: roomId);
      print(
        '  ✅ Room details fetched: maxRounds=${room.maxRounds}, gameMode=${room.gameMode}',
      );

      final gameState = GameState(
        roomId: roomId,
        currentRound: roundModel.toEntity(),
        players: players,
        currentPlayerId: currentPlayerId,
        totalRounds: room.maxRounds,
        playerScores: scores,
        gameMode: room.gameMode,
      );

      print('✅ Game state created successfully');
      return Right(gameState);
    } catch (e) {
      print('❌ Error getting game state: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    try {
      await remoteDataSource.submitHint(
        roundId: roundId,
        playerId: playerId,
        hint: hint,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    try {
      await remoteDataSource.submitVote(
        roundId: roundId,
        voterId: voterId,
        votedPlayerId: votedPlayerId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> advancePhase({
    required String roundId,
  }) async {
    try {
      // جلب الجولة الحالية
      final currentRoundResponse = await client
          .from('rounds')
          .select('*, rooms!inner(round_duration)')
          .eq('id', roundId)
          .single();

      final currentPhase = currentRoundResponse['phase'] as String;
      final roomDuration =
          currentRoundResponse['rooms']['round_duration'] as int;
      String newPhase;
      int phaseDuration;

      // تحديد المرحلة التالية - fixed durations for consistency
      switch (currentPhase) {
        case 'hints':
          newPhase = 'voting';
          phaseDuration = 60; // Fixed 1 minute for voting
          break;
        case 'voting':
          newPhase = 'results';
          phaseDuration = 30; // Keep 30 seconds for results
          break;
        default:
          throw Exception('Cannot advance from results phase');
      }

      // Use UTC time for consistency
      final phaseEndTime = DateTime.now().toUtc().add(Duration(seconds: phaseDuration));
      print('🕐 Setting phase_end_time (UTC): $phaseEndTime');

      final updatedRound = await remoteDataSource.updateRoundPhase(
        roundId: roundId,
        newPhase: newPhase,
        phaseEndTime: phaseEndTime,
      );

      return Right(updatedRound.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> calculateScores({
    required String roundId,
  }) async {
    try {
      // جلب معلومات الجولة
      final roundResponse = await client
          .from('rounds')
          .select()
          .eq('id', roundId)
          .single();

      final imposterPlayerId = roundResponse['imposter_player_id'] as String;
      final roomId = roundResponse['room_id'] as String;

      // جلب الأصوات
      final votes = await remoteDataSource.getVotesForRound(roundId: roundId);

      // حساب الأصوات لكل لاعب
      final voteCounts = <String, int>{};
      for (final votedPlayerId in votes.values) {
        voteCounts[votedPlayerId] = (voteCounts[votedPlayerId] ?? 0) + 1;
      }

      // إيجاد اللاعب الأكثر حصولاً على أصوات
      String? mostVotedPlayerId;
      int maxVotes = 0;
      for (final entry in voteCounts.entries) {
        if (entry.value > maxVotes) {
          maxVotes = entry.value;
          mostVotedPlayerId = entry.key;
        }
      }

      // جلب النتائج الحالية
      final currentScores = await remoteDataSource.getPlayerScores(
        roomId: roomId,
      );
      final newScores = Map<String, int>.from(currentScores);

      // توزيع النقاط
      if (mostVotedPlayerId == imposterPlayerId) {
        // المحتالون فازوا بتحديد المحتال
        for (final playerId in newScores.keys) {
          if (playerId != imposterPlayerId) {
            newScores[playerId] = (newScores[playerId] ?? 0) + 10;
          }
        }
      } else {
        // المحتال فاز بعدم اكتشافه
        newScores[imposterPlayerId] = (newScores[imposterPlayerId] ?? 0) + 20;
      }

      // تحديث النتائج في قاعدة البيانات
      await remoteDataSource.updatePlayerScores(scores: newScores);

      return Right(newScores);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int roundNumber,
  }) async {
    try {
      // جلب اللاعبين
      final players = await remoteDataSource.getRoomPlayers(roomId: roomId);

      // اختيار محتال عشوائي
      final random = DateTime.now().millisecondsSinceEpoch;
      final imposterIndex = random % players.length;
      final imposterPlayerId = players[imposterIndex].id;

      // جلب معلومات الغرفة للحصول على roundDuration
      final room = await roomRemoteDataSource.getRoomDetails(roomId: roomId);

      // جلب شخصية عشوائية
      final charactersResponse = await client
          .from('characters')
          .select()
          .eq('is_active', true)
          .limit(100);

      final characters = charactersResponse as List;
      if (characters.isEmpty) {
        throw Exception('No characters available');
      }

      final characterIndex = random % characters.length;
      final characterId = characters[characterIndex]['id'] as String;

      // إنشاء جولة جديدة بمدة من إعدادات الغرفة
      final newRound = await remoteDataSource.createRound(
        roomId: roomId,
        imposterPlayerId: imposterPlayerId,
        characterId: characterId,
        roundNumber: roundNumber,
        roundDurationSeconds: room.roundDuration,
      );

      return Right(newRound.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endGame({required String roomId}) async {
    try {
      await remoteDataSource.updateRoomStatus(
        roomId: roomId,
        status: 'finished',
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<RoundInfo> watchRoundUpdates({required String roundId}) async* {
    await for (final _ in remoteDataSource.watchRoundChanges(
      roundId: roundId,
    )) {
      try {
        // جلب معلومات الجولة الكاملة
        final roundResponse = await client
            .from('rounds')
            .select()
            .eq('id', roundId)
            .single();

        final character = await remoteDataSource.getCharacter(
          characterId: roundResponse['character_id'] as String,
        );

        final roomId = roundResponse['room_id'] as String;
        final players = await remoteDataSource.getRoomPlayers(roomId: roomId);
        final playerIds = players.map((p) => p.id).toList();

        final hints = await remoteDataSource.getHintsForRound(roundId: roundId);
        final votes = await remoteDataSource.getVotesForRound(roundId: roundId);

        final roundModel = RoundInfoModel.fromJson(
          roundResponse,
          character.toEntity(),
          playerIds,
          hints,
          votes,
        );

        yield roundModel.toEntity();
      } catch (e) {
        // تجاهل الأخطاء في الـ stream
      }
    }
  }

  @override
  Stream<Map<String, String>> watchHintsUpdates({
    required String roundId,
  }) async* {
    await for (final _ in remoteDataSource.watchHintsChanges(
      roundId: roundId,
    )) {
      final hints = await remoteDataSource.getHintsForRound(roundId: roundId);
      yield hints;
    }
  }

  @override
  Stream<Map<String, String>> watchVotesUpdates({
    required String roundId,
  }) async* {
    await for (final _ in remoteDataSource.watchVotesChanges(
      roundId: roundId,
    )) {
      final votes = await remoteDataSource.getVotesForRound(roundId: roundId);
      yield votes;
    }
  }
}
