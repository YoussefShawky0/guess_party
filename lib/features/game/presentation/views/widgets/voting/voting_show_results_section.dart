import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Shown once every required vote is in: host gets the "show results" button,
/// everyone else sees a waiting-for-host notice.
class VotingShowResultsSection extends StatelessWidget {
  final bool isHost;
  final bool isFinalizingVoting;
  final VoidCallback? onShowResults;
  final bool isTablet;

  const VotingShowResultsSection({
    super.key,
    required this.isHost,
    required this.isFinalizingVoting,
    required this.onShowResults,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (isHost) {
      return ElevatedButton.icon(
        onPressed: isFinalizingVoting ? null : onShowResults,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(
          isFinalizingVoting
              ? context.l10n.finalizingResults
              : context.l10n.showResultsNow,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.of(context).textPrimary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.l10n.allVotesWaitingHost,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
