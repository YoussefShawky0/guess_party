import 'package:flutter/material.dart';

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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(51),
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
                  Icon(
                    Icons.timer_rounded,
                    color: Theme.of(context).primaryColor,
                    size: isTablet ? 24 : 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Number of Rounds',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
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
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedRounds',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor:
                  Theme.of(context).primaryColor.withAlpha(77),
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withAlpha(51),
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
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '10 rounds',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey,
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