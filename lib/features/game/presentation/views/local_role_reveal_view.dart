import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/exit_role_reveal_dialog.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/pass_phone_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/role_reveal_action_button.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/role_reveal_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/role_reveal_loading.dart';
import 'package:guess_party/features/game/presentation/views/widgets/local_role_reveal/role_reveal_progress.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Shared-Device screen where each player sees their role one by one.
/// before the game starts. This ensures privacy on a shared device.
class LocalRoleRevealScreen extends StatefulWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const LocalRoleRevealScreen({
    super.key,
    required this.roomId,
    this.preservedScores,
  });

  @override
  State<LocalRoleRevealScreen> createState() => _LocalRoleRevealScreenState();
}

class _LocalRoleRevealScreenState extends State<LocalRoleRevealScreen> {
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
    final isTablet = MediaQuery.of(context).size.width > 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showExitRoleRevealDialog(context);

        if (shouldExit == true && context.mounted) {
          context.read<LocalRoleRevealCubit>().clearSecrets();
          _clearSecretFields();
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: BlocConsumer<LocalRoleRevealCubit, LocalRoleRevealState>(
          listener: _onStateChanged,
          builder: (context, state) => _buildForState(context, state, isTablet),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, LocalRoleRevealState state) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizedErrorMessage(context.l10n, state.code)),
        ),
      );
    }
  }

  bool get _hasRevealData =>
      !_isLoading &&
      _players.isNotEmpty &&
      _roundId != null &&
      _character != null &&
      _imposterPlayerId != null;

  Widget _buildForState(
    BuildContext context,
    LocalRoleRevealState state,
    bool isTablet,
  ) {
    if (state is LocalRoleRevealFailure) {
      return ErrorScreen(
        message: localizedErrorMessage(context.l10n, state.code),
        // A dropped connection is usually brief: Retry reloads the same
        // round; Go Back really leaves instead of silently retrying.
        onRetry: () => context.read<LocalRoleRevealCubit>().load(widget.roomId),
        onGoBack: () => context.go(AppRoutes.home),
      );
    }
    if (!_hasRevealData) {
      return RoleRevealLoading(isTablet: isTablet);
    }

    final currentPlayer = _players[_currentPlayerIndex];
    final isImposter = _imposterPlayerId == currentPlayer.id;
    final isLastPlayer = _currentPlayerIndex == _players.length - 1;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 24),
        child: Column(
          children: [
            RoleRevealProgress(
              currentIndex: _currentPlayerIndex,
              total: _players.length,
              isTablet: isTablet,
            ),
            const Spacer(),

            // Pass-the-phone step, then the role reveal step
            if (!_isRoleRevealed)
              PassPhoneCard(player: currentPlayer, isTablet: isTablet)
            else
              RoleRevealCard(
                player: currentPlayer,
                isImposter: isImposter,
                character: _character!,
                isTablet: isTablet,
              ),

            const Spacer(),

            RoleRevealActionButton(
              isRoleRevealed: _isRoleRevealed,
              isLastPlayer: isLastPlayer,
              isTablet: isTablet,
              onPressed: _handleAction,
            ),
            SizedBox(height: isTablet ? 32 : 24),
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
              SnackBar(content: Text(context.l10n.couldNotStartSafely)),
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
