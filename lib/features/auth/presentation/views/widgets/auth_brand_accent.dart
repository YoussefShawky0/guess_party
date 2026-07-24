import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class AuthBrandAccent extends StatelessWidget {
  const AuthBrandAccent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AccentBar(color: AppColors.error),
        const SizedBox(width: 6),
        const _AccentBar(color: AppColors.primaryLight),
      ],
    );
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
