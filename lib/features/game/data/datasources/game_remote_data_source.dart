import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/game/data/models/character_model.dart';
import 'package:guess_party/features/game/data/models/finalize_voting_result_model.dart';
import 'package:guess_party/features/game/data/models/local_role_reveal_bundle_model.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/game/data/models/vote_state_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GameRemoteDataSource {
  Future<RoundInfoModel> getCurrentRound({required String roomId});

  Future<RoundInfoModel> getRoundSnapshot({required String roundId});

  Future<Map<String, dynamic>> getRoundForPlayerV2({required String roundId});

  Future<LocalRoleRevealBundleModel> getLocalRoleRevealBundle({
    required String roundId,
  });

  Future<VoteStateModel> getVoteState({required String roundId});

  Future<List<PlayerModel>> getRoomPlayers({required String roomId});

  Future<CharacterModel> getCharacter({required String characterId});

  Future<Map<String, String>> getHintsForRound({required String roundId});

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

  Future<void> advanceToVoting({required String roundId});

  Future<FinalizeVotingResultModel> finalizeVoting({
    required String roundId,
    required String reason,
  });

  Future<String> createNextRoundCommand({
    required String roomId,
    required int expectedRoundNumber,
  });

  Future<void> finishGameCommand({required String roomId});

  Future<void> extendLocalRoleReveal({
    required String roundId,
    required int seconds,
  });

  Stream<Map<String, dynamic>> watchRoundRevision({required String roundId});

  Stream<List<PlayerModel>> watchPlayersChanges({required String roomId});

  Stream<String> watchRoomStatus({required String roomId});

  Future<void> updateCurrentPlayerPresence({
    required String roomId,
    required String userId,
    required bool isOnline,
  });
}

