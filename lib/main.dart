import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guess_party/core/router/app_router.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_routes.dart';
import 'core/services/auth_navigation_coordinator.dart';
import 'core/services/auth_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    runApp(
      BootstrapErrorApp(message: 'Unable to load app configuration: $error'),
    );
    return;
  }

  late final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on AppConfigException catch (error) {
    runApp(BootstrapErrorApp(message: error.message));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );

  await di.init();

  final sentryDsn = config.sentryDsn;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (sentryDsn != null) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (sentryDsn != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    return false;
  };

  await runZonedGuarded(
    () async {
      if (sentryDsn != null) {
        await SentryFlutter.init((options) {
          options.dsn = sentryDsn;
          options.environment = config.environment;
          options.tracesSampleRate = config.sentryTracesSampleRate;
          options.sendDefaultPii = false;
        }, appRunner: () => runApp(const GuessParty()));
      } else {
        runApp(const GuessParty());
      }
    },
    (error, stackTrace) {
      if (sentryDsn != null) {
        Sentry.captureException(error, stackTrace: stackTrace);
      }
    },
  );
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_suggest_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Guess Party could not start',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GuessParty extends StatefulWidget {
  const GuessParty({super.key});

  @override
  State<GuessParty> createState() => _GuessPartyState();
}

class _GuessPartyState extends State<GuessParty> {
  late final AuthNavigationCoordinator _authNavigationCoordinator;

  @override
  void initState() {
    super.initState();
    _authNavigationCoordinator = AuthNavigationCoordinator(
      sessionService: di.sl<AuthSessionService>(),
      onSignedOut: () =>
          _navigateAfterFrame('${AppRoutes.auth}?reason=session-ended'),
      onIntentionalSignedOut: () => _navigateAfterFrame(AppRoutes.auth),
      onPasswordRecovery: () => _navigateAfterFrame(AppRoutes.resetPassword),
    )..start();
  }

  void _navigateAfterFrame(String location) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppRouter.router.go(location);
    });
  }

  @override
  void dispose() {
    unawaited(_authNavigationCoordinator.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: di.sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Guess Party',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
