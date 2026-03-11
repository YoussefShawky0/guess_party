import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'phase_timer_widget.dart';

class RoundHeaderWidget extends StatelessWidget {
  final RoundInfo round;
  final int totalRounds;
  final int roundDuration;
  final VoidCallback onTimeUp;

  const RoundHeaderWidget({
    super.key,
    required this.round,
    required this.totalRounds,
    required this.roundDuration,
    required this.onTimeUp,
  });

  String get _durationText {
    switch (round.phase) {
      case GamePhase.hints:
        final minutes = roundDuration ~/ 60;
        final seconds = roundDuration % 60;
        return seconds > 0
            ? '$minutes:${seconds.toString().padLeft(2, '0')} min'
            : '$minutes min';
      case GamePhase.voting:
        return '${GameConstants.votingPhaseDurationSeconds ~/ 60} min';
      case GamePhase.results:
        return '${GameConstants.resultsPhaseDurationSeconds} sec';
    }
  }

  String get _phaseText {
    switch (round.phase) {
      case GamePhase.hints:
        return 'Hints Phase';
      case GamePhase.voting:
        return 'Voting Phase';
      case GamePhase.results:
        return 'Results';
    }
  }

  IconData get _phaseIcon {
    switch (round.phase) {
      case GamePhase.hints:
        return FontAwesomeIcons.lightbulb;
      case GamePhase.voting:
        return FontAwesomeIcons.checkToSlot;
      case GamePhase.results:
        return FontAwesomeIcons.trophy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.of(context).characterCardBg, AppColors.of(context).surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.of(context).characterCardBorder, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            // Top Row: Round number + Timer (timer hidden in results phase)
            if (round.phase == GamePhase.results)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Round ${round.roundNumber}',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $totalRounds',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round ${round.roundNumber}',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $totalRounds',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PhaseTimerWidget(
                    phaseEndTime: round.phaseEndTime,
                    onTimeUp: onTimeUp,
                  ),
                ],
              ),
            SizedBox(height: isTablet ? 16 : 12),
            // Phase info + duration badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _phaseIcon,
                    color: AppColors.primary,
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Text(
                    _phaseText,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  if (round.phase != GamePhase.results) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _durationText,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
