# Flutter Client Handoff — Online/Local Gameplay Security

**Audience:** cheaper implementation LLM  
**Scope:** Flutter/Dart client only  
**Workflow:** direct implementation; do not use Spec Kit  
**Database status:** additive Supabase rollout is already applied and tested  
**Critical rule:** do not write, apply, edit, or suggest SQL. Do not modify Supabase objects. Database work is owned by the lead Codex session.

## 1. Mission

Migrate the Flutter client from client-authoritative gameplay and raw secret-bearing tables to the secure RPC and revision API already deployed in Supabase.

Preserve both flows:

```text
Online: create/join → waiting → start → hints → secret voting → results → next round/finish
Local: create roster → waiting → start → pass-device reveal → shared play → voting → results → next round/finish
```

Do not edit Dart outside this scope unless compilation proves it is required. Preserve unrelated working-tree changes.

## 2. What Is Already Live in Supabase

Project: `Guess Party game` (`bkpignyvtkqlicirpmmp`).

Applied migrations:

```text
20260710153558 gameplay_security_foundation_additive
20260710153703 gameplay_security_masked_reads
20260710195512 gameplay_security_atomic_commands
20260710195552 gameplay_security_write_policies_realtime
20260710195821 gameplay_security_advisor_remediation
20260711162224 gameplay_security_current_round_lookup
```

Live database behavior already provides:

- Immutable `round_participants` snapshots.
- Safe `round_revisions` Realtime events.
- Server-side imposter and character selection.
- Role-aware secret redaction.
- Local-only reveal bundle.
- Identity-aware secret ballots.
- Atomic room creation/join/start/phase/finalize/next/finish commands.
- Atomic +10/+20 scoring and finalization idempotency.
- Room-scoped Online stale-player cleanup; Local fake players are excluded.
- Host migration serialized with gameplay commands.
- Local host vote writes for fake Local players.

The database was transaction-tested for a complete Local lifecycle, next-round retry, caught-imposter scoring, and no-vote imposter scoring.

## 3. Compatibility State — Read Carefully

The database is intentionally in an additive compatibility stage because old app builds may still exist.

- Legacy raw `rounds` and `votes` access still exists temporarily.
- Legacy `rounds` and `votes` Realtime publications still exist temporarily.
- Legacy `get_round_for_player` still exists temporarily.
- New code must not use those legacy paths.
- Final privilege/publication enforcement will be applied by the lead Codex session only after the compatible client passes tests and is released or force-updated.

Do not claim the security rollout is complete merely because the client compiles. At the end, report that the client is ready for enforcement.

## 4. Locked Product Rules

Do not reinterpret these rules:

1. `players.is_host` is authoritative.
2. Online and Local behavior remain separate.
3. Both `imposter_player_id` and `character_id` are secrets.
4. Online imposter before results receives the imposter ID but no character.
5. Online innocent before results receives the character but no imposter ID.
6. General Local gameplay before results receives neither secret.
7. Only the dedicated Local reveal flow receives both Local secrets.
8. Results participants receive both secrets.
9. Online ballots are secret before results: caller vote plus aggregate progress only.
10. Local host may see all Local votes.
11. Every correct voter gets +10.
12. Imposter gets +20 unless uniquely most-voted. Tie/no-vote means escape.
13. Finalization and scoring happen only through `finalize_voting`.
14. The client never chooses an imposter/character and never writes scores.
15. A disconnected participant remains in the snapshot; Online readiness uses currently online snapshot participants.

## 5. Live RPC Contracts

Parameter names must match exactly.

### 5.1 Masked round snapshot

```text
RPC: get_round_for_player_v2
params: { p_round_id: uuid }
returns zero or one row:
  id: uuid
  room_id: uuid
  character_id: uuid|null
  round_number: int
  phase: hints|voting|results
  phase_end_time: timestamptz
  imposter_revealed: bool
  imposter_player_id: uuid|null
  created_at: timestamptz
  participant_ids: uuid[]
```

Zero rows means the authenticated caller is not a round participant. Fail closed.

Resolve the authoritative current round with:

```text
RPC: get_current_round_id
params: { p_room_id: uuid }
returns: uuid|null
```

### 5.2 Local reveal

```text
RPC: get_local_role_reveal_bundle
params: { p_round_id: uuid }
returns zero or one row:
  round_id: uuid
  character_id: uuid
  imposter_player_id: uuid
```

Only the current Local host can receive this row.

### 5.3 Vote state

