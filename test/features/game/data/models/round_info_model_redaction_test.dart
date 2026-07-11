import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/data/models/finalize_voting_result_model.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/game/data/models/vote_state_model.dart';

void main() {
  const roundJson = <String, dynamic>{
    'id': 'round-1',
    'room_id': 'room-1',
    'imposter_player_id': null,
    'round_number': 1,
    'phase': 'voting',
    'phase_end_time': '2026-07-10T10:00:00+00:00',
    'imposter_revealed': false,
  };

  test('preserves redacted secrets as null', () {
    final model = RoundInfoModel.fromJson(
      roundJson,
      null,
      const ['player-1', 'player-2'],
      const {},
      const {'player-1': 'player-2'},
      submittedVoteCount: 1,
      requiredVoteCount: 2,
    );

    expect(model.imposterPlayerId, isNull);
    expect(model.character, isNull);
    expect(model.hasVisibleImposter, isFalse);
    expect(model.hasVisibleCharacter, isFalse);
    expect(model.submittedVoteCount, 1);
    expect(model.requiredVoteCount, 2);
    expect(model.allRequiredVotesSubmitted, isFalse);
  });

  test('copyWith can explicitly clear nullable secrets', () {
    final model = RoundInfoModel.fromJson(
      {...roundJson, 'imposter_player_id': 'player-2'},
      null,
      const ['player-1', 'player-2'],
      const {},
      const {},
    );

    final cleared = model.copyWith(imposterPlayerId: null, character: null);

    expect(cleared.imposterPlayerId, isNull);
    expect(cleared.character, isNull);
  });

  test('parses identity-aware vote progress', () {
    final model = VoteStateModel.fromJson(const {
      'votes': {'player-1': 'player-2'},
      'submitted_count': 3,
      'required_count': 3,
      'all_required_submitted': true,
    });

    expect(model.votes, const {'player-1': 'player-2'});
    expect(model.allRequiredSubmitted, isTrue);
  });

  test('parses atomic finalization scores as integers', () {
    final model = FinalizeVotingResultModel.fromJson(const {
      'round_id': 'round-1',
      'phase': 'results',
      'scores': {'player-1': 10, 'player-2': 20.0},
      'already_finalized': false,
    });

    expect(model.scores, const {'player-1': 10, 'player-2': 20});
    expect(model.alreadyFinalized, isFalse);
  });
}
