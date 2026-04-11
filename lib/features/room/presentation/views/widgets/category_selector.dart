import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;
  final Map<String, String> categories;
  final bool enabled;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.categories,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
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
            children: [
              FaIcon(
                FontAwesomeIcons.shapes,
                color: AppColors.primary,
                size: isTablet ? 20 : 16,
              ),
              const SizedBox(width: 12),
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.of(context).surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 16 : 12,
              ),
            ),
            dropdownColor: AppColors.of(context).surface,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: AppColors.of(context).textPrimary,
            ),
            items: categories.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: enabled ? (value) => onChanged(value!) : null,
          ),
        ],
      ),
    );
  }
}
