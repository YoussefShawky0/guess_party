import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActionButtons extends StatelessWidget {
  final bool isTablet;

  const HomeActionButtons({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => context.push('/create-room'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: isTablet ? 32 : 28),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                'Create Room',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        OutlinedButton(
          onPressed: () => context.push('/join-room'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: isTablet ? 32 : 28),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                'Join Room',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
