import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/data/datasources/auth_api_client.dart';
import 'package:guess_party/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  group('AuthRemoteDataSource', () {
    test('new registration keeps email separate from display name', () async {
      final api = FakeAuthApiClient();
      final source = AuthRemoteDataSourceImpl(authApi: api);

      final player = await source.signUpWithPassword(
        'PLAYER@EXAMPLE.COM',
        'PartyPlayer',
        'password123',
      );

      expect(api.lastEmail, 'player@example.com');
      expect(api.lastDisplayName, 'PartyPlayer');
      expect(player.username, 'PartyPlayer');
    });

    test(
      'legacy login preserves the synthetic-email compatibility path',
      () async {
        final api = FakeAuthApiClient();
        final source = AuthRemoteDataSourceImpl(authApi: api);

        await source.signInLegacyWithPassword('Old_Player', 'password123');

        expect(api.lastEmail, 'old_player@guessparty.com');
      },
    );

    test('legacy migration requires a previously authenticated user', () async {
      final source = AuthRemoteDataSourceImpl(authApi: FakeAuthApiClient());

      expect(
        () => source.beginAccountUpgrade('owner@example.com', 'Owner'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('sign in before upgrading'),
          ),
        ),
      );
    });

    test('legacy migration preserves the authenticated UID', () async {
      final api = FakeAuthApiClient(
        current: user(id: 'legacy-uid', email: 'legacy@guessparty.com'),
      );
      final source = AuthRemoteDataSourceImpl(authApi: api);

      final result = await source.beginAccountUpgrade(
        'owner@example.com',
        'Owner',
      );

      expect(result, 'legacy-uid');
      expect(api.currentUser?.id, 'legacy-uid');
    });

    test('guest upgrade preserves the anonymous UID', () async {
      final api = FakeAuthApiClient(
        current: user(id: 'guest-uid', isAnonymous: true),
      );
      final source = AuthRemoteDataSourceImpl(authApi: api);

      final result = await source.beginAccountUpgrade(
        'guest@example.com',
        'Guest Player',
      );

      expect(result, 'guest-uid');
      expect(api.currentUser?.id, 'guest-uid');
    });

    test('identity-changing upgrade is rejected instead of merged', () async {
      final api = FakeAuthApiClient(
        current: user(id: 'guest-uid', isAnonymous: true),
        updateResultId: 'different-uid',
      );
      final source = AuthRemoteDataSourceImpl(authApi: api);

      expect(
        () => source.beginAccountUpgrade('used@example.com', 'Guest'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('identity changed'),
          ),
        ),
      );
    });

    test(
      'duplicate global display names do not define account identity',
      () async {
        final api = FakeAuthApiClient();
        final source = AuthRemoteDataSourceImpl(authApi: api);

        final first = await source.signUpWithPassword(
          'one@example.com',
          'SameName',
          'password123',
        );
        final second = await source.signUpWithPassword(
          'two@example.com',
          'SameName',
          'password123',
        );

        expect(first.username, second.username);
        expect(first.userId, isNot(second.userId));
      },
    );

    test('account password cannot be set before email verification', () async {
      final api = FakeAuthApiClient(
        current: user(
          id: 'guest-uid',
          email: 'guest@example.com',
          isAnonymous: true,
        ),
      );
      final source = AuthRemoteDataSourceImpl(authApi: api);

      expect(
        () => source.setVerifiedAccountPassword('password123'),
        throwsA(isA<Exception>()),
      );
      expect(api.passwordUpdates, 0);
    });

    test('verified upgraded account can set its password', () async {
      final api = FakeAuthApiClient(
        current: user(
          id: 'guest-uid',
          email: 'guest@example.com',
          isEmailVerified: true,
        ),
      );
      final source = AuthRemoteDataSourceImpl(authApi: api);

      await source.setVerifiedAccountPassword('password123');

      expect(api.passwordUpdates, 1);
      expect(api.currentUser?.id, 'guest-uid');
    });
  });
}

AuthUserSnapshot user({
  required String id,
  String? email,
  String displayName = 'Player',
  bool isAnonymous = false,
  bool isEmailVerified = false,
}) => AuthUserSnapshot(
  id: id,
  email: email,
  displayName: displayName,
  isAnonymous: isAnonymous,
  isEmailVerified: isEmailVerified,
);

class FakeAuthApiClient implements AuthApiClient {
  FakeAuthApiClient({this.current, this.updateResultId});

  AuthUserSnapshot? current;
  final String? updateResultId;
  String? lastEmail;
  String? lastDisplayName;
  int passwordUpdates = 0;
  int _sequence = 0;

  @override
  AuthUserSnapshot? get currentUser => current;

  @override
  Future<AuthUserSnapshot> signInAnonymously(String displayName) async {
    current = user(
      id: 'anonymous-${++_sequence}',
      displayName: displayName,
      isAnonymous: true,
    );
    return current!;
  }

  @override
  Future<AuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    current = user(
      id: 'signed-in-${++_sequence}',
      email: email,
      displayName: email.split('@').first,
      isEmailVerified: true,
    );
    return current!;
  }

  @override
  Future<AuthUserSnapshot> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    lastEmail = email;
    lastDisplayName = displayName;
    current = user(
      id: 'registered-${++_sequence}',
      email: email,
      displayName: displayName,
      isEmailVerified: true,
    );
    return current!;
  }

  @override
  Future<AuthUserSnapshot> updateEmail({
    required String email,
    required String displayName,
  }) async {
    lastEmail = email;
    lastDisplayName = displayName;
    final existing = current!;
    current = user(
      id: updateResultId ?? existing.id,
      email: email,
      displayName: displayName,
      isAnonymous: existing.isAnonymous,
      isEmailVerified: existing.isEmailVerified,
    );
    return current!;
  }

  @override
  Future<AuthUserSnapshot> updatePassword(String password) async {
    passwordUpdates++;
    return current!;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    lastEmail = email;
  }
}
