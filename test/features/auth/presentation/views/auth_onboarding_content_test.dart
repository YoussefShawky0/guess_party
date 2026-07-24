import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/auth/presentation/views/widgets/auth_onboarding_content.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  testWidgets('renders the approved English onboarding hierarchy and actions', (
    tester,
  ) async {
    var startCount = 0;
    var loginCount = 0;

    await _pumpOnboarding(
      tester,
      locale: const Locale('en'),
      onStartPlaying: () => startCount++,
      onLogin: () => loginCount++,
    );

    expect(find.byKey(const Key('auth-figures')), findsOneWidget);
    expect(find.byKey(const Key('auth-brand-title')), findsOneWidget);
    expect(find.text('Find the imposter. Own the room.'), findsOneWidget);
    expect(find.text('PLAY AS GUEST'), findsOneWidget);
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Start Playing'), findsOneWidget);
    expect(find.text('No account required'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest-start-button')));
    await tester.ensureVisible(find.byKey(const Key('auth-login-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-login-action')));
    await tester.pump();

    expect(startCount, 1);
    expect(loginCount, 1);
  });

  testWidgets(
    'renders localized Arabic content in RTL without translating title',
    (tester) async {
      await _pumpOnboarding(tester, locale: const Locale('ar'));

      expect(find.text('Guess Party', findRichText: true), findsOneWidget);
      expect(find.text('اكتشف المحتال وسيطر على اللعبة.'), findsOneWidget);
      expect(find.text('العب كضيف'), findsOneWidget);
      expect(find.text('أدخل اسم المستخدم'), findsOneWidget);
      expect(find.text('ابدأ اللعب'), findsOneWidget);
      expect(find.text('لا حاجة إلى حساب'), findsOneWidget);
      expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    },
  );

  testWidgets('accepts an Arabic guest username', (tester) async {
    await _pumpOnboarding(tester, locale: const Locale('ar'));

    await tester.enterText(
      find.byKey(const Key('guest-username-field')),
      'محمد',
    );

    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isTrue);
    await tester.pump();
    expect(find.text('محمد'), findsOneWidget);
  });

  testWidgets('has no overflow at 200 percent text scale on phone and tablet', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in <Size>[const Size(360, 800), const Size(800, 1000)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await _pumpOnboarding(
        tester,
        locale: const Locale('en'),
        textScaler: const TextScaler.linear(2),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    }
  });

  testWidgets('centers the complete content group on a tall phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;

    await _pumpOnboarding(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();

    final contentTop = tester
        .getTopLeft(find.byKey(const Key('auth-figures')))
        .dy;
    final contentBottom = tester
        .getBottomRight(find.byKey(const Key('auth-login-action')))
        .dy;
    final topSpace = contentTop;
    final bottomSpace = 900 - contentBottom;

    expect((topSpace - bottomSpace).abs(), lessThan(48));
  });

  testWidgets('loading state disables input and shows progress feedback', (
    tester,
  ) async {
    var startCount = 0;

    await _pumpOnboarding(
      tester,
      locale: const Locale('en'),
      isLoading: true,
      onStartPlaying: () => startCount++,
    );

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('guest-username-field')),
    );
    expect(field.enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest-start-button')));
    await tester.pump();
    expect(startCount, 0);
  });
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  required Locale locale,
  TextScaler textScaler = TextScaler.noScaling,
  bool isLoading = false,
  VoidCallback? onStartPlaying,
  VoidCallback? onLogin,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      home: Scaffold(
        body: AuthOnboardingContent(
          formKey: GlobalKey<FormState>(),
          usernameController: controller,
          isLoading: isLoading,
          sessionEnded: false,
          onStartPlaying: onStartPlaying ?? () {},
          onLogin: onLogin ?? () {},
        ),
      ),
    ),
  );
}
