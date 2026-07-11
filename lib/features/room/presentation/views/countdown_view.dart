import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';

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
      final result = await sl<GetRoomDetails>()(roomId: widget.roomId);
      if (mounted) {
        result.fold(
          (_) => setState(() => _gameMode = GameConstants.gameModeOnline),
          (room) => setState(() => _gameMode = room.gameMode),
        );
      }
    } catch (e) {
      // Default to online if error
      if (mounted) {
        setState(() {
          _gameMode = GameConstants.gameModeOnline;
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

    // Wait for "GO!" animation, then verify round exists before navigating.
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      // Poll for the round to be created (up to 5 seconds with 1s intervals).
      // The DB trigger `create_first_round` should have run by now, but on
      // slow networks there may be a delay.
      bool roundExists = false;
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          final result = await sl<GameRepository>().getCurrentRound(
            roomId: widget.roomId,
          );
          if (result.isRight()) {
            roundExists = true;
            break;
          }
        } catch (_) {
          // Network error — retry
        }
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!mounted) return;

      if (!roundExists) {
        debugPrint('First round not found after polling, navigating anyway.');
      }

      if (_gameMode == GameConstants.gameModeLocal) {
        context.go(AppRoutes.roomRoleReveal(widget.roomId));
      } else {
        context.go(AppRoutes.roomGame(widget.roomId));
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
      backgroundColor: AppColors.of(context).background,
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
