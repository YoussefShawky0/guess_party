import 'package:flutter/material.dart';

class FullscreenSplashArtwork extends StatelessWidget {
  const FullscreenSplashArtwork({super.key});

  static const assetPath = 'assets/images/splash_fullscreen_v1.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}
