import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _gameMode;

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

    _loadGameMode();
    _startCountdown();
  }

  Future<void> _loadGameMode() async {
    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .select('game_mode')
          .eq('id', widget.roomId)
          .single();
      if (mounted) {
        setState(() {
          _gameMode = response['game_mode'] as String?;
        });
      }
    } catch (e) {
      // Default to online if error
      if (mounted) {
        setState(() {
          _gameMode = 'online';
        });
      }
    }
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
        // For local mode, go to role reveal screen first
        // For online mode, go directly to game
        if (_gameMode == 'local') {
          context.go('/room/${widget.roomId}/role-reveal');
        } else {
          context.go('/room/${widget.roomId}/game');
        }
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
      backgroundColor: AppColors.background,
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
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'GO!',
                      style: TextStyle(
                        fontSize: isTablet ? 120 : 100,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
