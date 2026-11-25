import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/rematch_invite_cubit.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:guess_party/features/stats/presentation/views/widgets/new_badges_card.dart';
import 'package:guess_party/shared/design/animated_game_background.dart';
import 'package:guess_party/shared/design/game_button.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'widgets/leaderboard_list_widget.dart';
import 'widgets/rematch_invite_card.dart';
import 'widgets/podium_widget.dart';
import 'package:guess_party/l10n/l10n.dart';

class GameOverView extends StatefulWidget {
  final List<Player> players;
  final Map<String, int> playerScores;
  final InterstitialAdService adService;

  /// The finished room. Without it (and [currentUserId] and
  /// [roomRepository]) there is no Play Again and no rematch invite.
  final String? roomId;
  final String gameMode;
  final String? currentUserId;
  final RoomRepository? roomRepository;

  /// Builds the invite cubit for invited (non-host) Online players. The view
  /// starts and closes it.
  final RematchInviteCubit Function()? createRematchInviteCubit;

  /// Builds the stats cubit used to announce new badges (Online Mode only).
  /// The view loads and closes it; failures stay silent.
  final PlayerStatsCubit Function()? createPlayerStatsCubit;

  const GameOverView({
    super.key,
    required this.players,
    required this.playerScores,
    this.adService = const DisabledInterstitialAdService(),
    this.roomId,
    this.gameMode = GameConstants.gameModeOnline,
    this.currentUserId,
    this.roomRepository,
    this.createRematchInviteCubit,
    this.createPlayerStatsCubit,
  });

