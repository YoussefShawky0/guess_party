import 'dart:async';
import 'package:flutter/material.dart';

class PhaseTimerWidget extends StatefulWidget {
  final DateTime phaseEndTime;
  final VoidCallback? onTimeUp;
  final bool isLargeDisplay;

  const PhaseTimerWidget({
    super.key,
    required this.phaseEndTime,
    this.onTimeUp,
    this.isLargeDisplay = false,
  });

  @override
  State<PhaseTimerWidget> createState() => _PhaseTimerWidgetState();
}

class _PhaseTimerWidgetState extends State<PhaseTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasCalledOnTimeUp = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(PhaseTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phaseEndTime != widget.phaseEndTime) {
      _hasCalledOnTimeUp = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    print('⏱️ Starting timer. Phase end time: ${widget.phaseEndTime}');
    print('⏱️ Current time: ${DateTime.now()}');
    print(
      '⏱️ Difference: ${widget.phaseEndTime.difference(DateTime.now()).inSeconds} seconds',
    );
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();
    final difference = widget.phaseEndTime.difference(now);
    final newSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;

    if (_remainingSeconds != newSeconds) {
      print(
        '⏱️ Timer update: $_remainingSeconds → $newSeconds seconds remaining',
      );
    }

    setState(() {
      _remainingSeconds = newSeconds;
    });

    if (_remainingSeconds == 0 && !_hasCalledOnTimeUp) {
      print('⏰ Time is up!');
      _hasCalledOnTimeUp = true;
      _timer?.cancel();
      widget.onTimeUp?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 30) {
      return Colors.green;
    } else if (_remainingSeconds > 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    final timeText = _formatTime();

    if (widget.isLargeDisplay) {
      return _buildLargeTimer(color, timeText);
    }

    return _buildCompactTimer(color, timeText);
  }

  Widget _buildCompactTimer(Color color, String timeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            's',
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTimer(Color color, String timeText) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              'Time Remaining',
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
              ),
            ),
            Text(
              'seconds',
              style: TextStyle(fontSize: 16, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
