import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/release/release_metadata.dart';

void main() {
  const validator = ReleaseMetadataValidator();

  group('ReleaseMetadataValidator', () {
    test('parses semver plus build metadata from pubspec text', () {
      final version = validator.parsePubspecVersion('version: 1.2.3+45\n');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.build, 45);
      expect(version.baseVersion, '1.2.3');
      expect(version.semanticVersion, '1.2.3+45');
      expect(version.tag, 'v1.2.3');
    });

    test('rejects missing build metadata', () {
      expect(
        () => validator.parsePubspecVersion('version: 1.2.3\n'),
        throwsA(isA<ReleaseMetadataException>()),
      );
    });

    test('rejects mismatched git tags', () {
      final version = ReleaseVersion.parse('1.2.3+45');

      expect(
        () => validator.validateTagMatchesVersion(
          tag: 'v1.2.4',
          version: version,
        ),
        throwsA(isA<ReleaseMetadataException>()),
      );
    });
  });
}
