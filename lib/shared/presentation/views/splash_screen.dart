import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/shared/presentation/views/widgets/fullscreen_splash_artwork.dart';

class SplashScreen extends StatefulWidget {
  static const minimumDisplayDuration = Duration(milliseconds: 1500);
  const SplashScreen({super.key, required this.session});

  final AuthSessionService session;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future<void>.delayed(SplashScreen.minimumDisplayDuration);

    if (!mounted) return;

    final userId = widget.session.currentUserId;
    context.go(userId == null ? AppRoutes.auth : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: FullscreenSplashArtwork());
  }
}
