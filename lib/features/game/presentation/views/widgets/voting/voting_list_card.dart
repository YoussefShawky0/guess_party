import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

/// Card chrome shared by the online and shared-device voting lists.
class VotingListCard extends StatelessWidget {
  final String title;
  final bool isTablet;
  final List<Widget> children;

  const VotingListCard({
    super.key,
    required this.title,
    required this.isTablet,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...children,
        ],
      ),
    );
  }
}
