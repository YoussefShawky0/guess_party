import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/l10n/l10n.dart';

class VotePlayerTile extends StatelessWidget {
  final Player player;
  final int voteCount;
  final bool iVotedForThis; // online mode: I voted for this player
  final bool
  hasAlreadyVotedAsVoter; // local mode: this player already cast their vote
  final bool isTablet;
  final VoidCallback onVote;

  const VotePlayerTile({
    super.key,
    required this.player,
    required this.voteCount,
    required this.iVotedForThis,
    required this.hasAlreadyVotedAsVoter,
    required this.isTablet,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: (iVotedForThis || hasAlreadyVotedAsVoter)
              ? AppColors.voteSelectedBg
              : AppColors.of(context).voteUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (iVotedForThis || hasAlreadyVotedAsVoter)
                ? AppColors.success
                : AppColors.of(context).cardBorder,
            width: (iVotedForThis || hasAlreadyVotedAsVoter) ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 8 : 4,
          ),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: isTablet ? 24 : 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: isTablet ? 20 : 16,
                  ),
                ),
              ),
              // Vote count badge
              if (voteCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: isTablet ? 22 : 18,
                    height: isTablet ? 22 : 18,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.of(context).surface,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$voteCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            player.username,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          subtitle: voteCount > 0
              ? Text(
                  voteCount == 1 ? '1 vote' : '$voteCount votes',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing: (iVotedForThis || hasAlreadyVotedAsVoter)
              ? FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.success,
                  size: isTablet ? 28 : 22,
                )
              : ElevatedButton(
                  onPressed: onVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.of(context).textPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    context.l10n.vote,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
