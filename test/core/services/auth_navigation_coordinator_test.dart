import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/services/auth_navigation_coordinator.dart';
import 'package:guess_party/core/services/auth_session_service.dart';

void main() {
  test('expired session redirects exactly once per signed-in cycle', () async {
    final session = FakeAuthSessionService();
    var signedOutNavigations = 0;
    final coordinator = AuthNavigationCoordinator(
      sessionService: session,
      onSignedOut: () => signedOutNavigations++,
      onIntentionalSignedOut: () {},
      onPasswordRecovery: () {},
    )..start();

    session.add(AuthLifecycleEvent.signedOut);
    session.add(AuthLifecycleEvent.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(signedOutNavigations, 1);

    session.add(AuthLifecycleEvent.signedIn);
    session.add(AuthLifecycleEvent.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(signedOutNavigations, 2);

    await coordinator.close();
    await session.close();
  });

  test('password recovery navigation is handled once', () async {
    final session = FakeAuthSessionService();
    var recoveryNavigations = 0;
    final coordinator = AuthNavigationCoordinator(
      sessionService: session,
      onSignedOut: () {},
      onIntentionalSignedOut: () {},
      onPasswordRecovery: () => recoveryNavigations++,
    )..start();

    session.add(AuthLifecycleEvent.passwordRecovery);
    session.add(AuthLifecycleEvent.passwordRecovery);
    await Future<void>.delayed(Duration.zero);
    expect(recoveryNavigations, 1);

    await coordinator.close();
    await session.close();
  });

  test('intentional sign out uses one distinct navigation path', () async {
    final session = FakeAuthSessionService();
    var intentionalNavigations = 0;
    var expiryNavigations = 0;
    final coordinator = AuthNavigationCoordinator(
      sessionService: session,
      onSignedOut: () => expiryNavigations++,
      onIntentionalSignedOut: () => intentionalNavigations++,
      onPasswordRecovery: () {},
    )..start();

    session.add(AuthLifecycleEvent.intentionalSignedOut);
    session.add(AuthLifecycleEvent.intentionalSignedOut);
    await Future<void>.delayed(Duration.zero);

    expect(intentionalNavigations, 1);
    expect(expiryNavigations, 0);
    await coordinator.close();
    await session.close();
  });
}

class FakeAuthSessionService implements AuthSessionService {
  final _events = StreamController<AuthLifecycleEvent>.broadcast();

  void add(AuthLifecycleEvent event) => _events.add(event);
  Future<void> close() => _events.close();

  @override
  Stream<AuthLifecycleEvent> get lifecycleEvents => _events.stream;
  @override
  bool get hasPasswordRecoverySession => false;
  @override
  bool get isAnonymous => false;
  @override
  bool get isEmailVerified => false;
  @override
  bool get isLegacyAccount => false;
  @override
  String? get currentEmail => null;
  @override
  String? get currentUserId => null;
  @override
  String get currentUsername => 'Player';
  @override
  Stream<String?> get userIdChanges => const Stream.empty();
  @override
  Future<void> signOut() async {}
  @override
  void consumePasswordRecoverySession() {}
}
