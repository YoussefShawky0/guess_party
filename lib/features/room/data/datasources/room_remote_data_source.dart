import 'dart:async';

import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/data/models/room_model.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RoomRemoteDataSource {
  Future<RoomSession> createRoom({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  });

  Future<RoomSession> joinRoom({
    required String roomCode,
    required String username,
  });

  Future<Room> getRoomDetails({required String roomId});

  Stream<Room> watchRoomDetails({required String roomId});

  Stream<List<Player>> watchRoomPlayers({required String roomId});

  Future<List<Player>> getRoomPlayers({required String roomId});

  Future<Room> getRoomByCode({required String roomCode});

  Future<String> startGame(String roomId);

  Future<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  });

  Future<void> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  });

  Future<void> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  });
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final SupabaseClient client;

  RoomRemoteDataSourceImpl({required this.client});
  @override
  Future<RoomSession> createRoom({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  }) async {
    try {
      final response = await client.rpc(
        'create_room',
        params: {
          'p_request_id': requestId,
          'p_category': category,
          'p_max_rounds': maxRounds,
          'p_max_players': maxPlayers,
          'p_round_duration': roundDuration,
          'p_game_mode': gameMode,
          'p_host_username': hostUsername,
          'p_local_names': localNames,
        },
      );
      return _parseCreatedSession(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<RoomSession> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    final response = await client.rpc(
      'join_room',
      params: {'p_room_code': roomCode, 'p_username': username},
    );
    final json = Map<String, dynamic>.from(response as Map);
    final room = RoomModel.fromJson(
      Map<String, dynamic>.from(json['room'] as Map),
    );
    final player = PlayerModel.fromJson(
      Map<String, dynamic>.from(json['player'] as Map),
    );
    return RoomSession(room: room, currentPlayer: player, players: [player]);
  }

  @override
  Future<Room> getRoomDetails({required String roomId}) async {
    try {
      final response = await client
          .from('rooms')
          .select()
          .eq('id', roomId)
          .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Room> watchRoomDetails({required String roomId}) {
    late final StreamController<Room> controller;
    RealtimeChannel? channel;

    Future<void> emitCurrentRoom() async {
      try {
        final room = await getRoomDetails(roomId: roomId);
        if (!controller.isClosed) {
          controller.add(room);
        }
      } catch (e, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(e, stackTrace);
        }
      }
    }

    controller = StreamController<Room>(
      onListen: () {
        unawaited(emitCurrentRoom());

        final realtimeChannel = client.channel('room_details_$roomId');
        realtimeChannel.onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            try {
              controller.add(RoomModel.fromJson(payload.newRecord));
            } catch (_) {
              unawaited(emitCurrentRoom());
            }
          },
        );

        realtimeChannel.subscribe((status, error) {
          if (error != null && !controller.isClosed) {
            controller.addError(error);
          }
        });

        channel = realtimeChannel;
      },
      onCancel: () async {
        final activeChannel = channel;
        channel = null;
        if (activeChannel != null) {
          await activeChannel.unsubscribe();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<List<Player>> getRoomPlayers({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select()
          .eq('room_id', roomId)
          .eq('is_online', true)
          .order('created_at', ascending: true);

      return (response as List)
          .map((player) => PlayerModel.fromJson(player))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) {
    return client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) {
          final players = rows
              .where((row) => row['is_online'] == true)
              .map(PlayerModel.fromJson)
              .toList(growable: false);
          players.sort((a, b) {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            if (aTime == null && bTime == null) return a.id.compareTo(b.id);
            if (aTime == null) return -1;
            if (bTime == null) return 1;
            final compared = aTime.compareTo(bTime);
            return compared == 0 ? a.id.compareTo(b.id) : compared;
          });
          return players;
        });
  }

  @override
  Future<Room> getRoomByCode({required String roomCode}) async {
    try {
      final response = await client.rpc(
        'find_joinable_room',
        params: {'p_room_code': roomCode},
      );
      final json = Map<String, dynamic>.from(response as Map);
      return RoomModel.fromJson(Map<String, dynamic>.from(json['room'] as Map));
    } catch (e) {
      // Catch "no rows found" error and provide specific message for room code validation
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('no rows') ||
          errorText.contains('norowsfoundexception') ||
          errorText.contains('pgrst116')) {
        throw Exception('Room not found. Please check the code and try again.');
      }
      rethrow;
    }
  }

  @override
  Future<String> startGame(String roomId) async {
    try {
      final response = await client.rpc(
        'start_game',
        params: {'p_room_id': roomId},
      );
      return response as String;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
    try {
      await client
          .from('players')
          .update({
            'is_online': isOnline,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', playerId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  }) async {
    try {
      await client.rpc(
        'mark_stale_players_offline',
        params: {'p_room_id': roomId, 'p_stale_seconds': staleSeconds},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    try {
      // Host migration / empty-room cleanup is handled in database triggers.
      // Leaving client only marks its own player as offline.
      final _ = isHost;
      await client
          .from('players')
          .update({
            'is_online': false,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', playerId);
    } catch (e) {
      rethrow;
    }
  }

  RoomSession _parseCreatedSession(Map<String, dynamic> json) {
    final room = RoomModel.fromJson(
      Map<String, dynamic>.from(json['room'] as Map),
    );
    final players = (json['players'] as List)
        .map(
          (value) =>
              PlayerModel.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    final currentPlayer = players.firstWhere((player) => player.isHost);
    return RoomSession(
      room: room,
      currentPlayer: currentPlayer,
      players: players,
    );
  }
}
