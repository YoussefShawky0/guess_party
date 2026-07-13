import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/character_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/shared_device_phase_content.dart';
import 'package:guess_party/core/theme/app_theme.dart';

import '../../../../../helpers/game_test_fixtures.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );

  testWidgets('shared-device hints component exposes no secret card', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const SingleChildScrollView(
          child: Column(
            children: [
              SharedDeviceIntroCard(isTablet: false),
              SharedDeviceHintsContent(isTablet: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CharacterCard), findsNothing);
    expect(find.byKey(const Key('shared-device-neutral-card')), findsOneWidget);
    expect(
      find.byKey(const Key('shared-device-hints-content')),
      findsOneWidget,
    );
    expect(find.textContaining('Impostor'), findsNothing);
  });

  testWidgets(
    'shared-device voting delegates voter selection without secrets',
    (tester) async {
      String? selectedVoter;
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: SharedDeviceVotingContent(
              round: phase2Round(phase: GamePhase.voting),
              players: phase2Players,
              isTablet: false,
              isFinalizing: false,
              onSelectVoter: (id) => selectedVoter = id,
              onShowResults: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Vote').first);
      expect(selectedVoter, 'host-player');
      expect(find.byType(CharacterCard), findsNothing);
      expect(find.textContaining('Guest is the'), findsNothing);
    },
  );

  testWidgets('shared-device results reveal secrets only in results', (
    tester,
  ) async {
    final resultsRound = phase2Round(phase: GamePhase.results).copyWith(
      character: const Character(
        id: 'character-1',
        name: 'Sherlock Holmes',
        emoji: 'detective',
        category: 'fictional',
        difficulty: 'easy',
        isActive: true,
      ),
      imposterPlayerId: 'guest-player',
      playerVotes: const {
        'host-player': 'guest-player',
        'guest-player': 'host-player',
      },
      submittedVoteCount: 2,
    );
    await tester.pumpWidget(
      harness(
        SingleChildScrollView(
          child: SharedDeviceResultsContent(
            state: GameLoaded(phase2GameState(round: resultsRound)),
            isTablet: false,
            isStartingNextRound: false,
            onFinishGame: () {},
            onStartNextRound: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('shared-device-results-content')),
      findsOneWidget,
    );
    expect(find.textContaining('Guest'), findsWidgets);
  });
}
