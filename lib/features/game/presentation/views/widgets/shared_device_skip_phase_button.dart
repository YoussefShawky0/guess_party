import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';

/// Shared-Device host control: confirm, then skip hints -> voting or
/// voting -> results.
class SharedDeviceSkipPhaseButton extends StatelessWidget {
  final GamePhase phase;
  final void Function(String roundId) onFinalizeVoting;

  const SharedDeviceSkipPhaseButton({
    super.key,
    required this.phase,
    required this.onFinalizeVoting,
  });

  @override
  Widget build(BuildContext context) {
    final skipTarget = phase == GamePhase.hints
        ? context.l10n.votingPhase
        : context.l10n.resultsPhase;
    final skipLabel = phase == GamePhase.hints
        ? context.l10n.skipToVoting
        : context.l10n.skipToResults;

    return GameButton(
      variant: GameButtonVariant.secondary,
      size: GameButtonSize.md,
      icon: const Icon(Icons.skip_next),
      label: skipLabel,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              phase == GamePhase.hints
                  ? context.l10n.skipHints
                  : context.l10n.skipVoting,
            ),
            content: Text(context.l10n.skipPhaseConfirmation(skipTarget)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.skip),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;

        final current = context.read<GameCubit>().state;
        if (current is! GameLoaded) return;
        if (phase == GamePhase.hints) {
          context.read<GameCubit>().progressPhase(
            current.gameState.currentRound.id,
          );
        } else {
          onFinalizeVoting(current.gameState.currentRound.id);
        }
      },
    );
  }
}
