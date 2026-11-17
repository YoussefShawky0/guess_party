import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Online mode: shown once the current player has cast their vote.
class VoteSubmittedCard extends StatelessWidget {
  final bool isTablet;

  const VoteSubmittedCard({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.voteSelectedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.circleCheck,
            color: AppColors.success,
            size: isTablet ? 28 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              context.l10n.voteSubmittedWaiting,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the current user cannot be resolved to a room player yet.
class VotingPlayerNotFoundCard extends StatelessWidget {
  final bool isTablet;

  const VotingPlayerNotFoundCard({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: isTablet ? 28 : 24,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              context.l10n.syncingPlayerInfoHelp,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "N of M votes" progress card.
class VotingProgressCard extends StatelessWidget {
  final RoundInfo round;
  final bool isTablet;

  const VotingProgressCard({
    super.key,
    required this.round,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final progress = round.requiredVoteCount <= 0
        ? 0.0
        : (round.submittedVoteCount / round.requiredVoteCount)
              .clamp(0.0, 1.0)
              .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.votesProgress(
              round.submittedVoteCount,
              round.requiredVoteCount,
            ),
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isTablet ? 12 : 8,
              backgroundColor: AppColors.of(context).surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
