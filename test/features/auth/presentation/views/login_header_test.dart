import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/auth/presentation/views/widgets/login_header.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  testWidgets('uses the tightly cropped figures artwork at a readable size', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;

    await _pumpHeader(tester, locale: const Locale('en'));

    final image = tester.widget<Image>(find.byKey(const Key('login-figures')));
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/images/Figures.png');
    expect(image.width, 220);
    expect(image.height, closeTo(100.7, 0.1));
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets(
    'supports Arabic RTL at 200 percent text scale without overflow',
    (tester) async {
      await _pumpHeader(
        tester,
        locale: const Locale('ar'),
        title: 'مرحبًا بعودتك',
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('مرحبًا بعودتك'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    },
  );
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Locale locale,
  String title = 'Welcome Back',
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Center(child: LoginHeader(title: title)),
      ),
    ),
  );
}
