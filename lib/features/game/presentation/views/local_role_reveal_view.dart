import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';

/// Screen for Local Mode where each player sees their role one by one
/// before the game starts. This ensures privacy on a shared device.
class LocalRoleRevealScreen extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const LocalRoleRevealScreen({
    super.key,
    required this.roomId,
    this.preservedScores,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LocalRoleRevealCubit>()..load(roomId),
      child: LocalRoleRevealContent(
        roomId: roomId,
        preservedScores: preservedScores,
      ),
    );
  }
}

class LocalRoleRevealContent extends StatefulWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const LocalRoleRevealContent({
    super.key,
    required this.roomId,
    this.preservedScores,
  });

  @override
  State<LocalRoleRevealContent> createState() => _LocalRoleRevealContentState();
}

class _LocalRoleRevealContentState extends State<LocalRoleRevealContent> {
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;
  List<Player> _players = [];
  String? _roundId;
  String? _imposterPlayerId;
  Character? _character;
  bool _isLoading = true;
  DateTime? _roleRevealStartTime;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.of(context).surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Exit Role Reveal?',
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
            content: Text(
              'Are you sure you want to exit? The game will be cancelled.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          context.read<LocalRoleRevealCubit>().clearSecrets();
          _clearSecretFields();
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: BlocConsumer<LocalRoleRevealCubit, LocalRoleRevealState>(
          listener: (context, state) {
            if (state is LocalRoleRevealLoaded) {
              setState(() {
                _players = state.data.players;
                _roundId = state.data.roundId;
                _imposterPlayerId = state.data.imposterPlayerId;
                _character = state.data.character;
                _isLoading = false;
                _roleRevealStartTime ??= DateTime.now();
              });
            } else if (state is LocalRoleRevealFailure) {
              setState(() {
                _isLoading = false;
                _clearSecretFields();
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is LocalRoleRevealFailure) {
              return ErrorScreen(
                message: state.message,
                onGoBack: () =>
                    context.read<LocalRoleRevealCubit>().load(widget.roomId),
              );
            }
            if (_isLoading ||
                _players.isEmpty ||
                _roundId == null ||
                _character == null ||
                _imposterPlayerId == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      'Loading game...',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: isTablet ? 20 : 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Validate player list
            if (_players.isEmpty ||
                _roundId == null ||
                _character == null ||
                _imposterPlayerId == null) {
              return ErrorScreen(
                message: 'Unable to load player information',
                onGoBack: () => Navigator.of(context).pop(),
              );
            }

            final currentPlayer = _players[_currentPlayerIndex];
            final isImposter = _imposterPlayerId == currentPlayer.id;

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
      ),
    );
  }

  Widget _buildProgressIndicator(bool isTablet) {
    return Column(
      children: [
        Text(
          'Player ${_currentPlayerIndex + 1} of ${_players.length}',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: isTablet ? 18 : 14,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_currentPlayerIndex + 1) / _players.length,
          backgroundColor: AppColors.of(context).surface,
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
        color: AppColors.of(context).surface,
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
              color: AppColors.of(context).textSecondary,
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
    final accent = isImposter ? AppColors.error : AppColors.success;
    final roleIcon = isImposter
        ? FontAwesomeIcons.userSecret
        : FontAwesomeIcons.userCheck;

    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 32),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name
          Text(
            player.username,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Role icon in circle
          Container(
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(roleIcon, color: accent, size: isTablet ? 56 : 48),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // "You are the" text
          Text(
            'You are the',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          const SizedBox(height: 8),

          // Role name
          Text(
            isImposter ? 'IMPOSTER!' : 'INNOCENT!',
            style: TextStyle(
              color: accent,
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Bottom hint box
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isImposter) ...[
                  Text(
                    _character!.emoji,
                    style: TextStyle(fontSize: isTablet ? 24 : 20),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _character!.name,
                      style: TextStyle(
                        color: accent,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    color: accent,
                    size: isTablet ? 20 : 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Blend in! Don\'t get caught!',
                      style: TextStyle(
                        color: accent,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
              color: AppColors.of(context).textPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              _isRoleRevealed
                  ? (isLastPlayer ? 'Start Game!' : 'Next Player')
                  : 'Reveal My Role',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
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
        // Calculate elapsed time and adjust timer
        if (_roleRevealStartTime != null && _roundId != null) {
          final elapsedSeconds = DateTime.now()
              .difference(_roleRevealStartTime!)
              .inSeconds;

          final extended = await context
              .read<LocalRoleRevealCubit>()
              .extendReveal(roundId: _roundId!, seconds: elapsedSeconds);
          if (!extended) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not start safely. Please try again.'),
              ),
            );
            return;
          }
        }

        if (!mounted) return;
        context.read<LocalRoleRevealCubit>().clearSecrets();
        setState(_clearSecretFields);

        context.go(
          AppRoutes.roomLocalGame(widget.roomId),
          extra:
              widget.preservedScores != null &&
                  widget.preservedScores!.isNotEmpty
              ? {'playerScores': widget.preservedScores!}
              : null,
        );
      }
    }
  }

  void _clearSecretFields() {
    _roundId = null;
    _imposterPlayerId = null;
    _character = null;
  }

  @override
  void dispose() {
    _clearSecretFields();
    super.dispose();
  }
}
