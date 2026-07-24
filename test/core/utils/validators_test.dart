import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/utils/validators.dart';

void main() {
  group('Validators.username', () {
    test('accepts Arabic letters and Arabic-Indic numbers', () {
      expect(Validators.username('محمد'), isNull);
      expect(Validators.username('لاعب١٢٣'), isNull);
    });

    test('accepts Arabic combining marks', () {
      expect(Validators.username('مُحَمَّد'), isNull);
    });

    test('rejects usernames made only from combining marks', () {
      expect(
        Validators.username('\u064E\u064F'),
        'Username must contain at least one letter or number',
      );
    });

    test('keeps existing Latin, number, and underscore support', () {
      expect(Validators.username('Player_123'), isNull);
    });

    test('continues to reject spaces, punctuation, and emoji', () {
      expect(Validators.username('محمد علي'), isNotNull);
      expect(Validators.username('محمد!'), isNotNull);
      expect(Validators.username('محمد🎉'), isNotNull);
    });

    test('continues to enforce the two-to-twenty character boundary', () {
      expect(Validators.username('م'), isNotNull);
      expect(Validators.username('محمودمحمودمحمودمحمودم'), isNotNull);
    });
  });
}
