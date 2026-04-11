import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isImposter;
  final String gameMode;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isImposter,
    required this.gameMode,
  });

  String _formatCategoryLabel(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isImposter) {
      return _buildImposterCard(context, isTablet);
    } else {
      return _buildCharacterCard(context, isTablet);
    }
  }

  Widget _buildCharacterCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).characterCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).characterCardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).characterCardBorder.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: isTablet ? 64 : 48,
              color: AppColors.of(context).characterCardIcon,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'Character',
              style: TextStyle(
                color: AppColors.of(context).characterCardSubtext,
                fontSize: isTablet ? 20 : 18,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              gameMode == GameConstants.gameModeLocal ? '???' : character.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).characterCardText,
                fontSize: isTablet ? 32 : 26,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 10 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.of(context).characterCardBorder.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: isTablet ? 20 : 16,
                    color: AppColors.of(context).characterCardSubtext,
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    _formatCategoryLabel(character.category),
                    style: TextStyle(
                      color: AppColors.of(context).characterCardSubtext,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImposterCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.imposterCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.imposterCardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.imposterCardBorder.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              size: isTablet ? 64 : 48,
              color: AppColors.imposterCardIcon,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              '⚠️ You are the Impostor!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.imposterCardText,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 26 : 22,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              "You don't know the character!\nTry to guess from the hints",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.imposterCardSubtext,
                fontSize: isTablet ? 16 : 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
