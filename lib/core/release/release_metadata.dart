import 'dart:io';

class ReleaseMetadataException implements Exception {
  const ReleaseMetadataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReleaseVersion {
  const ReleaseVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get baseVersion => '$major.$minor.$patch';
  String get semanticVersion => '$baseVersion+$build';

  String get tag => 'v$baseVersion';

  static ReleaseVersion parse(String value) {
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$',
    ).firstMatch(value.trim());
    if (match == null) {
      throw const ReleaseMetadataException(
        'pubspec version must use major.minor.patch+build.',
      );
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    final build = int.parse(match.group(4)!);
    if (build <= 0) {
      throw const ReleaseMetadataException('Build number must be positive.');
    }
    return ReleaseVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: build,
    );
  }
}

class ReleaseMetadataValidator {
  const ReleaseMetadataValidator();

  ReleaseVersion parsePubspecVersion(String pubspecText) {
    final match = RegExp(
      r'^version:\s*([^\s]+)\s*$',
      multiLine: true,
    ).firstMatch(pubspecText);
    if (match == null) {
      throw const ReleaseMetadataException('pubspec.yaml version is missing.');
    }
    return ReleaseVersion.parse(match.group(1)!);
  }

  ReleaseVersion parsePubspecFile(File file) {
    if (!file.existsSync()) {
      throw ReleaseMetadataException('pubspec file not found: ${file.path}');
    }
    return parsePubspecVersion(file.readAsStringSync());
  }

  void validateTagMatchesVersion({
    required String tag,
    required ReleaseVersion version,
  }) {
    final normalized = tag.trim();
    if (normalized != version.tag) {
      throw ReleaseMetadataException(
        'Git tag must match version ${version.tag}.',
      );
    }
  }
}
