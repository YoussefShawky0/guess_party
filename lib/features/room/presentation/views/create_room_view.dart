import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/core/utils/error_handler.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'widgets/category_selector.dart';
import 'widgets/create_room_header.dart';
import 'widgets/game_mode_selector.dart';
import 'widgets/local_players_input.dart';
import 'widgets/max_players_selector.dart';
import 'widgets/round_duration_selector.dart';
import 'widgets/rounds_selector.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = di.sl<AuthSessionService>();
    final username = session.currentUsername;

    if (session.currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.createRoom)),
        body: Center(child: Text(context.l10n.userNotAuthenticated)),
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
  String? _selectedCategory;
  int _selectedRounds = GameConstants.defaultRounds;
  int _selectedMaxPlayers = 4;
  int _selectedRoundDuration = 300;
  String _selectedGameMode = GameConstants.gameModeOnline;
  List<String> _localPlayerNames = [];
  bool _isLoadingCategories = true;
  Map<String, String> _categories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final fetched = await di.sl<RoomQueryService>().getActiveCategories();

      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _categories = fetched;
          _selectedCategory = fetched.keys.first;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = ErrorHandler.getUserFriendlyMessage(
          ErrorHandler.extractErrorMessage(e),
        );
        final isNetworkError = message.contains('Connection lost');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError
                  ? context.l10n.noInternet
                  : context.l10n.categoriesLoadFailed,
            ),
            action: SnackBarAction(
              label: context.l10n.retry,
              onPressed: () {
                setState(() => _isLoadingCategories = true);
                _loadCategories();
              },
            ),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  bool _isCreateDisabled() {
    if (_selectedCategory == null || _isLoadingCategories) return true;

    if (_selectedGameMode == GameConstants.gameModeLocal) {
      // Require exactly maxPlayers valid names
      if (_localPlayerNames.length != _selectedMaxPlayers) return true;
      // All names must be non-empty
      return !_localPlayerNames.every((name) => name.trim().isNotEmpty);
    }
    return false;
  }

  void _createRoom() {
    if (_selectedCategory == null) return;

    context.read<RoomCubit>().createNewRoom(
      category: _selectedCategory!,
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
        title: AppBarTitle(title: context.l10n.createRoom),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomWithPlayerCreated) {
            if (_selectedGameMode == GameConstants.gameModeLocal) {
              context.read<RoomCubit>().startGameSession(state.room.id);
              context.go(AppRoutes.roomCountdown(state.room.id));
            } else {
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
                    const CreateRoomHeader(),
                    SizedBox(height: isTablet ? 48 : 40),

                    GameModeSelector(
                      selectedMode: _selectedGameMode,
                      onModeChanged: (mode) =>
                          setState(() => _selectedGameMode = mode),
                    ),
                    if (_selectedGameMode == GameConstants.gameModeLocal) ...[
                      const SizedBox(height: 12),
                      SharedDeviceConnectivityNotice(isTablet: isTablet),
                    ],
                    const SizedBox(height: 24),

                    if (_isLoadingCategories)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_selectedCategory != null)
                      CategorySelector(
                        selectedCategory: _selectedCategory!,
                        categories: _categories,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        enabled: !isLoading,
                      ),
                    const SizedBox(height: 24),

                    RoundsSelector(
                      selectedRounds: _selectedRounds,
                      onChanged: (value) =>
                          setState(() => _selectedRounds = value),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),

                    MaxPlayersSelector(
                      selectedMaxPlayers: _selectedMaxPlayers,
                      onMaxPlayersChanged: (value) =>
                          setState(() => _selectedMaxPlayers = value),
                    ),
                    const SizedBox(height: 24),

                    if (_selectedGameMode == GameConstants.gameModeLocal)
                      LocalPlayersInput(
                        maxPlayers: _selectedMaxPlayers,
                        onPlayersChanged: (names) =>
                            setState(() => _localPlayerNames = names),
                      ),
                    if (_selectedGameMode == GameConstants.gameModeLocal)
                      const SizedBox(height: 24),

                    RoundDurationSelector(
                      selectedDuration: _selectedRoundDuration,
                      onDurationChanged: (value) =>
                          setState(() => _selectedRoundDuration = value),
                    ),
                    SizedBox(height: isTablet ? 48 : 40),

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
                                  context.l10n.createRoom,
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

          return body;
        },
      ),
    );
  }
}
