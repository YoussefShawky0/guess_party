import 'package:flutter/material.dart';

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
            color: Theme.of(context).primaryColor,
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
                icon: Icons.devices,
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
                icon: Icons.phone_android,
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
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isTablet ? 48 : 40,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  color: Colors.grey.shade700,
                ),
              ),
              if (isSelected) ...[
                SizedBox(height: isTablet ? 8 : 6),
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: isTablet ? 24 : 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