class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final SupabaseClient client;

  GameRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getRoundForPlayerV2({
    required String roundId,
  }) async {
    try {
      final response = await client
          .rpc('get_round_for_player_v2', params: {'p_round_id': roundId})
          .select()
          .maybeSingle();

      if (response == null) {
        throw StateError('ROUND_PARTICIPANT_REQUIRED');
      }
      return Map<String, dynamic>.from(response);
    } catch (error) {
      throw Exception('Failed to load the secure round snapshot: $error');
    }
  }

  @override
  Future<LocalRoleRevealBundleModel> getLocalRoleRevealBundle({
    required String roundId,
  }) async {
    try {
      final response = await client
          .rpc('get_local_role_reveal_bundle', params: {'p_round_id': roundId})
          .select()
          .maybeSingle();

      if (response == null) {
        throw StateError('LOCAL_HOST_REVEAL_REQUIRED');
      }
      return LocalRoleRevealBundleModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to load the Local role reveal: $error');
    }
  }

  @override
  Future<VoteStateModel> getVoteState({required String roundId}) async {
    try {
      final response = await client.rpc(
        'get_vote_state',
        params: {'p_round_id': roundId},
      );
      return VoteStateModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw Exception('Failed to load vote progress: $error');
    }
  }

  @override
  Future<RoundInfoModel> getCurrentRound({required String roomId}) async {
    try {
      final roundId = await client.rpc(
        'get_current_round_id',
        params: {'p_room_id': roomId},
      );
      if (roundId == null) {
        throw StateError('ROUND_NOT_FOUND');
      }
      return getRoundSnapshot(roundId: roundId as String);
    } catch (error) {
      throw Exception('Failed to get the current round: $error');
    }
  }

  @override
  Future<RoundInfoModel> getRoundSnapshot({required String roundId}) async {
    final maskedRound = await getRoundForPlayerV2(roundId: roundId);
    final characterId = maskedRound['character_id'] as String?;
    final character = characterId == null
        ? null
        : await getCharacter(characterId: characterId);
    final participantIds =
        ((maskedRound['participant_ids'] as List?) ?? const [])
            .map((id) => id as String)
            .toList(growable: false);

    final results = await Future.wait<Object>([
      getHintsForRound(roundId: roundId),
      getVoteState(roundId: roundId),
    ]);
    final hints = results[0] as Map<String, String>;
    final voteState = results[1] as VoteStateModel;

    return RoundInfoModel.fromJson(
      maskedRound,
      character?.toEntity(),
      participantIds,
      hints,
      voteState.votes,
      submittedVoteCount: voteState.submittedCount,
      requiredVoteCount: voteState.requiredCount,
    );
  }

  @override
  Future<List<PlayerModel>> getRoomPlayers({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw Exception('Failed to get room players: $error');
    }
  }

  @override
  Future<CharacterModel> getCharacter({required String characterId}) async {
    try {
      final response = await client
          .from('characters')
          .select()
          .eq('id', characterId)
          .single();
      return CharacterModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get character: $error');
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
      return <String, String>{
        for (final hint in response)
          hint['player_id'] as String: hint['content'] as String,
      };
    } catch (error) {
      throw Exception('Failed to get hints: $error');
    }
  }

  @override
  Future<Map<String, int>> getPlayerScores({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select('id, score')
          .eq('room_id', roomId);
      return <String, int>{
        for (final player in response)
          player['id'] as String: player['score'] as int? ?? 0,
      };
    } catch (error) {
      throw Exception('Failed to get player scores: $error');
    }
  }

  @override
  Future<void> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    try {
      await client.from('hints').upsert({
        'round_id': roundId,
        'player_id': playerId,
        'content': hint,
      }, onConflict: 'round_id,player_id');
    } catch (error) {
      throw Exception('Failed to submit hint: $error');
    }
  }

  @override
  Future<void> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    try {
      await client.from('votes').upsert({
        'round_id': roundId,
        'voter_player_id': voterId,
        'voted_player_id': votedPlayerId,
      }, onConflict: 'round_id,voter_player_id');
    } catch (error) {
      throw Exception('Failed to submit vote: $error');
    }
  }

  @override
  Future<void> advanceToVoting({required String roundId}) async {
    await client.rpc('advance_to_voting', params: {'p_round_id': roundId});
  }

  @override
  Future<FinalizeVotingResultModel> finalizeVoting({
    required String roundId,
    required String reason,
  }) async {
    final response = await client.rpc(
      'finalize_voting',
      params: {'p_round_id': roundId, 'p_reason': reason},
    );
    return FinalizeVotingResultModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<String> createNextRoundCommand({
    required String roomId,
    required int expectedRoundNumber,
  }) async {
    final response = await client.rpc(
      'create_next_round',
      params: {
        'p_room_id': roomId,
        'p_expected_round_number': expectedRoundNumber,
      },
    );
    return response as String;
  }

  @override
  Future<void> finishGameCommand({required String roomId}) async {
    await client.rpc('finish_game', params: {'p_room_id': roomId});
  }

  @override
  Future<void> extendLocalRoleReveal({
    required String roundId,
    required int seconds,
  }) async {
    await client.rpc(
      'extend_local_role_reveal',
      params: {'p_round_id': roundId, 'p_seconds': seconds},
    );
  }

  @override
  Stream<Map<String, dynamic>> watchRoundRevision({required String roundId}) {
    return client
        .from('round_revisions')
        .stream(primaryKey: ['round_id'])
        .eq('round_id', roundId)
        .map((rows) {
          if (rows.isEmpty) {
            throw StateError('ROUND_REVISION_NOT_VISIBLE');
          }
          return rows.single;
        });
  }

  @override
  Stream<List<PlayerModel>> watchPlayersChanges({required String roomId}) {
    return client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((data) {
          final rows = data.cast<Map<String, dynamic>>().toList();
          rows.sort((a, b) {
            final aCreatedAt = DateTime.tryParse(
              a['created_at']?.toString() ?? '',
            );
            final bCreatedAt = DateTime.tryParse(
              b['created_at']?.toString() ?? '',
            );
            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return -1;
            if (bCreatedAt == null) return 1;
            return aCreatedAt.compareTo(bCreatedAt);
          });
          return rows.map(PlayerModel.fromJson).toList(growable: false);
        });
  }

  @override
  Stream<String> watchRoomStatus({required String roomId}) {
    return client.from('rooms').stream(primaryKey: ['id']).eq('id', roomId).map(
      (rows) {
        if (rows.isEmpty) throw StateError('ROOM_NOT_VISIBLE');
        return rows.single['status'] as String;
      },
    );
  }

  @override
  Future<void> updateCurrentPlayerPresence({
    required String roomId,
    required String userId,
    required bool isOnline,
  }) async {
    await client
        .from('players')
        .update({
          'is_online': isOnline,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }
}
