import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/room/presentation/cubit/countdown_cubit.dart';
import 'package:guess_party/l10n/app_localizations.dart';

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
  Timer? _tickTimer;
  Timer? _goTimer;

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
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 0) {
        setState(() => _countdown--);
        _animationController.forward(from: 0);
      } else {
        timer.cancel();
        _showGoAndResolve();
      }
    });
  }

  void _showGoAndResolve() {
    setState(() => _countdown = -1);
    _animationController.forward(from: 0);

    // Wait for the "GO!" animation, then verify the round exists.
    _goTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      context.read<CountdownCubit>().resolveRound();
    });
  }

  void _navigate(CountdownReady ready) {
    if (!mounted) return;
    if (ready.isLocal) {
      context.go(AppRoutes.roomRoleReveal(widget.roomId));
    } else {
      context.go(AppRoutes.roomGame(widget.roomId));
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _goTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CountdownCubit, CountdownState>(
      listener: (context, state) {
        if (state is CountdownReady) _navigate(state);
      },
      builder: (context, state) {
        if (state is CountdownRoundUnavailable) {
          return _buildUnavailable(context, state);
        }
        return _buildCountdown(context);
      },
    );
  }

  Widget _buildUnavailable(BuildContext context, CountdownRoundUnavailable s) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizedErrorMessage(l10n, s.code),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.read<CountdownCubit>().resolveRound(),
                child: Text(l10n.retry),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(BuildContext context) {
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
