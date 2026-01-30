import 'dart:math';

import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/data/models/room_model.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class RoomRemoteDataSource {
  Future<Room> createRoom({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  });

  Future<Player> addPlayerToRoom({
    required String roomId,
    required String username,
    required bool isHost,
    bool isLocalPlayer = false,
  });

  Future<Room> getRoomDetails({required String roomId});

  Future<List<Player>> getRoomPlayers({required String roomId});

  Future<Room> getRoomByCode({required String roomCode});

  Future<void> startGame(String roomId);

  Future<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
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
  Future<Room> createRoom({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  }) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final roomCode = _generateRoomCode();
      const uuid = Uuid();
      final roomId = uuid.v4();

      final response = await client
          .from('rooms')
          .insert({
            'id': roomId,
            'host_id': user.id,
            'category': category,
            'max_rounds': maxRounds,
            'current_round': 0,
            'room_code': roomCode,
            'status': 'waiting',
            'used_character_ids': [],
            'max_players': maxPlayers,
            'round_duration': roundDuration,
            'game_mode': gameMode,
          })
          .select()
          .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Player> addPlayerToRoom({
    required String roomId,
    required String username,
    required bool isHost,
    bool isLocalPlayer = false,
  }) async {
    try {
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // For local mode players (except host), generate a unique UUID
      // This allows multiple players on the same device
      final playerId = isLocalPlayer && !isHost 
          ? const Uuid().v4() 
          : user.id;

      final response = await client
          .from('players')
          .insert({
            'room_id': roomId,
            'user_id': playerId,
            'username': username,
            'score': 0,
            'is_host': isHost,
            'is_online': true,
          })
          .select()
          .single();

      return PlayerModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
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
  Future<List<Player>> getRoomPlayers({required String roomId}) async {
    try {
      final response = await client
          .from('players')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((player) => PlayerModel.fromJson(player))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Room> getRoomByCode({required String roomCode}) async {
    try {
      final response = await client
          .from('rooms')
          .select()
          .eq('room_code', roomCode)
          .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> startGame(String roomId) async {
    try {
      // Update room status to active
      await client
          .from('rooms')
          .update({'status': 'active'})
          .eq('id', roomId)
          .select();

      // TODO: Create first round automatically
      // Currently, the first round needs to be created manually via GameRepository.createNextRound()
      // Options to fix this:
      // 1. Create a Supabase Edge Function that triggers on room status change
      // 2. Call GameRepository.createNextRound() from the host's device after countdown
      // 3. Add a database trigger to auto-create first round
      // For now, the game will show an error until the first round is created
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
          .update({'is_online': isOnline})
          .eq('id', playerId);
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
      if (isHost) {
        // If host leaves, close the room
        await client
            .from('rooms')
            .update({'status': 'finished'})
            .eq('id', roomId);
      }

      // Remove player from room
      await client.from('players').delete().eq('id', playerId);
    } catch (e) {
      rethrow;
    }
  }

  String _generateRoomCode() {
    final random = Random();
    // Generate 6-digit code (100000 - 999999)
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }
}
