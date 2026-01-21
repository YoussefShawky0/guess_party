import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';

class RoomCodeCard extends StatelessWidget {
  final String roomCode;

  const RoomCodeCard({super.key, required this.roomCode});

  void _copyRoomCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ErrorSnackBar.showSuccess(context, 'Room code copied!');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Room Code',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Room Code Display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              roomCode,
              style: TextStyle(
                fontSize: isTablet ? 56 : 48,
                fontWeight: FontWeight.bold,
                letterSpacing: isTablet ? 12 : 8,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Copy Button
          TextButton.icon(
            onPressed: () => _copyRoomCode(context),
            icon: const Icon(Icons.copy, size: 20),
            label: const Text('Copy Code'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
