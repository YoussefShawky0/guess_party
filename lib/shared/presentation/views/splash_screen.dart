import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user has active session
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in → go to Home
      context.go('/home');
    } else {
      // User not logged in → go to Auth
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset(
              'assets/icons/Main_icon.png',
              width: isTablet ? 420 : 320,
              height: isTablet ? 320 : 240,
              fit: BoxFit.contain,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            // App Name
            Text(
              'Guess Party',
              style: TextStyle(
                fontSize: isTablet ? 48 : 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: isTablet ? 48 : 40),
            // Three Dots Loading Animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    // Each dot animates with a delay
                    final delay = index * 0.2;
                    final animValue =
                        ((_animationController.value + delay) % 1.0);
                    // Create a bounce effect
                    final scale = 0.5 + (0.5 * _calculateBounce(animValue));
                    final opacity = 0.4 + (0.6 * _calculateBounce(animValue));

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 6,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: isTablet ? 16 : 12,
                          height: isTablet ? 16 : 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateBounce(double t) {
    // Creates a smooth bounce effect
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      return 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
    }
  }
}
