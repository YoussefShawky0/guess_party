import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class MaxPlayersSelector extends StatelessWidget {
  final int selectedMaxPlayers;
  final Function(int) onMaxPlayersChanged;

  const MaxPlayersSelector({
    super.key,
    required this.selectedMaxPlayers,
    required this.onMaxPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final playerOptions = [4, 6, 8, 10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Players',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Wrap(
          spacing: isTablet ? 16 : 12,
          runSpacing: isTablet ? 16 : 12,
          children: playerOptions.map((players) {
            final isSelected = selectedMaxPlayers == players;
            return ChoiceChip(
              label: Text(
                '$players Players',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.of(context).textPrimary
                      : AppColors.of(context).textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onMaxPlayersChanged(players);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.of(context).surface,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.of(context).textPrimary
                    : AppColors.of(context).textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