```text
RPC: get_vote_state
params: { p_round_id: uuid }
returns json:
{
  "votes": { "voter-player-id": "target-player-id" },
  "submitted_count": 2,
  "required_count": 4,
  "all_required_submitted": false
}
```

Do not infer readiness from `votes.length`. In Online voting, `votes` normally contains only the caller's vote.

### 5.4 Room commands

```text
create_room(
  p_request_id uuid,
  p_category text,
  p_max_rounds int,
  p_max_players int,
  p_round_duration int,
  p_game_mode text,
  p_host_username text,
  p_local_names text[]
) -> json { room, players }

find_joinable_room(p_room_code text)
  -> json { room, online_count, available_slots }

join_room(p_room_code text, p_username text)
  -> json { room, player }
```

`p_local_names` excludes the host. Online must send `[]`.

Generate `p_request_id` once with `Uuid().v4()` for one create attempt and reuse it for retries until success/cancel. The database uses it for create idempotency.

### 5.5 Gameplay commands

```text
start_game(p_room_id uuid) -> first round uuid
advance_to_voting(p_round_id uuid) -> void
finalize_voting(p_round_id uuid, p_reason text) -> json
create_next_round(p_room_id uuid, p_expected_round_number int) -> round uuid
finish_game(p_room_id uuid) -> void
extend_local_role_reveal(p_round_id uuid, p_seconds int) -> void
mark_stale_players_offline(p_room_id uuid, p_stale_seconds int) -> int
```

Allowed finalization reasons:

```text
all_votes
timer
host_skip
```

Finalization response:

```json
{
  "round_id": "uuid",
  "phase": "results",
  "scores": { "player-id": 10 },
  "already_finalized": false
}
```

Stable database error messages include:

```text
AUTH_REQUIRED
ROOM_NOT_FOUND
ROUND_NOT_FOUND
HOST_REQUIRED
ROOM_FULL
ROOM_ALREADY_STARTED
NOT_ENOUGH_PLAYERS
WRONG_PHASE
VOTING_PHASE_REQUIRED
VOTES_INCOMPLETE
PREVIOUS_ROUND_NOT_FINALIZED
ROUND_PARTICIPANT_REQUIRED
```

Map these to current user-friendly errors; do not expose raw stack traces.

## 6. Required Dart Models

Create focused immutable models in the existing feature layers:

```text
LocalRoleRevealBundle
  roundId: String
  characterId: String
  imposterPlayerId: String

VoteState
  votes: Map<String, String>
  submittedCount: int
  requiredCount: int
  allRequiredSubmitted: bool

FinalizeVotingResult
  roundId: String
  phase: String
  scores: Map<String, int>
  alreadyFinalized: bool
```

Add matching data models with strict `fromJson` parsing.

Change `RoundInfo` and `RoundInfoModel`:

```dart
final String? imposterPlayerId;
final Character? character;
final int submittedVoteCount;
final int requiredVoteCount;

bool get hasVisibleImposter => imposterPlayerId != null;
bool get hasVisibleCharacter => character != null;
bool get allRequiredVotesSubmitted =>
    requiredVoteCount > 0 && submittedVoteCount >= requiredVoteCount;
```

Never replace a redacted secret with `''`, a fake UUID, or a fake `Character`.

If `copyWith` must support explicitly clearing a nullable field, use a private sentinel parameter; `value ?? oldValue` cannot represent "set to null".

## 7. Remote Data Source Changes

Primary file:

```text
lib/features/game/data/datasources/game_remote_data_source.dart
```

Add methods:

```dart
Future<Map<String, dynamic>> getRoundForPlayerV2({required String roundId});
Future<LocalRoleRevealBundleModel> getLocalRoleRevealBundle({required String roundId});
Future<VoteStateModel> getVoteState({required String roundId});
Future<FinalizeVotingResultModel> finalizeVoting({
  required String roundId,
  required String reason,
});
Future<void> advanceToVoting({required String roundId});
Future<String> createNextRoundCommand({
  required String roomId,
  required int expectedRoundNumber,
});
Future<void> finishGameCommand({required String roomId});
Future<void> extendLocalRoleReveal({
  required String roundId,
  required int seconds,
});
Stream<Map<String, dynamic>> watchRoundRevision({required String roundId});
```

RPC example:

```dart
final response = await client.rpc(
  'get_round_for_player_v2',
  params: {'p_round_id': roundId},
);

final rows = (response as List).cast<Map<String, dynamic>>();
if (rows.isEmpty) {
  throw StateError('ROUND_PARTICIPANT_REQUIRED');
}
return rows.single;
```

