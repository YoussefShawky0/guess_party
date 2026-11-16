import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Centered spinner with the "loading game" caption.
class GameLoadingIndicator extends StatelessWidget {
  const GameLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            context.l10n.loadingGame,
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}
