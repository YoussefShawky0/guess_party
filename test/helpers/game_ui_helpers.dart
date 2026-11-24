import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/l10n/app_localizations.dart';

/// Loads the real Baloo Bhaijaan 2 so overflow tests measure real glyphs, not
/// the test font. Call from `setUpAll`.
Future<void> loadGameFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('BalooBhaijaan2')
    ..addFont(rootBundle.load('assets/fonts/BalooBhaijaan2-Variable.ttf'));
  await loader.load();
}

/// Counts light UI-tap haptics.
class CountingFeedback extends SilentGameFeedback {
  int taps = 0;

  @override
  Future<void> tapHaptic() async => taps++;
}

/// Wraps [home] in an app with the real theme, l10n, a text scale and a
/// feedback provider.
Widget gameTestApp({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  GameFeedback? feedback,
  bool disableAnimations = false,
}) {
  return RepositoryProvider<GameFeedback>.value(
    value: feedback ?? SilentGameFeedback(),
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Stats repository the test completes by hand.
class GateStatsRepository implements StatsRepository {
  final completer = Completer<Either<Failure, PlayerStats>>();
  int calls = 0;

  @override
  Future<Either<Failure, PlayerStats>> getMyStats() {
    calls++;
    return completer.future;
  }
}

class FakeBadgeSummaryStore implements BadgeSummaryStore, GuestBannerStore {
  FakeBadgeSummaryStore({Map<String, BadgeSummary>? initial})
    : summaries = {...?initial};

  final Map<String, BadgeSummary> summaries;
  final dismissed = <String>{};
  final cleared = <String>[];

  @override
  Future<BadgeSummary?> read(String userId) async => summaries[userId];

  @override
  Future<void> write(String userId, BadgeSummary summary) async =>
      summaries[userId] = summary;

  @override
  Future<void> clear(String userId) async {
    cleared.add(userId);
    summaries.remove(userId);
  }

  @override
  Future<bool> isDismissed(String userId) async => dismissed.contains(userId);

  @override
  Future<void> dismiss(String userId) async => dismissed.add(userId);
}

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository(this.user);

  final UserInfo user;
  int signOutCalls = 0;

  @override
  Future<Either<Failure, UserInfo>> getCurrentUser() async => Right(user);

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async => const Right(null);
}

const guestUser = UserInfo(
  id: 'u1',
  username: 'Sam',
  isAnonymous: true,
  email: null,
  isLegacyAccount: false,
);

const fullUser = UserInfo(
  id: 'u1',
  username: 'Sam',
  isAnonymous: false,
  email: 'sam@example.com',
  isLegacyAccount: false,
);
