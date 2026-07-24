import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/utils/validators.dart';
import 'package:guess_party/l10n/l10n.dart';

class UsernameField extends StatelessWidget {
  const UsernameField({
    required this.controller,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return TextFormField(
      key: const Key('guest-username-field'),
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w400,
        color: AppColors.of(context).textPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.enterUsername,
        hintStyle: TextStyle(
          fontSize: isTablet ? 18 : 16,
          color: const Color(0xFFADC3D8),
        ),
        prefixIcon: Icon(
          Icons.person_outline,
          size: isTablet ? 24 : 20,
          color: const Color(0xFFAFC6DB),
        ),
        filled: true,
        fillColor: const Color(0xF50E273E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2F6092)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2F6092)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 18,
          vertical: isTablet ? 19 : 17,
        ),
      ),
      validator: Validators.username,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      autocorrect: false,
      enableSuggestions: false,
    );
  }
}