Build one complete round snapshot in this order:

1. Call `get_round_for_player_v2`.
2. Parse `participant_ids` from its response; do not query current players to invent the snapshot.
3. Fetch `Character` only if `character_id != null`.
4. Fetch room-scoped hints.
5. Call `get_vote_state`.
6. Build `RoundInfoModel` with masked secrets and aggregate vote counts.

Change the round event stream to:

```dart
return client
    .from('round_revisions')
    .stream(primaryKey: ['round_id'])
    .eq('round_id', roundId)
    .map((rows) {
      if (rows.isEmpty) throw StateError('ROUND_REVISION_NOT_VISIBLE');
      return rows.single;
    });
```

Keep the existing cancellation-aware `_watchWithRetry`, mapping every revision event to a fresh complete masked snapshot.

Delete supported-code usage of:

- `getRoundViaRpc` (legacy RPC).
- Raw `watchRoundChanges`.
- Raw `watchVotesChanges`.
- Client `updateRoundPhase`.
- Client `updatePhaseEndTime` for normal phase transitions.
- Client `updatePlayerScores`.
- Client `createRound`.
- Client `updateRoomStatus` for finish.

Direct vote upsert remains the write path:

```dart
await client.from('votes').upsert(
  {
    'round_id': roundId,
    'voter_player_id': voterId,
    'voted_player_id': votedPlayerId,
  },
  onConflict: 'round_id,voter_player_id',
);
```

The database validates identity, mode, phase, and snapshot membership.

## 8. Game Repository Changes

Primary files:

```text
lib/features/game/domain/repositories/game_repository.dart
lib/features/game/data/repositories/game_repository_impl.dart
```

Replace client-authoritative contracts with:

```dart
Future<Either<Failure, RoundInfo>> advanceToVoting({required String roundId});

Future<Either<Failure, FinalizeVotingResult>> finalizeVoting({
  required String roundId,
  required String reason,
});

Future<Either<Failure, RoundInfo>> createNextRound({
  required String roomId,
  required int expectedRoundNumber,
});

Future<Either<Failure, void>> finishGame({required String roomId});

Future<Either<Failure, LocalRoleRevealBundle>> getLocalRoleRevealBundle({
  required String roundId,
});
```

Remove after replacement is compiled and tested:

- `calculateScores` and all client scoring logic.
- `advancePhase(requestingPlayerId: ...)`.
- Client-side `Random()` imposter/character selection.
- Direct room/round secret reads.
- Best-effort score writes.
- Separate hints/votes Realtime subscriptions.

`createNextRound` must call the RPC, then load the returned round through the masked snapshot path. It must never construct secrets locally.

## 9. Game Use Cases and Dependency Injection

Create or replace use cases under:

```text
lib/features/game/domain/usecases/finalize_voting.dart
lib/features/game/domain/usecases/advance_to_voting.dart
lib/features/game/domain/usecases/create_next_round.dart
lib/features/game/domain/usecases/finish_game.dart
lib/features/game/domain/usecases/get_local_role_reveal_bundle.dart
```

Update:

```text
lib/core/di/injection_container.dart
```

Register new use cases and a dedicated Local reveal Cubit/controller as factories. Remove old registrations only after no production reference remains.

## 10. Game Cubit Changes

Primary file:

```text
lib/features/game/presentation/cubit/game_cubit.dart
```

Required behavior:

- Keep only `_roundSubscription` and `_playersSubscription`.
- Remove `_hintsSubscription` and `_votesSubscription` after the revision snapshot stream works.
- Cancel and await old subscriptions before replacing them.
- On resume, perform one authoritative reload, then replace streams.
- Clear the old round subscription before subscribing to a new round.
- Add a per-round in-flight finalization guard.
- Host `all_votes`, timer, and skip paths all call `finalizeVoting` with different reasons.
- Apply scores returned by `finalize_voting`; never calculate or increment locally.
- Wait for/reload the masked results snapshot after finalization.
- `createNewRound` calls `create_next_round` with `currentRound + 1`.
- `finishGame` calls `finish_game`.
- If identity or a required visible secret is temporarily missing, show syncing state and fail closed.

Suggested finalization guard:

```dart
final Set<String> _finalizingRoundIds = <String>{};

Future<void> finalizeVoting(String roundId, String reason) async {
  if (!_finalizingRoundIds.add(roundId)) return;
  try {
    // Call one repository command, apply returned scores, reload snapshot.
  } finally {
    _finalizingRoundIds.remove(roundId);
  }
}
```

