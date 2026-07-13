import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/data/datasources/auth_api_client.dart';

void main() {
  test('Android, iOS, and local Supabase use the same auth callback', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final supabaseConfig = File('supabase/config.toml').readAsStringSync();

    expect(authCallbackUrl, 'io.supabase.guessparty://login-callback');
    expect(
      androidManifest,
      contains('android:scheme="io.supabase.guessparty"'),
    );
    expect(androidManifest, contains('android:host="login-callback"'));
    expect(iosInfo, contains('<string>io.supabase.guessparty</string>'));
    expect(supabaseConfig, contains(authCallbackUrl));
  });
}
