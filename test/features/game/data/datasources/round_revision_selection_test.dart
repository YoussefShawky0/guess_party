import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';

void main() {
  group('selectRoundRevisionRow', () {
    test('returns the single matching row', () {
      final row = {'round_id': 'r1', 'revision': 1};
      expect(selectRoundRevisionRow([row], 'r1'), row);
    });

    test('picks the watched round when several rounds are emitted', () {
      final r1 = {'round_id': 'r1', 'revision': 3};
      final r2 = {'round_id': 'r2', 'revision': 5};
      expect(selectRoundRevisionRow([r1, r2], 'r2'), r2);
      expect(selectRoundRevisionRow([r1, r2], 'r1'), r1);
    });

    test('throws ROUND_REVISION_NOT_VISIBLE when empty or no match', () {
      expect(
        () => selectRoundRevisionRow([], 'r1'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => selectRoundRevisionRow([
          {'round_id': 'r2'},
        ], 'r1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
