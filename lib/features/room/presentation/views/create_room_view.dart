import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/services/room_query_service.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';

import 'widgets/category_selector.dart';
import 'widgets/create_room_header.dart';
import 'widgets/game_mode_selector.dart';
import 'widgets/local_players_input.dart';
import 'widgets/player_count_selector.dart';
import 'widgets/round_duration_selector.dart';
import 'widgets/rounds_selector.dart';

class CreateRoomView extends StatefulWidget {
  final String username;
  final RoomQueryService roomQueryService;

  /// Settings of the finished room when opened from "Play Again".
  final RematchSeed? rematch;

  const CreateRoomView({
    super.key,
    required this.username,
    required this.roomQueryService,
    this.rematch,
  });

  @override
  State<CreateRoomView> createState() => _CreateRoomViewState();
}

class _CreateRoomViewState extends State<CreateRoomView> {
  String? _selectedCategory;
  int _selectedRounds = GameConstants.defaultRounds;
  int _selectedMaxPlayers = 4;
  bool _isPlayerCountValid = true;
  int _selectedRoundDuration = 300;
  String _selectedGameMode = GameConstants.gameModeOnline;
  List<String> _localPlayerNames = [];
  bool _isLoadingCategories = true;
  Map<String, String> _categories = {};

  @override
  void initState() {
    super.initState();
    final seed = widget.rematch;
    if (seed != null) {
      _selectedRounds = seed.maxRounds;
      _selectedMaxPlayers = seed.maxPlayers;
      _selectedRoundDuration = seed.roundDuration;
      _selectedGameMode = seed.gameMode;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final fetched = await widget.roomQueryService.getActiveCategories();

      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _categories = fetched;
          final seedCategory = widget.rematch?.category;
          _selectedCategory =
              seedCategory != null && fetched.containsKey(seedCategory)
              ? seedCategory
              : fetched.keys.first;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isNetworkError = appErrorCodeFrom(e) == AppErrorCode.network;
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
    if (!_isPlayerCountValid) return true;

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

    final seed = widget.rematch;
    if (seed != null) {
      context.read<RoomCubit>().createRematch(
        seed: seed,
        category: _selectedCategory!,
        maxRounds: _selectedRounds,
        maxPlayers: _selectedMaxPlayers,
        roundDuration: _selectedRoundDuration,
        username: widget.username,
        localPlayerNames: seed.gameMode == GameConstants.gameModeLocal
            ? _localPlayerNames
            : null,
      );
      return;
    }

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
        title: AppBarTitle(
          title: widget.rematch != null
              ? context.l10n.playAgain
              : context.l10n.createRoom,
        ),
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
            ErrorSnackBar.show(
              context,
              localizedErrorMessage(context.l10n, state.code),
            );
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
                      enabled: widget.rematch == null,
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

                    PlayerCountSelector(
                      initialValue: _selectedMaxPlayers,
                      onChanged: (value) {
                        setState(() {
                          _isPlayerCountValid = value != null;
                          if (value != null) _selectedMaxPlayers = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_selectedGameMode == GameConstants.gameModeLocal)
                      LocalPlayersInput(
                        maxPlayers: _selectedMaxPlayers,
                        initialNames: widget.rematch?.localNames ?? const [],
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

                    GameButton(
                      onPressed: isLoading || _isCreateDisabled()
                          ? null
                          : _createRoom,
                      isLoading: isLoading,
                      icon: const FaIcon(FontAwesomeIcons.plus),
                      label: context.l10n.createRoom,
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