Delete `_scoredRoundIds`, `_lastKnownScores`, and old calculation code after focused tests prove the server result path.

## 11. Local Reveal Isolation

Primary file:

```text
lib/features/game/presentation/views/local_role_reveal_view.dart
```

Do not instantiate the general `GameCubit` to retrieve Local secrets.

Create a small dedicated reveal Cubit/controller that:

1. Calls `get_local_role_reveal_bundle` once.
2. Loads the immutable participant/player display list.
3. Drives the pass-device reveal sequence.
4. Holds both secrets only in reveal state.
5. Clears/closes reveal state before navigating to shared Local gameplay.

The shared Local game then loads `get_round_for_player_v2`, where both secrets are null until results. This is intentional.

If reveal time needs extension, call `extend_local_role_reveal`; never update `rounds.phase_end_time` directly.

After any await before navigation/snackbar/dialog work, check `context.mounted` or the owning `State.mounted`.

## 12. Online and Local UI Guards

Update role/character/result widgets:

- Online imposter UI must build when `character == null`.
- Online innocent UI must build when `imposterPlayerId == null`.
- Shared Local gameplay must build with both values null.
- Results render only when both values are non-null; otherwise show a short syncing state and refresh.
- Never force unwrap before these guards.

Update voting UI:

```text
lib/features/game/presentation/views/widgets/voting_phase_content.dart
```

- Show `submittedVoteCount / requiredVoteCount`.
- Use `allRequiredVotesSubmitted` for readiness.
- Do not display target counts before Online results.
- Online `playerVotes` before results contains only the caller vote.
- Host auto-finalizes only on a false → true readiness transition.
- A repeated revision must not trigger repeated finalization.

## 13. Room Client Migration

Primary files:

```text
lib/features/room/data/datasources/room_remote_data_source.dart
lib/features/room/data/repositories/room_repository_impl.dart
lib/features/room/domain/repositories/room_repository.dart
lib/features/room/presentation/cubit/room_cubit.dart
lib/features/room/presentation/views/waiting_room_view.dart
```

Replace multi-step room mutations:

- `createRoom` calls `create_room` and returns room plus complete roster.
- Do not call `_addLocalPlayers` after secure create; Local roster is already atomic.
- Online create sends `p_local_names: []`.
- Local create sends host name separately and remaining names in `p_local_names`.
- `joinRoom` calls `join_room`; optional validation uses `find_joinable_room`.
- `startGame` calls `start_game` and receives the first round ID.
- Stale cleanup calls the room-scoped overload with both parameters.
- Do not use the legacy one-parameter stale cleanup overload.

Remove any fallback equivalent to:

```dart
currentPlayer ??= players.first;
```

If the authenticated player's row is not resolved, show syncing state. Never perform heartbeat, leave, host action, or navigation under another player's identity.

## 14. Exact Room RPC Parameter Maps

```dart
await client.rpc('create_room', params: {
  'p_request_id': requestId,
  'p_category': category,
  'p_max_rounds': maxRounds,
  'p_max_players': maxPlayers,
  'p_round_duration': roundDuration,
  'p_game_mode': gameMode,
  'p_host_username': hostUsername,
  'p_local_names': localNamesWithoutHost,
});

await client.rpc('join_room', params: {
  'p_room_code': roomCode,
  'p_username': username,
});

await client.rpc('start_game', params: {
  'p_room_id': roomId,
});

await client.rpc('mark_stale_players_offline', params: {
  'p_room_id': roomId,
  'p_stale_seconds': staleSeconds,
});
```

Parse `create_room` as `{room: Map, players: List}` and `join_room` as `{room: Map, player: Map}`.

## 15. Work Packages — One at a Time

Do not implement the whole handoff in one uncontrolled edit.

| Package | Scope | Required gate |
|---|---|---|
| C-01 | Nullable/redaction entities and data models | Model tests pass |
| C-02 | Masked round/vote/reveal data-source methods | Data-source tests pass |
| C-03 | Repository commands; delete client secrets/scoring | Repository tests pass |
| C-04 | Revision-only snapshot stream | Stream retry/cancel tests pass |
| C-05 | Game use cases, DI, Cubit finalization | Cubit tests pass |
| C-06 | Dedicated Local reveal flow | Local reveal widget tests pass |
| C-07 | Room create/join/start/cleanup migration | Room tests pass |
| C-08 | Online/Local UI guards and vote progress | Widget tests pass |
| C-09 | Full static/analyze/test verification | All gates pass |

