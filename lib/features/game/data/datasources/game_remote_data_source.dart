import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/game/data/models/character_model.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GameRemoteDataSource {
  Future<RoundInfoModel> getCurrentRound({required String roomId});

  Future<List<PlayerModel>> getRoomPlayers({required String roomId});

  Future<CharacterModel> getCharacter({required String characterId});

  Future<Map<String, String>> getHintsForRound({required String roundId});

  Future<Map<String, String>> getVotesForRound({required String roundId});

  Future<Map<String, int>> getPlayerScores({required String roomId});

  Future<void> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  });

  Future<void> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  });

  Future<RoundInfoModel> updateRoundPhase({
    required String roundId,
    required String newPhase,
    required DateTime phaseEndTime,
  });

  Future<void> updatePlayerScores({required Map<String, int> scores});

  Future<RoundInfoModel> createRound({
    required String roomId,
    required String imposterPlayerId,
    required String characterId,
    required int roundNumber,
    required int roundDurationSeconds,
  });

  Future<void> updateRoomStatus({
    required String roomId,
    required String status,
  });

  Stream<Map<String, dynamic>> watchRoundChanges({required String roundId});

  Stream<Map<String, dynamic>> watchHintsChanges({required String roundId});

  Stream<Map<String, dynamic>> watchVotesChanges({required String roundId});
}

