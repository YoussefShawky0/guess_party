import 'package:flutter/material.dart';

class CreateRoomHeader extends StatelessWidget {
  const CreateRoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.meeting_room_rounded,
            size: isTablet ? 64 : 48,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Text(
          'Create New Room',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Choose category and rounds to start the game',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}