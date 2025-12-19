import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/presentation/widgets/app_bar_title.dart';
import 'package:guess_party/shared/presentation/widgets/error_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/category_selector.dart';
import 'widgets/create_room_header.dart';
import 'widgets/max_players_selector.dart';
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
  String _selectedCategory = GameConstants.categories.first;
  int _selectedRounds = GameConstants.defaultRounds;
  int _selectedMaxPlayers = 6;
  int _selectedRoundDuration = 60;

  @override
  void initState() {
    super.initState();
    // Ensure valid category key
    if (!GameConstants.categories.contains(_selectedCategory)) {
      _selectedCategory = GameConstants.categories.first;
    }
  }

  void _createRoom() {
    context.read<RoomCubit>().createNewRoom(
      category: _selectedCategory,
      maxRounds: _selectedRounds,
      username: widget.username,
      maxPlayers: _selectedMaxPlayers,
      roundDuration: _selectedRoundDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Create Room'),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomWithPlayerCreated) {
            ErrorSnackBar.showSuccess(context, 'Room created successfully!');
            context.go('/room/${state.room.id}/waiting');
          } else if (state is RoomError) {
            ErrorSnackBar.show(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is RoomLoading;

          return SafeArea(
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

                    // Category Selector
                    CategorySelector(
                      selectedCategory: _selectedCategory,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      enabled: !isLoading,
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

                    // Round Duration Selector
                    RoundDurationSelector(
                      selectedDuration: _selectedRoundDuration,
                      onDurationChanged: (value) =>
                          setState(() => _selectedRoundDuration = value),
                    ),
                    SizedBox(height: isTablet ? 48 : 40),

                    // Create Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _createRoom,
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
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: isTablet ? 28 : 24,
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
        },
      ),
    );
  }
}
