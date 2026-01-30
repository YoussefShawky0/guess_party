import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class GameModeSelector extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const GameModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Game Mode',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                context: context,
                mode: 'online',
                title: 'Online',
                subtitle: 'Each player joins from their own device',
                icon: FontAwesomeIcons.towerBroadcast,
                isSelected: selectedMode == 'online',
                isTablet: isTablet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                context: context,
                mode: 'local',
                title: 'Local',
                subtitle: 'Pass & play on one device',
                icon: FontAwesomeIcons.mobile,
                isSelected: selectedMode == 'local',
                isTablet: isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: isTablet ? 40 : 32,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                SizedBox(height: isTablet ? 8 : 6),
                FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.primary,
                  size: isTablet ? 20 : 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
