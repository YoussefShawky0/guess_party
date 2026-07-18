import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

Future<void> showHowToPlayDialog({required BuildContext context}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          FaIcon(FontAwesomeIcons.gamepad, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.howToPlay,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HowToPlayStep(
              number: '1',
              title: context.l10n.chooseMode,
              description: context.l10n.chooseModeDescription,
            ),
            const SizedBox(height: 12),
            HowToPlayStep(
              number: '2',
              title: context.l10n.createOrJoinRoom,
              description: context.l10n.createOrJoinRoomDescription,
            ),
            const SizedBox(height: 12),
            HowToPlayStep(
              number: '3',
              title: context.l10n.getYourRole,
              description: context.l10n.getYourRoleDescription,
            ),
            const SizedBox(height: 12),
            HowToPlayStep(
              number: '4',
              title: context.l10n.hintsAndVoting,
              description: context.l10n.hintsAndVotingDescription,
            ),
            const SizedBox(height: 12),
            HowToPlayStep(
              number: '5',
              title: context.l10n.resultsAndScoring,
              description: context.l10n.resultsAndScoringDescription,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            context.l10n.gotIt,
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

class HowToPlayStep extends StatelessWidget {
  const HowToPlayStep({
    required this.number,
    required this.title,
    required this.description,
    super.key,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
