import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/shared/presentation/views/splash_screen.dart';
import 'package:guess_party/shared/presentation/views/widgets/fullscreen_splash_artwork.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('keeps the artwork visible before navigating to auth', (
    tester,
  ) async {
    sl.registerSingleton<AuthSessionService>(
      const _FakeAuthSessionService(userId: null),
    );
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byType(FullscreenSplashArtwork), findsOneWidget);

    await tester.pump(
      SplashScreen.minimumDisplayDuration - const Duration(milliseconds: 1),
    );
    expect(find.byType(FullscreenSplashArtwork), findsOneWidget);
    expect(find.text('Auth destination'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(FullscreenSplashArtwork), findsNothing);
    expect(find.text('Auth destination'), findsOneWidget);
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Auth destination'))),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home destination'))),
      ),
    ],
  );
}

class _FakeAuthSessionService implements AuthSessionService {
  const _FakeAuthSessionService({required this.userId});

  final String? userId;

  @override
  String? get currentUserId => userId;

  @override
  String get currentUsername => 'Tester';

  @override
  String? get currentEmail => null;

  @override
  bool get isAnonymous => userId == null;

  @override
  bool get isLegacyAccount => false;

  @override
  bool get isEmailVerified => false;

  @override
  bool get hasPasswordRecoverySession => false;

  @override
  Stream<String?> get userIdChanges => const Stream<String?>.empty();

  @override
  Stream<AuthLifecycleEvent> get lifecycleEvents =>
      const Stream<AuthLifecycleEvent>.empty();

  @override
  Future<void> signOut() async {}

  @override
  void consumePasswordRecoverySession() {}
}
