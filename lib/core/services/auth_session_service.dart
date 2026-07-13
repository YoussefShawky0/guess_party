import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthSessionService {
  String? get currentUserId;
  String get currentUsername;
  Stream<String?> get userIdChanges;
}

class SupabaseAuthSessionService implements AuthSessionService {
  SupabaseAuthSessionService(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String get currentUsername =>
      _client.auth.currentUser?.userMetadata?['username'] as String? ?? 'Guest';

  @override
  Stream<String?> get userIdChanges => _client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
}
