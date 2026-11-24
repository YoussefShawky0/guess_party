import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/feedback_settings_section.dart';
import 'package:guess_party/l10n/app_localizations.dart';

class RecordingFeedback extends SilentGameFeedback {
  final calls = <String>[];

  @override
  Future<void> setSoundEnabled(bool value) {
    calls.add('sound:$value');
    return super.setSoundEnabled(value);
  }

  @override
  Future<void> setHapticsEnabled(bool value) {
    calls.add('haptics:$value');
    return super.setHapticsEnabled(value);
  }
}

void main() {
  late RecordingFeedback feedback;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    RepositoryProvider<GameFeedback>.value(
      value: feedback,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: FeedbackSettingsSection(isTablet: false),
          ),
        ),
      ),
    ),
  );

  setUp(() => feedback = RecordingFeedback());

  testWidgets('shows both switches reflecting the service', (tester) async {
    await feedback.setHapticsEnabled(false);
    feedback.calls.clear();
    await pump(tester);

    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('settings-sound-switch')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('settings-vibration-switch')))
          .value,
      isFalse,
    );
  });

  testWidgets('toggling a switch calls the service', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-sound-switch')));
    await tester.pump();
    expect(feedback.calls, ['sound:false']);
    expect(feedback.soundEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings-vibration')));
    await tester.pump();
    expect(feedback.calls, ['sound:false', 'haptics:false']);
    expect(feedback.hapticsEnabled, isFalse);
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('settings-sound-switch')))
          .value,
      isFalse,
    );
  });
}
