import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/category_selector.dart';
import 'widgets/create_room_header.dart';
import 'widgets/game_mode_selector.dart';
import 'widgets/local_players_input.dart';
import 'widgets/max_players_selector.dart';
import 'widgets/room_status_listener.dart';
import 'widgets/round_duration_selector.dart';
import 'widgets/rounds_selector.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'Guest';

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Room')),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    return BlocProvider(
      create: (_) => di.sl<RoomCubit>(),
      child: CreateRoomView(username: username),
    );
  }
}

class CreateRoomView extends StatefulWidget {
  final String username;

  const CreateRoomView({super.key, required this.username});

  @override
  State<CreateRoomView> createState() => _CreateRoomViewState();
}

class _CreateRoomViewState extends State<CreateRoomView> {
  String _selectedCategory = 'mix';
  int _selectedRounds = GameConstants.defaultRounds;
  int _selectedMaxPlayers = 4;
  int _selectedRoundDuration = 300; // 5 minutes
  String _selectedGameMode = GameConstants.gameModeOnline; // Default to online
  List<String> _localPlayerNames = []; // For local mode
  String? _createdRoomId; // Store room ID for listener
  bool _isLoadingCategories = true;

  static const Map<String, String> _fallbackCategories = {
    'mix': 'Mix (All)',
    'places': 'Places',
    'foods': 'Foods',
    'animals': 'Animals',
  };

  Map<String, String> _categories = Map<String, String>.from(
    _fallbackCategories,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('key, name')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final fetched = <String, String>{'mix': 'Mix (All)'};

      for (final row in (response as List)) {
        final key = (row['key'] as String?)?.trim();
        final name = (row['name'] as String?)?.trim();
        if (key != null && key.isNotEmpty && name != null && name.isNotEmpty) {
          fetched[key] = name;
        }
      }

      if (mounted) {
        setState(() {
          _categories = fetched.length > 1 ? fetched : _fallbackCategories;
          if (!_categories.containsKey(_selectedCategory)) {
            _selectedCategory = _categories.keys.first;
          }
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = Map<String, String>.from(_fallbackCategories);
          if (!_categories.containsKey(_selectedCategory)) {
            _selectedCategory = _categories.keys.first;
          }
          _isLoadingCategories = false;
        });
      }
    }
  }

  bool _isCreateDisabled() {
    // For local mode, require at least 2 player names
    if (_selectedGameMode == GameConstants.gameModeLocal) {
      return _localPlayerNames.length < 2;
    }
    return false;
  }

  void _createRoom() {
    // For local mode, pass player names. For online mode, pass null
    context.read<RoomCubit>().createNewRoom(
      category: _selectedCategory,
      maxRounds: _selectedRounds,
      username: widget.username,
      maxPlayers: _selectedMaxPlayers,
      roundDuration: _selectedRoundDuration,
      gameMode: _selectedGameMode,
      localPlayerNames: _selectedGameMode == GameConstants.gameModeLocal
          ? _localPlayerNames
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).surface,
        title: const AppBarTitle(title: 'Create Room'),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomWithPlayerCreated) {
            // Store room ID for listener
            setState(() {
              _createdRoomId = state.room.id;
            });

            // For local mode, start game and navigate directly to countdown
            if (_selectedGameMode == GameConstants.gameModeLocal) {
              // Room created, starting game
              // Start game for local mode
              context.read<RoomCubit>().startGameSession(state.room.id);
              // Navigate directly to countdown (don't wait for realtime)
              context.go(AppRoutes.roomCountdown(state.room.id));
            } else {
              // Room created successfully
              context.go(AppRoutes.roomWaiting(state.room.id));
            }
          } else if (state is RoomError) {
            ErrorSnackBar.show(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is RoomLoading;

          final body = SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.2 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const CreateRoomHeader(),
                    SizedBox(height: isTablet ? 48 : 40),

                    // Game Mode Selector
                    GameModeSelector(
                      selectedMode: _selectedGameMode,
                      onModeChanged: (mode) =>
                          setState(() => _selectedGameMode = mode),
                    ),
                    const SizedBox(height: 24),

                    // Category Selector
                    CategorySelector(
                      selectedCategory: _selectedCategory,
                      categories: _categories,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      enabled: !isLoading && !_isLoadingCategories,
                    ),
                    const SizedBox(height: 24),

                    // Rounds Selector
                    RoundsSelector(
                      selectedRounds: _selectedRounds,
                      onChanged: (value) =>
                          setState(() => _selectedRounds = value),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Max Players Selector
                    MaxPlayersSelector(
                      selectedMaxPlayers: _selectedMaxPlayers,
                      onMaxPlayersChanged: (value) =>
                          setState(() => _selectedMaxPlayers = value),
                    ),
                    const SizedBox(height: 24),

                    // Local Players Input (only shown for local mode)
                    if (_selectedGameMode == GameConstants.gameModeLocal)
                      LocalPlayersInput(
                        maxPlayers: _selectedMaxPlayers,
                        onPlayersChanged: (names) =>
                            setState(() => _localPlayerNames = names),
                      ),
                    if (_selectedGameMode == GameConstants.gameModeLocal)
                      const SizedBox(height: 24),

                    // Round Duration Selector
                    RoundDurationSelector(
                      selectedDuration: _selectedRoundDuration,
                      onDurationChanged: (value) =>
                          setState(() => _selectedRoundDuration = value),
                    ),
                    SizedBox(height: isTablet ? 48 : 40),

                    // Create Button
                    ElevatedButton(
                      onPressed: isLoading || _isCreateDisabled()
                          ? null
                          : _createRoom,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: isTablet ? 28 : 24,
                              width: isTablet ? 28 : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.of(context).textPrimary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: isTablet ? 24 : 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Create Room',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Wrap with RoomStatusListener when room is created (for local mode)
          if (_createdRoomId != null) {
            return RoomStatusListener(
              roomId: _createdRoomId!,
              builder: (context) => body,
            );
          }

          return body;
        },
      ),
    );
  }
}
