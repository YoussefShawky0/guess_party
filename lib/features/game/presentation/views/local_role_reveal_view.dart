import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

/// Screen for Local Mode where each player sees their role one by one
/// before the game starts. This ensures privacy on a shared device.
class LocalRoleRevealScreen extends StatelessWidget {
  final String roomId;

  const LocalRoleRevealScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GameCubit>()
        ..loadGameState(
          roomId: roomId,
          currentPlayerId: '', // Will be set per player
        ),
      child: LocalRoleRevealContent(roomId: roomId),
    );
  }
}

class LocalRoleRevealContent extends StatefulWidget {
  final String roomId;

  const LocalRoleRevealContent({super.key, required this.roomId});

  @override
  State<LocalRoleRevealContent> createState() => _LocalRoleRevealContentState();
}

class _LocalRoleRevealContentState extends State<LocalRoleRevealContent> {
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;
  List<Player> _players = [];
  RoundInfo? _roundInfo;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<GameCubit, GameState>(
        listener: (context, state) {
          if (state is GameLoaded) {
            setState(() {
              _players = state.gameState.players;
              _roundInfo = state.gameState.currentRound;
              _isLoading = false;
            });
          } else if (state is GameError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (_isLoading || _players.isEmpty || _roundInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Loading game...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 20 : 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final currentPlayer = _players[_currentPlayerIndex];
          final isImposter = _roundInfo!.imposterPlayerId == currentPlayer.id;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 48 : 24),
              child: Column(
                children: [
                  // Progress indicator
                  _buildProgressIndicator(isTablet),
                  const Spacer(),

                  // Main content
                  if (!_isRoleRevealed)
                    _buildPlayerNameCard(currentPlayer, isTablet)
                  else
                    _buildRoleRevealCard(currentPlayer, isImposter, isTablet),

                  const Spacer(),

                  // Action button
                  _buildActionButton(isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(bool isTablet) {
    return Column(
      children: [
        Text(
          'Player ${_currentPlayerIndex + 1} of ${_players.length}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 18 : 14,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_currentPlayerIndex + 1) / _players.length,
          backgroundColor: AppColors.surface,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: isTablet ? 8 : 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPlayerNameCard(Player player, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.handPointRight,
            color: AppColors.primary,
            size: isTablet ? 64 : 48,
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            'Pass the phone to',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 22 : 18,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            player.username,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.eyeSlash,
                  color: AppColors.warning,
                  size: isTablet ? 20 : 16,
                ),
                const SizedBox(width: 12),
                Text(
                  'Make sure others can\'t see!',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRevealCard(Player player, bool isImposter, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        color: isImposter
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isImposter ? AppColors.error : AppColors.success,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name
          Text(
            player.username,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Role icon
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: (isImposter ? AppColors.error : AppColors.success)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              isImposter ? FontAwesomeIcons.userSecret : FontAwesomeIcons.user,
              color: isImposter ? AppColors.error : AppColors.success,
              size: isTablet ? 64 : 48,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Role text
          Text(
            isImposter ? 'You are the' : 'You are',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isImposter ? 'IMPOSTER!' : 'INNOCENT',
            style: TextStyle(
              color: isImposter ? AppColors.error : AppColors.success,
              fontSize: isTablet ? 36 : 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),

          // Character info (only for innocents)
          if (!isImposter) ...[
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'The Character is',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roundInfo!.character.emoji,
                        style: TextStyle(fontSize: isTablet ? 36 : 28),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _roundInfo!.character.name,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: isTablet ? 28 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleQuestion,
                    color: AppColors.error,
                    size: isTablet ? 24 : 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Blend in! Don\'t get caught!',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: isTablet ? 18 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isTablet) {
    final isLastPlayer = _currentPlayerIndex == _players.length - 1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRoleRevealed
              ? (isLastPlayer ? AppColors.success : AppColors.primary)
              : AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _isRoleRevealed
                  ? (isLastPlayer
                        ? FontAwesomeIcons.play
                        : FontAwesomeIcons.arrowRight)
                  : FontAwesomeIcons.eye,
              size: isTablet ? 24 : 20,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              _isRoleRevealed
                  ? (isLastPlayer ? 'Start Game!' : 'Next Player')
                  : 'Reveal My Role',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction() {
    if (!_isRoleRevealed) {
      // Reveal the role
      setState(() {
        _isRoleRevealed = true;
      });
    } else {
      // Move to next player or start game
      if (_currentPlayerIndex < _players.length - 1) {
        setState(() {
          _currentPlayerIndex++;
          _isRoleRevealed = false;
        });
      } else {
        // All players have seen their roles, start the game
        context.go('/room/${widget.roomId}/game');
      }
    }
  }
}
