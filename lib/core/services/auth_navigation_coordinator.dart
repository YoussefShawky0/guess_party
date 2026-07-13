import 'dart:async';

import 'auth_session_service.dart';

class AuthNavigationCoordinator {
  AuthNavigationCoordinator({
    required AuthSessionService sessionService,
    required void Function() onSignedOut,
    required void Function() onIntentionalSignedOut,
    required void Function() onPasswordRecovery,
  }) : _sessionService = sessionService,
       _onSignedOut = onSignedOut,
       _onIntentionalSignedOut = onIntentionalSignedOut,
       _onPasswordRecovery = onPasswordRecovery;

  final AuthSessionService _sessionService;
  final void Function() _onSignedOut;
  final void Function() _onIntentionalSignedOut;
  final void Function() _onPasswordRecovery;

  StreamSubscription<AuthLifecycleEvent>? _subscription;
  bool _signedOutHandled = false;
  bool _recoveryHandled = false;

  void start() {
    _subscription ??= _sessionService.lifecycleEvents.listen(_handleEvent);
  }

  void _handleEvent(AuthLifecycleEvent event) {
    switch (event) {
      case AuthLifecycleEvent.signedIn:
        _signedOutHandled = false;
        _recoveryHandled = false;
      case AuthLifecycleEvent.signedOut:
        if (_signedOutHandled) return;
        _signedOutHandled = true;
        _recoveryHandled = false;
        _onSignedOut();
      case AuthLifecycleEvent.intentionalSignedOut:
        if (_signedOutHandled) return;
        _signedOutHandled = true;
        _recoveryHandled = false;
        _onIntentionalSignedOut();
      case AuthLifecycleEvent.passwordRecovery:
        if (_recoveryHandled) return;
        _recoveryHandled = true;
        _onPasswordRecovery();
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
