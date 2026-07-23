import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class CustomPlayerCountOption extends StatefulWidget {
  static const fieldKey = Key('custom-player-count-field');

  const CustomPlayerCountOption({
    super.key,
    required this.isSelected,
    required this.onSelected,
  });

  final bool isSelected;
  final ValueChanged<int?> onSelected;

  @override
  State<CustomPlayerCountOption> createState() =>
      _CustomPlayerCountOptionState();
}

class _CustomPlayerCountOptionState extends State<CustomPlayerCountOption> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus && !widget.isSelected) {
      _validateAndSelect(_controller.text);
    }
  }

  void _handleChanged(String value) {
    if (widget.isSelected) {
      _validateAndSelect(value);
    }
  }

  void _validateAndSelect(String rawValue) {
    final result = _validate(rawValue);
    setState(() => _errorText = result.errorText);
    widget.onSelected(result.value);
  }

  _PlayerCountValidation _validate(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return _PlayerCountValidation(
        errorText: context.l10n.playerCountRequired,
      );
    }
    if (!RegExp(r'^-?\d+$').hasMatch(value)) {
      return _PlayerCountValidation(
        errorText: context.l10n.playerCountWholeNumber,
      );
    }

    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 4 || parsed > 10) {
      return _PlayerCountValidation(
        errorText: context.l10n.playerCountRangeError,
      );
    }
    return _PlayerCountValidation(value: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final colors = AppColors.of(context);

    return Semantics(
      textField: true,
      label: context.l10n.customPlayerCount,
      child: SizedBox(
        width: isTablet ? 180 : 150,
        child: TextField(
          key: CustomPlayerCountOption.fieldKey,
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          maxLines: 1,
          onChanged: _handleChanged,
          style: TextStyle(
            color: widget.isSelected
                ? colors.textPrimary
                : colors.textSecondary,
            fontSize: isTablet ? 18 : 16,
            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.customPlayerCountHint,
            hintStyle: TextStyle(color: colors.textSecondary),
            errorText: widget.isSelected ? _errorText : null,
            errorMaxLines: 2,
            isDense: true,
            filled: true,
            fillColor: widget.isSelected ? AppColors.primary : colors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 18 : 14,
              vertical: isTablet ? 14 : 11,
            ),
            border: _border(AppColors.primary),
            enabledBorder: _border(
              widget.isSelected
                  ? AppColors.primary
                  : colors.textSecondary.withValues(alpha: 0.35),
            ),
            focusedBorder: _border(AppColors.primary, width: 2),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PlayerCountValidation {
  const _PlayerCountValidation({this.value, this.errorText});

  final int? value;
  final String? errorText;
}