At the end of every package, report:

```text
Files changed:
Behavior changed:
Security invariant covered:
Tests run and exact result:
Skipped verification:
Next package safe: yes/no
```

## 16. Required Tests

Use `flutter_test` and manual fakes. Do not add a mocking dependency unless unavoidable.

Create focused tests such as:

```text
test/features/game/data/models/round_info_model_redaction_test.dart
test/features/game/data/repositories/game_repository_snapshot_test.dart
test/features/game/presentation/cubit/game_cubit_finalize_test.dart
test/features/game/presentation/views/local_role_reveal_view_test.dart
test/features/room/data/repositories/room_repository_commands_test.dart
test/features/room/presentation/cubit/room_cubit_identity_test.dart
```

Minimum cases:

1. Null secrets remain null.
2. Online imposter snapshot works without character.
3. Online innocent snapshot works without imposter ID.
4. Local shared snapshot works with both null.
5. Results require and parse both secrets.
6. Vote progress uses submitted/required counts, not map length.
7. Duplicate finalization events call repository once.
8. Finalization response replaces scores; it does not add again.
9. Revision event produces one complete snapshot refresh.
10. Stream cancellation prevents retry/resubscribe.
11. Local reveal bundle is cleared before shared navigation.
12. Room create sends one stable request UUID across retries.
13. Local roster is not inserted a second time client-side.
14. Waiting room never selects `players.first` for missing identity.
15. Stale cleanup includes `roomId`.

## 17. Verification Commands

Run from the repository root:

```powershell
dart format lib test
flutter analyze
flutter test
```

Then run static checks:

```powershell
rg -n "get_round_for_player'|watchRoundChanges|watchVotesChanges" lib
rg -n "from\('rounds'\).*select\(\)|from\('rounds'\).*select\('\*'\)" lib
rg -n "imposterPlayerId.*\?\? ''|imposter_player_id.*\?\? ''" lib
rg -n "Random\(\)|nextInt" lib\features\game\data
rg -n "calculateScores|updatePlayerScores|createRound\(" lib\features\game
rg -n "while \(true\)" lib\features\game lib\features\room
rg -n "service_role|SUPABASE_SERVICE" lib assets
```

Expected:

- No legacy round RPC in supported code.
- No raw round/vote Realtime watcher.
- No raw secret-bearing `rounds` read.
- No secret sentinel fallback.
- No client Online secret selection.
- No client score calculation/write.
- No unbounded retry loop.
- No service secret in Flutter.

`Random()` used only for non-authoritative UI is acceptable; any gameplay imposter/character use is forbidden.

## 18. Manual Matrix

After automated tests pass, report that these require device verification:

### Local

- Four-player room creation produces exactly four players.
- Every player sees one reveal; exactly one is imposter.
- Shared gameplay no longer retains reveal secrets.
- All Local players can vote through the host device.
- All-votes, timer, and skip finalization score once.
- Next round works after finalized results.

### Online with three or more clients

- Host, innocent, imposter, and outsider identities are distinct.
- Imposter never receives character before results.
- Innocent never receives imposter ID before results.
- One client cannot vote as another.
- Live target totals are hidden before results.
- Disconnect changes required vote count without changing the snapshot.
- Host migration cannot double-finalize or double-create a round.
- Every client reacts to safe revision/player streams.

## 19. STOP Conditions

Stop immediately and report evidence if:

- An RPC name, parameter, or response differs from this document.
- The proposed fix needs SQL/Supabase changes.
- A supported path still requires raw `rounds`/`votes` secrets.
- Local shared gameplay requires storing the reveal bundle.
- A UI path cannot safely render a redacted secret.
- Finalization can be invoked twice for one event.
- Tests reveal a gameplay rule different from the locked +10/+20/tie behavior.
- Unrelated user changes overlap and cannot be preserved.

Do not work around a database contract mismatch. The lead Codex session owns database corrections.

## 20. Completion Handoff

When all client packages pass, provide:

```text
CLIENT READY FOR DATABASE ENFORCEMENT

Files changed:
Tests and analyzer results:
Manual cases completed:
Manual cases still pending:
Legacy raw round reads remaining: none/list
Legacy raw vote reads remaining: none/list
Legacy raw Realtime subscriptions remaining: none/list
Known blockers:
```

Do not apply final database enforcement. Return control to the user so the connected lead Codex session can revoke legacy privileges and remove raw Realtime publications safely.
