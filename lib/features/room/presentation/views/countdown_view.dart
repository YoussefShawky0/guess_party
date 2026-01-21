import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CountdownScreen extends StatefulWidget {
  final String roomId;

  const CountdownScreen({super.key, required this.roomId});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int _countdown = 3;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 0) {
        setState(() => _countdown--);
        _animationController.forward(from: 0);
      } else {
        timer.cancel();
        _showGoAndNavigate();
      }
    });
  }

  void _showGoAndNavigate() {
    setState(() => _countdown = -1);
    _animationController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Navigate to game screen after countdown
        context.go('/room/${widget.roomId}/game');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _countdown > 0
                  ? Text(
                      '$_countdown',
                      style: TextStyle(
                        fontSize: isTablet ? 180 : 150,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : Text(
                      'GO!',
                      style: TextStyle(
                        fontSize: isTablet ? 120 : 100,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
