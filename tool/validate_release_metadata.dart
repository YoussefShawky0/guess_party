import 'dart:io';

import 'package:guess_party/core/release/release_metadata.dart';

void main(List<String> args) {
  String? pubspecPath;
  String? tag;
  var requireBuild = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--pubspec' && i + 1 < args.length) {
      pubspecPath = args[++i];
    } else if (arg == '--tag' && i + 1 < args.length) {
      tag = args[++i];
    } else if (arg == '--require-build') {
      requireBuild = true;
    }
  }

  if (pubspecPath == null) {
    stderr.writeln(
      'Usage: dart run tool/validate_release_metadata.dart --pubspec <pubspec.yaml> [--tag <vX.Y.Z>] [--require-build]',
    );
    exitCode = 64;
    return;
  }

  try {
    final validator = ReleaseMetadataValidator();
    final version = validator.parsePubspecFile(File(pubspecPath));
    if (requireBuild && version.build <= 0) {
      throw const ReleaseMetadataException('Build number must be positive.');
    }
    if (tag != null) {
      validator.validateTagMatchesVersion(tag: tag, version: version);
    }
    stdout.writeln('Release metadata is valid.');
  } on ReleaseMetadataException catch (error) {
    stderr.writeln('Invalid release metadata: ${error.message}');
    exitCode = 78;
  }
}
