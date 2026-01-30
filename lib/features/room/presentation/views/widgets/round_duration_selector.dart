import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class RoundDurationSelector extends StatelessWidget {
  final int selectedDuration;
  final Function(int) onDurationChanged;

  const RoundDurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final durationOptions = [
      300,
      420,
      600,
      900,
    ]; // 5, 7, 10, 15 minutes in seconds

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round Duration',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Wrap(
          spacing: isTablet ? 16 : 12,
          runSpacing: isTablet ? 16 : 12,
          children: durationOptions.map((duration) {
            final isSelected = selectedDuration == duration;
            final displayText = duration < 60
                ? '${duration}s'
                : '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} min';

            return ChoiceChip(
              label: Text(
                displayText,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onDurationChanged(duration);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