  @override
  State<GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<GameOverView> {
  /// Single-flight guard shared by Back to Home, Play Again and Join.
  bool _leaving = false;
  bool _preparingRematch = false;
  RematchInviteCubit? _inviteCubit;
  PlayerStatsCubit? _statsCubit;

  List<Player> get players => widget.players;
  Map<String, int> get playerScores => widget.playerScores;

  @override
  void initState() {
    super.initState();
    widget.adService.preload();
    if (_canInvite) {
      _inviteCubit = widget.createRematchInviteCubit!()..start();
    }
    final createStats = widget.createPlayerStatsCubit;
    if (createStats != null &&
        widget.gameMode == GameConstants.gameModeOnline) {
      // Fire and forget: the buttons never wait for the stats.
      _statsCubit = createStats()..load();
    }
  }

  @override
  void dispose() {
    _inviteCubit?.close();
    _statsCubit?.close();
    super.dispose();
  }

  Player? get _hostPlayer {
    for (final p in players) {
      if (p.isHost) return p;
    }
    return null;
  }

  /// The signed-in user is the host of the finished room.
  bool get _isHost {
    final userId = widget.currentUserId;
    if (userId == null) return false;
    for (final p in players) {
      if (p.userId == userId && p.isHost) return true;
    }
    return false;
  }

  bool get _canPlayAgain =>
      widget.roomId != null && widget.roomRepository != null && _isHost;

  bool get _canInvite =>
      widget.roomId != null &&
      widget.currentUserId != null &&
      widget.createRematchInviteCubit != null &&
      widget.gameMode == GameConstants.gameModeOnline &&
      !_isHost;

  Future<void> _playAgain() async {
    if (_leaving || !_canPlayAgain) return;
    _leaving = true;
    setState(() => _preparingRematch = true);

    final repository = widget.roomRepository!;
    final roomResult = await repository.getRoomDetails(roomId: widget.roomId!);
    if (!mounted) return;

    final room = roomResult.fold((_) => null, (r) => r);
    if (room == null) {
      final code = roomResult.fold((f) => f.code, (_) => AppErrorCode.unknown);
      _leaving = false;
      setState(() => _preparingRematch = false);
      ErrorSnackBar.show(context, localizedErrorMessage(context.l10n, code));
      return;
    }

    var seedPlayers = players;
    if (room.gameMode == GameConstants.gameModeLocal) {
      // Fresh rows carry createdAt, which keeps the host first.
      final playersResult = await repository.getRoomPlayers(
        roomId: widget.roomId!,
      );
      if (!mounted) return;
      seedPlayers = playersResult.getOrElse(() => players);
    }

    final seed = RematchSeed.fromFinishedRoom(room, seedPlayers);
    await widget.adService.showAfterGameIfReady();
    if (!mounted) return;
    context.go(AppRoutes.createRoom, extra: seed);
  }

  Future<void> _goToRematchRoom(String newRoomId) async {
    if (_leaving) return;
    _leaving = true;
    await widget.adService.showAfterGameIfReady();
    if (!mounted) return;
    context.go(AppRoutes.roomWaiting(newRoomId));
  }

  void _onInviteState(BuildContext context, RematchInviteState state) {
    if (state is RematchJoined) {
      _goToRematchRoom(state.roomId);
    } else if (state is RematchFailed) {
      ErrorSnackBar.show(
        context,
        localizedErrorMessage(context.l10n, state.code),
      );
    }
  }

  Widget _buildInviteCard() {
    return BlocBuilder<RematchInviteCubit, RematchInviteState>(
      bloc: _inviteCubit,
      builder: (context, state) {
        if (state is! RematchInvited && state is! RematchJoining) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 16),
          child: RematchInviteCard(
            hostName: _hostPlayer?.username ?? '',
            isJoining: state is RematchJoining,
            onJoin: () => _inviteCubit?.accept(),
            onDecline: () => _inviteCubit?.decline(),
          ),
        );
      },
    );
  }

  Widget _buildNewBadgesCard() {
    return BlocBuilder<PlayerStatsCubit, PlayerStatsState>(
      bloc: _statsCubit,
      builder: (context, state) {
        if (state is! StatsLoaded || state.newBadges.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 16),
          child: NewBadgesCard(badges: state.newBadges),
        );
      },
    );
  }

  /// The game is over, so the ad can't interrupt play in either mode.
  Future<void> _goHome() async {
    if (_leaving) return;
    _leaving = true;
    await widget.adService.showAfterGameIfReady();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  List<Player> get _sortedPlayers {
    final sorted = List<Player>.from(players);
    sorted.sort(
      (a, b) => (playerScores[b.id] ?? 0).compareTo(playerScores[a.id] ?? 0),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPlayers;
    final top3 = sorted.take(3).toList();
    final rest = sorted.length > 3 ? sorted.sublist(3) : <Player>[];

    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _goHome(),
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        // The game is over, so the background is allowed here (never during
        // rounds).
        body: AnimatedGameBackground(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ─── Header ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      children: [
                        Text('🏆', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.gameOver,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.of(context).textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.finalLeaderboard,
                          style: TextStyle(
                            color: AppColors.of(context).textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Podium (top 3) ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: PodiumWidget(
                      topPlayers: top3,
                      playerScores: playerScores,
                    ),
                  ),
                ),

                // ─── Rest of the players list ─────────────────────────────
                if (rest.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: LeaderboardListWidget(
                        players: rest,
                        playerScores: playerScores,
                        startRank: 4,
                      ),
                    ),
                  ),

                // ─── Back to Home button ──────────────────────────────────
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_statsCubit != null) _buildNewBadgesCard(),
                          if (_inviteCubit != null) _buildInviteCard(),
                          if (_canPlayAgain) ...[
                            GameButton(
                              key: const Key('game-over-play-again'),
                              label: context.l10n.playAgain,
                              // The spinner replaces the icon (not the
                              // label), as before the redesign.
                              icon: _preparingRematch
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.replay_rounded),
                              onPressed: _leaving ? null : _playAgain,
                            ),
                            const SizedBox(height: 12),
                          ],
                          // One primary per screen: Home is secondary when the
                          // host has Play Again.
                          GameButton(
                            key: const Key('game-over-home'),
                            label: context.l10n.backToHome,
                            icon: const Icon(Icons.home_rounded),
                            variant: _canPlayAgain
                                ? GameButtonVariant.secondary
                                : GameButtonVariant.primary,
                            onPressed: _goHome,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final cubit = _inviteCubit;
    if (cubit == null) return content;
    return BlocListener<RematchInviteCubit, RematchInviteState>(
      bloc: cubit,
      listener: _onInviteState,
      child: content,
    );
  }
}
