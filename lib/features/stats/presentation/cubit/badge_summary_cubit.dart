import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';

/// Read-only trophy count for Home. State is `null` while unknown.
///
/// Shows the cached value first, then refreshes from the server in the
/// background. It deliberately has no access to `SeenBadgesStore`.
class BadgeSummaryCubit extends Cubit<BadgeSummary?> {
  BadgeSummaryCubit({
    required StatsRepository repository,
    required BadgeSummaryStore store,
    required String userId,
  }) : _repository = repository,
       _store = store,
       _userId = userId,
       super(null);

  final StatsRepository _repository;
  final BadgeSummaryStore _store;
  final String _userId;

  Future<void> load() async {
    if (isClosed || _userId.isEmpty) return;

    try {
      final cached = await _store.read(_userId);
      if (isClosed) return;
      if (cached != null && state == null) emit(cached);
    } catch (_) {
      // A broken cache just means we wait for the server.
    }

    final result = await _repository.getMyStats();
    if (isClosed) return;

    final stats = result.fold((_) => null, (stats) => stats);
    if (stats == null) return; // Keep whatever we already show.

    final summary = BadgeSummary.fromStats(stats);
    emit(summary);
    try {
      await _store.write(_userId, summary);
    } catch (_) {
      // Caching is best effort.
    }
  }

  /// Forgets the cached value of this user (call on logout).
  Future<void> clear() async {
    if (!isClosed) emit(null);
    try {
      await _store.clear(_userId);
    } catch (_) {
      // Best effort.
    }
  }
}
