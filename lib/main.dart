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

import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await di.init();

  final sentryDsn = dotenv.env['SENTRY_DSN'];

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    return false;
  };

  await runZonedGuarded(
    () async {
      if (sentryDsn != null && sentryDsn.isNotEmpty) {
        await SentryFlutter.init((options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 1.0;
          options.sendDefaultPii = false;
        }, appRunner: () => runApp(const GuessParty()));
      } else {
        runApp(const GuessParty());
      }
    },
    (error, stackTrace) {
      if (sentryDsn != null && sentryDsn.isNotEmpty) {
        Sentry.captureException(error, stackTrace: stackTrace);
      }
    },
  );
}

class GuessParty extends StatelessWidget {
  const GuessParty({super.key});

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
