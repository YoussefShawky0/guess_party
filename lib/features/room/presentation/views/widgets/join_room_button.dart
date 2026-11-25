import 'package:flutter/material.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';

class JoinRoomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const JoinRoomButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GameButton(
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      label: context.l10n.joinRoom,
    );
  }
}
