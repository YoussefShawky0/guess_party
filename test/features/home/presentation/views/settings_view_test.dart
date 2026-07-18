import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/features/home/presentation/views/settings_view.dart';
import 'package:guess_party/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sl = GetIt.instance;

void main() {
  late ThemeCubit themeCubit;
  late LocaleCubit localeCubit;

  setUp(() async {
    await _sl.reset();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Guess Party',
      packageName: 'com.youssefshawky.guessparty',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );

    themeCubit = ThemeCubit();
    localeCubit = LocaleCubit();
    _sl.registerSingleton<ThemeCubit>(themeCubit);
    _sl.registerSingleton<LocaleCubit>(localeCubit);
    _sl.registerSingleton<AppConfig>(
      const AppConfig(
        environment: AppEnvironment.development,
        distribution: AppDistribution.internal,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test',
        sentryDsn: null,
        sentryTracesSampleRate: 0,
        sentryRelease: null,
        sentryDist: null,
      ),
    );
  });

  tearDown(() async {
    await themeCubit.close();
    await localeCubit.close();
    await _sl.reset();
  });

  Widget harness({TextScaler textScaler = const TextScaler.linear(1)}) {
    return BlocLocaleHarness(localeCubit: localeCubit, textScaler: textScaler);
  }

  testWidgets(
    'shows language and delete-account settings without source link',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings-language')), findsOneWidget);
      expect(find.byKey(const Key('settings-delete-account')), findsOneWidget);
      expect(find.text('View on GitHub'), findsNothing);
      expect(find.text('Check out the source code'), findsNothing);

      await tester.tap(find.byKey(const Key('settings-language')));
      await tester.pumpAndSettle();
      expect(find.text('Choose Language'), findsOneWidget);
      expect(find.text('Arabic'), findsOneWidget);

      await tester.tap(find.text('Arabic'));
      await tester.pumpAndSettle();
      expect(find.text('الإعدادات'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-delete-account')),
        250,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-delete-account')));
      await tester.pumpAndSettle();
      expect(find.text('حذف حسابك؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    },
  );

  testWidgets('settings remains usable at 200 percent text scale', (
    tester,
  ) async {
    await tester.pumpWidget(harness(textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-language')),
      300,
      scrollable: list,
    );
    expect(find.byKey(const Key('settings-language')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-delete-account')),
      300,
      scrollable: list,
    );
    expect(find.byKey(const Key('settings-delete-account')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class BlocLocaleHarness extends StatelessWidget {
  const BlocLocaleHarness({
    required this.localeCubit,
    required this.textScaler,
    super.key,
  });

  final LocaleCubit localeCubit;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale?>(
      bloc: localeCubit,
      builder: (context, locale) {
        return MaterialApp(
          locale: locale,
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: const SettingsView(),
        );
      },
    );
  }
}
