import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class ImposterRevealCard extends StatelessWidget {
  final Player imposter;
  final bool imposterCaught;

  const ImposterRevealCard({
    super.key,
    required this.imposter,
    required this.imposterCaught,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.resultsImposterBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: imposterCaught ? AppColors.success : AppColors.error,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (imposterCaught ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        child: Column(
          children: [
            FaIcon(
              imposterCaught
                  ? FontAwesomeIcons.circleCheck
                  : FontAwesomeIcons.xmark,
              size: isTablet ? 80 : 64,
              color: imposterCaught
                  ? AppColors.resultsCaughtIcon
                  : AppColors.resultsEscapedIcon,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              imposterCaught ? '🎉 Imposter Caught!' : '😈 Imposter Won!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: imposterCaught
                    ? AppColors.resultsCaughtIcon
                    : AppColors.resultsEscapedIcon,
                fontSize: isTablet ? 32 : 24,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.imposterCardBorder,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'The Imposter was:',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 32 : 24,
                        backgroundColor: AppColors.imposterCardBorder,
                        child: Text(
                          imposter.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 24,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Flexible(
                        child: Text(
                          imposter.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 28 : 22,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
