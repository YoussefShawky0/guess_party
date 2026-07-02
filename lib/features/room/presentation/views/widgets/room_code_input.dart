import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class RoomCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool hasError;

  const RoomCodeInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Room Code',
        labelStyle: TextStyle(color: AppColors.of(context).textSecondary),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(
            hasError ? FontAwesomeIcons.ban : FontAwesomeIcons.key,
            color: hasError ? AppColors.error : AppColors.primary,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.primary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.65)
                : AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: hasError
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.of(context).surface,
      ),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isTablet ? 32 : 28,
        fontWeight: FontWeight.bold,
        letterSpacing: isTablet ? 16 : 12,
        color: AppColors.of(context).textPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: (_) => onChanged?.call(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter room code';
        }
        if (value.length != 6) {
          return 'Room code must be 6 digits';
        }
        return null;
      },
    );
  }
}
