import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const applicationId = 'com.youssefshawky.guessparty';

  test('Android uses the approved permanent application identity', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/youssefshawky/guessparty/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('namespace = "$applicationId"'));
    expect(gradle, contains('applicationId = "$applicationId"'));
    expect(gradle, isNot(contains('com.example.guess_party')));
    expect(activity, contains('package $applicationId'));
  });

  test('iOS uses the approved permanent bundle identity', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = $applicationId;'));
    expect(project, isNot(contains('com.example.guessParty')));
  });

  test('local Android signing properties cannot be committed', () {
    final ignore = File('.gitignore').readAsStringSync();
    expect(ignore, contains('/android/key.properties'));
  });
}
