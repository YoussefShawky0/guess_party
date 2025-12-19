import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  final String username;
  final bool isTablet;

  const WelcomeSection({
    super.key,
    required this.username,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: isTablet ? 50 : 40,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(
              Icons.person_rounded,
              size: isTablet ? 50 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Welcome, $username!',
            style: TextStyle(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Ready to play?',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
