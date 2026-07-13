import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('AuthRepositoryImpl password recovery', () {
    test('rejects password updates outside a recovery session', () async {
      final remote = FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        authSessionService: FakeAuthSessionService(),
      );

      final result = await repository.updateRecoveredPassword('password123');

      expect(result.isLeft(), isTrue);
      expect(remote.recoveredPasswordUpdates, 0);
    });

    test('updates password once and consumes the recovery session', () async {
      final remote = FakeAuthRemoteDataSource();
      final session = FakeAuthSessionService(hasRecoverySession: true);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        authSessionService: session,
      );

      final result = await repository.updateRecoveredPassword('password123');

      expect(result.isRight(), isTrue);
      expect(remote.recoveredPasswordUpdates, 1);
      expect(session.hasPasswordRecoverySession, isFalse);
    });
  });
}

class FakeAuthSessionService implements AuthSessionService {
  FakeAuthSessionService({bool hasRecoverySession = false})
    : _hasRecoverySession = hasRecoverySession;

  bool _hasRecoverySession;

  @override
  bool get hasPasswordRecoverySession => _hasRecoverySession;
  @override
  void consumePasswordRecoverySession() => _hasRecoverySession = false;
  @override
  Stream<AuthLifecycleEvent> get lifecycleEvents => const Stream.empty();
  @override
  bool get isAnonymous => false;
  @override
  bool get isEmailVerified => false;
  @override
  bool get isLegacyAccount => false;
  @override
  String? get currentEmail => null;
  @override
  String? get currentUserId => null;
  @override
  String get currentUsername => 'Player';
  @override
  Stream<String?> get userIdChanges => const Stream.empty();
  @override
  Future<void> signOut() async {}
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  int recoveredPasswordUpdates = 0;

  @override
  Future<void> updateRecoveredPassword(String password) async {
    recoveredPasswordUpdates++;
  }

  @override
  Future<String> beginAccountUpgrade(String email, String displayName) =>
      throw UnimplementedError();
  @override
  Future<String> getCurrentUserId() => throw UnimplementedError();
  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();
  @override
  Future<void> setVerifiedAccountPassword(String password) =>
      throw UnimplementedError();
  @override
  Future<PlayerModel> signInAsGuest(String username) =>
      throw UnimplementedError();
  @override
  Future<PlayerModel> signInLegacyWithPassword(
    String username,
    String password,
  ) => throw UnimplementedError();
  @override
  Future<PlayerModel> signInWithPassword(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<PlayerModel> signUpWithPassword(
    String email,
    String displayName,
    String password,
  ) => throw UnimplementedError();
}
