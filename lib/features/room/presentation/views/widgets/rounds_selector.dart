import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class RoundsSelector extends StatelessWidget {
  final int selectedRounds;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const RoundsSelector({
    super.key,
    required this.selectedRounds,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.chartSimple,
                    color: AppColors.primary,
                    size: isTablet ? 20 : 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Number of Rounds',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedRounds',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: isTablet ? 6 : 4,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isTablet ? 12 : 10,
              ),
            ),
            child: Slider(
              value: selectedRounds.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              label: '$selectedRounds rounds',
              onChanged: enabled ? (value) => onChanged(value.toInt()) : null,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '3 rounds',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '10 rounds',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
