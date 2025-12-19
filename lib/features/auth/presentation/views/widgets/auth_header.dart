import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        Icon(
          Icons.psychology_rounded,
          size: isTablet ? 120 : 100,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: isTablet ? 32 : 24),
        Text(
          'Guess Party',
          style: TextStyle(
            fontSize: isTablet ? 48 : 40,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Text(
          'Can you blend in or stand out?',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
