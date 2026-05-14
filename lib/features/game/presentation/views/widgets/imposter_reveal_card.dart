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
    final accent = imposterCaught ? AppColors.success : AppColors.error;
    final title = imposterCaught ? 'Imposter Caught' : 'Imposter Escaped';
    final subtitle = imposterCaught
        ? 'The group found the hidden player.'
        : 'The imposter avoided the vote.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        child: Column(
          children: [
            Container(
              width: isTablet ? 78 : 64,
              height: isTablet ? 78 : 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: FaIcon(
                  imposterCaught
                      ? FontAwesomeIcons.check
                      : FontAwesomeIcons.userSecret,
                  size: isTablet ? 34 : 28,
                  color: accent,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 18 : 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
                fontSize: isTablet ? 30 : 23,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.of(
                  context,
                ).surfaceLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    'The Imposter was:',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 32 : 24,
                        backgroundColor: accent.withValues(alpha: 0.85),
                        child: Text(
                          imposter.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 24,
                            color: AppColors.of(context).textPrimary,
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
                            color: AppColors.of(context).textPrimary,
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