class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final SupabaseClient client;

  GameRemoteDataSourceImpl({required this.client});

  @override
  Future<RoundInfoModel> getCurrentRound({required String roomId}) async {
    try {
      // Get all rounds for this room, ordered by round_number descending
      final validRounds = await client
          .from('rounds')
          .select('*')
          .eq('room_id', roomId)
          .order('round_number', ascending: false);

      if (validRounds.isEmpty) {
        throw Exception(
          'No rounds found for room $roomId. Please wait for round creation.',
        );
      }

      // Filter in Dart to find the first valid round
      Map<String, dynamic>? response;
      Map<String, dynamic>? latestRound = validRounds.first;
      final now = DateTime.now().toUtc();

      for (final round in validRounds) {
        final phaseEndTimeStr = round['phase_end_time'] as String;
        DateTime phaseEndTime;

        // Parse the timestamp as UTC
        if (phaseEndTimeStr.endsWith('Z')) {
          phaseEndTime = DateTime.parse(phaseEndTimeStr).toUtc();
        } else if (phaseEndTimeStr.contains('+') ||
            phaseEndTimeStr.contains('T')) {
          phaseEndTime = DateTime.parse(phaseEndTimeStr).toUtc();
        } else {
          phaseEndTime = DateTime.parse('${phaseEndTimeStr}Z').toUtc();
        }

        // Check if this round is still valid (not expired) - compare UTC to UTC
        if (phaseEndTime.isAfter(now)) {
          response = round;
          break;
        }
      }

      // If no valid round found, use the latest round as fallback
      response ??= latestRound;

      final character = await getCharacter(
        characterId: response['character_id'] as String,
      );

      final players = await getRoomPlayers(roomId: roomId);
      final playerIds = players.map((p) => p.id).toList();

      final hints = await getHintsForRound(roundId: response['id'] as String);
      final votes = await getVotesForRound(roundId: response['id'] as String);

      return RoundInfoModel.fromJson(
        response,
        character.toEntity(),
        playerIds,
        hints,
        votes,
      );
    } catch (e) {
      throw Exception('Failed to get current round: $e');
    }
  }

  @override
  Future<List<PlayerModel>> getRoomPlayers({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select('*')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => PlayerModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get room players: $e');
    }
  }

  @override
  Future<CharacterModel> getCharacter({required String characterId}) async {
    try {
      final response = await client
          .from('characters')
          .select('*')
          .eq('id', characterId)
          .single();

      return CharacterModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get character: $e');
    }
  }

  @override
  Future<Map<String, String>> getHintsForRound({
    required String roundId,
  }) async {
    try {
      final response = await client
          .from('hints')
          .select('player_id, content')
          .eq('round_id', roundId);

      final hintsMap = <String, String>{};
      for (final hint in response) {
        hintsMap[hint['player_id'] as String] = hint['content'] as String;
      }
      return hintsMap;
    } catch (e) {
      throw Exception('Failed to get hints: $e');
    }
  }

  @override
  Future<Map<String, String>> getVotesForRound({
    required String roundId,
  }) async {
    try {
      final response = await client
          .from('votes')
          .select('voter_player_id, voted_player_id')
          .eq('round_id', roundId);

      final votesMap = <String, String>{};
      for (final vote in response) {
        votesMap[vote['voter_player_id'] as String] =
            vote['voted_player_id'] as String;
      }
      return votesMap;
    } catch (e) {
      throw Exception('Failed to get votes: $e');
    }
  }

  @override
  Future<Map<String, int>> getPlayerScores({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select('id, score')
          .eq('room_id', roomId);

      final scoresMap = <String, int>{};
      for (final player in response) {
        scoresMap[player['id'] as String] = player['score'] as int;
      }
      return scoresMap;
    } catch (e) {
      throw Exception('Failed to get player scores: $e');
    }
  }

  @override
  Future<void> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    try {
      // First, check if hint already exists
      final existing = await client
          .from('hints')
          .select('id')
          .eq('round_id', roundId)
          .eq('player_id', playerId)
          .maybeSingle();

      if (existing != null) {
        // Update existing hint
        await client
            .from('hints')
            .update({'content': hint})
            .eq('round_id', roundId)
            .eq('player_id', playerId);
      } else {
        // Insert new hint
        await client.from('hints').insert({
          'round_id': roundId,
          'player_id': playerId,
          'content': hint,
        });
      }
    } catch (e) {
      throw Exception('Failed to submit hint: $e');
    }
  }

  @override
  Future<void> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    try {
      // Check if vote already exists
      final existing = await client
          .from('votes')
          .select('id')
          .eq('round_id', roundId)
          .eq('voter_player_id', voterId)
          .maybeSingle();

      if (existing != null) {
        // Update existing vote
        await client
            .from('votes')
            .update({'voted_player_id': votedPlayerId})
            .eq('round_id', roundId)
            .eq('voter_player_id', voterId);
      } else {
        // Insert new vote
        await client.from('votes').insert({
          'round_id': roundId,
          'voter_player_id': voterId,
          'voted_player_id': votedPlayerId,
        });
      }
    } catch (e) {
      throw Exception('Failed to submit vote: $e');
    }
  }

  @override
  Future<RoundInfoModel> updateRoundPhase({
    required String roundId,
    required String newPhase,
    required DateTime phaseEndTime,
  }) async {
    try {
      await client
          .from('rounds')
          .update({
            'phase': newPhase,
            'phase_end_time': phaseEndTime.toIso8601String(),
          })
          .eq('id', roundId);

      // Get updated round
      final response = await client
          .from('rounds')
          .select('*')
          .eq('id', roundId)
          .single();

      final character = await getCharacter(
        characterId: response['character_id'] as String,
      );

      final players = await getRoomPlayers(
        roomId: response['room_id'] as String,
      );
      final playerIds = players.map((p) => p.id).toList();

      final hints = await getHintsForRound(roundId: roundId);
      final votes = await getVotesForRound(roundId: roundId);

      return RoundInfoModel.fromJson(
        response,
        character.toEntity(),
        playerIds,
        hints,
        votes,
      );
    } catch (e) {
      throw Exception('Failed to update round phase: $e');
    }
  }

  @override
  Future<void> updatePlayerScores({required Map<String, int> scores}) async {
    try {
      for (final entry in scores.entries) {
        await client
            .from('players')
            .update({'score': entry.value})
            .eq('id', entry.key);
      }
    } catch (e) {
      throw Exception('Failed to update player scores: $e');
    }
  }

  @override
  Future<RoundInfoModel> createRound({
    required String roomId,
    required String imposterPlayerId,
    required String characterId,
    required int roundNumber,
    required int roundDurationSeconds,
  }) async {
    try {
      final phaseEndTime = DateTime.now().toUtc().add(
        Duration(seconds: roundDurationSeconds),
      );

      final response = await client
          .from('rounds')
          .insert({
            'room_id': roomId,
            'imposter_player_id': imposterPlayerId,
            'character_id': characterId,
            'round_number': roundNumber,
            'phase': 'hints',
            'phase_end_time': phaseEndTime.toIso8601String(),
            'imposter_revealed': false,
          })
          .select()
          .single();

      final character = await getCharacter(characterId: characterId);
      final players = await getRoomPlayers(roomId: roomId);
      final playerIds = players.map((p) => p.id).toList();

      return RoundInfoModel.fromJson(
        response,
        character.toEntity(),
        playerIds,
        {},
        {},
      );
    } catch (e) {
      throw Exception('Failed to create round: $e');
    }
  }

  @override
  Future<void> updateRoomStatus({
    required String roomId,
    required String status,
  }) async {
    try {
      await client.from('rooms').update({'status': status}).eq('id', roomId);
    } catch (e) {
      throw Exception('Failed to update room status: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>> watchRoundChanges({required String roundId}) {
    return client
        .from('rounds')
        .stream(primaryKey: ['id'])
        .eq('id', roundId)
        .map((data) => data.first);
  }

  @override
  Stream<Map<String, dynamic>> watchHintsChanges({required String roundId}) {
    return client
        .from('hints')
        .stream(primaryKey: ['id'])
        .eq('round_id', roundId)
        .map((data) => {'hints': data});
  }

  @override
  Stream<Map<String, dynamic>> watchVotesChanges({required String roundId}) {
    return client
        .from('votes')
        .stream(primaryKey: ['id'])
        .eq('round_id', roundId)
        .map((data) => {'votes': data});
  }
}
