import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/shared/presentation/views/widgets/fullscreen_splash_artwork.dart';

void main() {
  testWidgets('renders the single splash asset edge to edge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FullscreenSplashArtwork())),
    );

    final image = tester.widget<Image>(find.byType(Image));

    expect(find.byType(FullscreenSplashArtwork), findsOneWidget);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      FullscreenSplashArtwork.assetPath,
    );
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
  });
}
