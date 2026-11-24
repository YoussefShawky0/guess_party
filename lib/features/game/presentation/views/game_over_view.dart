import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'widgets/leaderboard_list_widget.dart';
import 'widgets/podium_widget.dart';
import 'package:guess_party/l10n/l10n.dart';

class GameOverView extends StatefulWidget {
  final List<Player> players;
  final Map<String, int> playerScores;
  final InterstitialAdService adService;

  const GameOverView({
    super.key,
    required this.players,
    required this.playerScores,
    this.adService = const DisabledInterstitialAdService(),
  });

  @override
  State<GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<GameOverView> {
  bool _leaving = false;

  List<Player> get players => widget.players;
  Map<String, int> get playerScores => widget.playerScores;

  @override
  void initState() {
    super.initState();
    widget.adService.preload();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _goHome(),
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: SafeArea(
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
                              fontWeight: FontWeight.bold,
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _goHome,
                        icon: const Icon(Icons.home_rounded),
                        label: Text(
                          context.l10n.backToHome,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonPrimary,
                          foregroundColor: AppColors.of(context).textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
