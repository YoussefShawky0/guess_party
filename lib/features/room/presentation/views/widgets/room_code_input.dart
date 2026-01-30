import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class RoomCodeInput extends StatelessWidget {
  final TextEditingController controller;

  const RoomCodeInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Room Code',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(
            FontAwesomeIcons.key,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isTablet ? 32 : 28,
        fontWeight: FontWeight.bold,
        letterSpacing: isTablet ? 16 : 12,
        color: AppColors.textPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
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
