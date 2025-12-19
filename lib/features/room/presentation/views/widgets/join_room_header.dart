import 'package:flutter/material.dart';

class JoinRoomHeader extends StatelessWidget {
  const JoinRoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        Icon(
          Icons.group_add_rounded,
          size: isTablet ? 120 : 100,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: isTablet ? 40 : 32),
        Text(
          'Enter Room Code',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
