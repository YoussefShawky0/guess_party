import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class GameConnectionFeedback extends StatelessWidget {
  final bool isReconnecting;
  final Widget child;

  const GameConnectionFeedback({
    super.key,
    required this.isReconnecting,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isReconnecting)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              key: const Key('game-reconnecting-feedback'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.reconnectingToGame,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
