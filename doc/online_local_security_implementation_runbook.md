# Online and Local Gameplay Security — Implementation Runbook

**Audience:** cost-optimized coding LLM or junior implementer  
**Authority:** this runbook is the execution guide; architecture rationale remains in `doc/local_mode_security_remediation_plan.md`  
**Workflow:** direct implementation, no Spec Kit  
**Rule:** complete tasks in order and stop at every gate

## 1. Mission

Implement the Online/Local gameplay security remediation without breaking the existing round loop:

```text
Create/Join → Start → Role/Character Reveal → Hints → Voting → Results → Next Round → Finish
```

The finished system must satisfy all of these:

- Online state and authorization are authoritative in Supabase.
- Online clients cannot vote as another player.
- Online host clients never choose or receive raw round secrets unless their role/results authorizes it.
- Online imposters do not receive the selected character before results.
- Local role reveal works for exactly one imposter and all Local votes succeed.
- Local shared gameplay state does not retain reveal secrets.
- Round creation, phase commands, scoring, and next-round creation are idempotent.
- Host migration races cannot double-score or double-create rounds.
- Realtime sends safe revision events, never raw round/vote secrets.
- Old clients are not broken until the explicit enforcement deployment.

## 2. Locked Decisions — Do Not Reinterpret

1. `players.is_host` is the host authority. Do not authorize with a client boolean or only `rooms.host_id`.
2. Both `rounds.imposter_player_id` and the selected `rounds.character_id` are secrets.
3. Online ballots are secret during voting:
   - Caller sees their own vote.
   - Everyone in the room may see submitted/required counts.
   - Full voter→target data becomes visible in results.
   - Local host sees all Local votes because one device conducts the sequence.
4. Scoring rules:
   - Each voter targeting the imposter gets +10.
   - Imposter gets +20 unless uniquely most-voted.
   - Ties and no-vote results mean the imposter escapes.
5. The imposter is never reassigned after round creation, including disconnect.
6. A round participant snapshot is immutable.
7. Local fake players are never processed by stale Online presence cleanup.
8. Voting→results and scoring are one atomic `finalize_voting` command.
9. Use a versioned v2 read RPC. Do not break the legacy RPC before minimum-version enforcement.
10. Use one safe `round_revisions` stream to refresh round, hint, and vote snapshot state. Keep a separate players/presence stream.

## 3. Forbidden Shortcuts

The implementation model must not:

- Add `getRoundDirect` or any client-side Local bypass.
- Put `service_role`/secret keys in Flutter.
- Trust `isLocalMode`, `isHost`, `requestingPlayerId`, scores, or secrets supplied by the client for authorization.
- Leave `SELECT *` or implicit `.select()` on `rounds` in supported client code.
- Generate an Online imposter or selected character with Dart `Random()`.
- Expose `rounds` or `votes` raw Realtime payloads after enforcement.
- Use `SECURITY DEFINER` without explicit caller checks, fixed search path, and revoked default EXECUTE.
- Prove RLS using SQL Editor superuser queries.
- Apply destructive schema changes before capturing deployed definitions.
- Continue after a STOP condition.
- Change gameplay scoring values or tie rules.

## 4. Best-Case Path and Fallbacks

### 4.1 Best-case assumptions

- Supabase CLI or authenticated Supabase MCP is available.
- The live schema mostly matches `doc/schemas/supabase_schema.sql`.
- `rooms.game_mode` already exists with values `online`/`local`.
- The legacy `get_round_for_player(uuid)` signature matches the app.
- A compatible mobile release can be deployed before privilege enforcement.
- Existing data contains no invalid room modes or duplicate `(room_id, user_id)` rows.

If every assumption is true, follow Sections 7–11 exactly.

### 4.2 Fallback rules

- **No DB connection:** implement and test Dart plus canonical SQL files, but stop before claiming database completion.
- **Schema drift:** save the actual definition, add a reconciliation migration, and rerun diagnostics. Never overwrite blindly.
- **Duplicate identities:** create a data-cleanup report and STOP; do not choose rows to delete automatically.
- **RPC signature differs:** create a new v2 function. Do not drop an unknown overload.
- **Old mobile versions remain active:** deploy additive objects/client first; defer grants/publication revocation.
- **Migration fails twice for the same reason:** stop, inspect the exact database error and live object definition, then revise the migration once.

## 5. Tools and Commands

Use these utilities:

```powershell
# Fast repository search
rg -n "pattern" lib test doc
rg --files lib test doc

# Flutter verification
dart format lib test
flutter analyze
flutter test

# Supabase command discovery — do not guess CLI syntax
supabase --help
supabase migration --help
supabase db --help
supabase --version
```

Preferred database workflow:

1. Supabase MCP `execute_sql` for diagnostics/iteration and `get_advisors` for final checks.
2. Otherwise a configured Supabase CLI.
3. If neither exists, save canonical SQL files only and report database execution as blocked.

When CLI migration support is configured, create migration files with:

```powershell
supabase migration new gameplay_security_additive
supabase migration new gameplay_security_enforcement
```

Do not invent timestamped migration names manually.

## 6. Files the Implementer Must Read First

Read these completely before editing:

- `AGENTS.md`
- `.specify/memory/constitution.md`
- `doc/local_mode_security_remediation_plan.md`
- `lib/features/game/data/datasources/game_remote_data_source.dart`
- `lib/features/game/data/repositories/game_repository_impl.dart`
- `lib/features/game/domain/repositories/game_repository.dart`
- `lib/features/game/domain/entities/round_info.dart`
- `lib/features/game/data/models/round_info_model.dart`
- `lib/features/game/presentation/cubit/game_cubit.dart`
- `lib/features/game/presentation/views/game_view.dart`
- `lib/features/game/presentation/views/local_mode_game_screen.dart`
- `lib/features/game/presentation/views/local_role_reveal_view.dart`
- `lib/features/game/presentation/views/widgets/voting_phase_content.dart`
- `lib/features/room/data/datasources/room_remote_data_source.dart`
- `lib/features/room/data/repositories/room_repository_impl.dart`
- `lib/features/room/domain/repositories/room_repository.dart`
- `lib/features/room/presentation/cubit/room_cubit.dart`
- `lib/features/room/presentation/views/waiting_room_view.dart`
- `lib/features/game/presentation/views/game_view.dart`
- `doc/schemas/supabase_schema.sql`
- `doc/schemas/fix_host_migration_and_room_cleanup.sql`

## 7. Phase A — Diagnostics and Canonical Contracts

### A01. Capture database definitions

Run and save results for:

```sql
select policyname, schemaname, tablename, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('rooms','players','rounds','hints','votes');

select pg_get_functiondef(p.oid) as definition,
       p.proname,
       pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as result,
       p.prosecdef,
       p.proacl,
       r.rolname as owner
from pg_proc p
join pg_roles r on r.oid = p.proowner
where p.proname in (
  'get_round_for_player',
  'create_first_round',
  'reconcile_room_after_presence_change',
  'mark_stale_players_offline'
);

select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('rooms','players','rounds','hints','votes')
order by table_name, ordinal_position;

select conrelid::regclass as table_name, conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid in (
  'public.rooms'::regclass,
  'public.players'::regclass,
  'public.rounds'::regclass,
  'public.votes'::regclass
);

select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon','authenticated');

select * from pg_publication_tables
where pubname = 'supabase_realtime';
```

Also query duplicate identities:

```sql
select room_id, user_id, count(*)
from public.players
group by room_id, user_id
having count(*) > 1;
```

**STOP:** if duplicates exist, return the rows/counts to the user and request a cleanup decision.

### A02. Create canonical SQL files

Create these files; each begins with purpose, dependencies, rollback, and verification queries:

```text
doc/schemas/01_gameplay_security_schema.sql
doc/schemas/02_gameplay_security_reads.sql
doc/schemas/03_gameplay_security_commands.sql
doc/schemas/04_gameplay_security_rls.sql
doc/schemas/05_gameplay_security_realtime.sql
doc/schemas/06_gameplay_security_enforcement.sql
doc/schemas/07_gameplay_security_rollback.sql
doc/schemas/08_gameplay_security_tests.sql
```

Do not edit old contradictory scripts into another “final” version. The eight files above become canonical; old scripts receive a header saying they are superseded after rollout.

**Gate A:** diagnostics captured, no unresolved duplicate identities, and canonical file skeletons exist.

## 8. Phase B — Additive Database Layer

Do not revoke old privileges or remove publications in this phase.

### B01. Schema reconciliation

In `01_gameplay_security_schema.sql`, implement:

```sql
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter table public.rooms
  add column if not exists game_mode text;

update public.rooms
set game_mode = 'online'
where game_mode is null;

alter table public.rooms
  alter column game_mode set default 'online',
  alter column game_mode set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.rooms'::regclass
      and conname = 'rooms_game_mode_check'
  ) then
    alter table public.rooms
      add constraint rooms_game_mode_check
      check (game_mode in ('online','local')) not valid;
  end if;
end $$;

alter table public.rooms
  validate constraint rooms_game_mode_check;

alter table public.rounds
  add column if not exists scores_finalized_at timestamptz;

create table if not exists public.round_participants (
  round_id uuid not null references public.rounds(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (round_id, player_id)
);

create table if not exists public.round_revisions (
  round_id uuid primary key references public.rounds(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);

create index if not exists idx_players_room_user
  on public.players(room_id, user_id);
create index if not exists idx_round_participants_player
  on public.round_participants(player_id, round_id);
create index if not exists idx_round_revisions_room
  on public.round_revisions(room_id, round_id);
```

For production tables with significant rows, create the new indexes concurrently outside a transaction. Backfill/validate invalid `game_mode` values before NOT NULL/CHECK.

Add `BEFORE UPDATE OF game_mode` trigger using a `SECURITY INVOKER` trigger function with `SET search_path = ''`.

### B02. Shared private utilities

In `03_gameplay_security_commands.sql`, create private helpers:

```text
private.lock_room(room_id uuid) returns void
private.is_room_member(room_id uuid, user_id uuid) returns boolean
private.is_current_host(room_id uuid, user_id uuid) returns boolean
private.bump_round_revision(round_id uuid) returns void
private.create_round_for_room(room_id uuid, round_number integer) returns uuid
```

Implementation requirements:

- `lock_room` uses one transaction-scoped per-room lock strategy consistently across game commands and host migration.
- `is_current_host` requires matching `players.user_id`, `players.is_host = true`, and current Online status for Online rooms.
- All helpers use schema-qualified names and `SET search_path = ''`.
- Trigger-only helpers have EXECUTE revoked from `PUBLIC`, `anon`, and `authenticated`.
- `create_round_for_room` locks room, validates state, snapshots participants, selects imposter/character server-side, inserts round + participants, updates `rooms.current_round`/used characters, and returns only round ID.
- Online participants are online room players; Local participants are all Local room player rows.
- Require at least `GameConstants.minPlayers` equivalent in SQL (currently 2).
- Unique `(room_id, round_number)` makes retry idempotent.

### B03. Safe revision triggers

Create triggers that call `private.bump_round_revision` after:

- `rounds` INSERT/UPDATE
- `hints` INSERT/UPDATE/DELETE
- `votes` INSERT/UPDATE/DELETE

The revision payload contains only round ID, room ID, revision, and timestamp.

Backfill one `round_revisions` row for every existing round.

### B04. Versioned read RPCs

In `02_gameplay_security_reads.sql`, implement these exact public contracts:

```sql
public.get_round_for_player_v2(p_round_id uuid)
returns table (
  id uuid,
  room_id uuid,
  character_id uuid,          -- nullable/redacted
  round_number integer,
  phase text,
  phase_end_time timestamptz,
  imposter_revealed boolean,
  imposter_player_id uuid,    -- nullable/redacted
  created_at timestamptz,
  participant_ids uuid[]
)

public.get_local_role_reveal_bundle(p_round_id uuid)
returns table (
  round_id uuid,
  character_id uuid,
  imposter_player_id uuid
)

public.get_vote_state(p_round_id uuid)
returns jsonb
```

Visibility logic for `get_round_for_player_v2`:

```text
not a round participant                → no row
results participant                    → both secrets
online imposter                        → imposter ID, character NULL
online non-imposter participant        → character ID, imposter NULL
local general gameplay before results  → both NULL
```

`get_local_role_reveal_bundle` requires Local mode + current host + participant membership and returns both secrets.

`get_vote_state` returns this shape:

```json
{
  "votes": {"voter-player-id": "target-player-id"},
  "submitted_count": 2,
  "required_count": 3,
  "all_required_submitted": false
}
```

Before results:

- Online `votes` contains only the caller's vote.
- Local current host receives all Local votes.
- Counts use currently online Online round participants or every Local participant.

During results, every participant receives all round votes.

Every public privileged RPC must include:

```sql
security definer
set search_path = ''
```

and then:

```sql
revoke execute on function ... from public, anon;
grant execute on function ... to authenticated;
```

Patch legacy `get_round_for_player(uuid)` only to restore Local reveal without changing its response shape. Do not drop it yet.

### B05. Atomic command RPCs

Implement these exact public contracts in `03_gameplay_security_commands.sql`:

```text
create_room(settings..., game_mode text, local_names text[]) returns jsonb
find_joinable_room(room_code text) returns jsonb
join_room(room_code text, username text) returns jsonb
start_game(room_id uuid) returns uuid              -- round id
advance_to_voting(round_id uuid) returns void
finalize_voting(round_id uuid, reason text) returns jsonb
create_next_round(room_id uuid, expected_round_number int) returns uuid
finish_game(room_id uuid) returns void
extend_local_role_reveal(round_id uuid, seconds int) returns void
mark_stale_players_offline(room_id uuid, stale_seconds int) returns int
```

All commands:

- Get caller from `(select auth.uid())`.
- Acquire the per-room lock first.
- Re-read room/current host/current phase after locking.
- Are idempotent for retries.
- Reject finished/wrong-mode/wrong-phase operations with stable error codes/messages.
- Never accept an authorization boolean.

`finalize_voting` algorithm, in order:

1. Lock room then round.
2. Verify current host and phase `voting`.
3. If `scores_finalized_at` is non-null, return current scores/phase without mutation.
4. Read participant votes.
5. Add +10 to every voter who targeted the imposter.
6. Aggregate target counts.
7. Imposter is caught only if it is the sole highest target.
8. Otherwise add +20 to imposter.
9. Update player scores in one set-based statement.
10. Set `scores_finalized_at`, `phase = 'results'`, and server-derived results deadline.
11. Bump revision and return:

```json
{
  "round_id": "...",
  "phase": "results",
  "scores": {"player-id": 10},
  "already_finalized": false
}
```

`reason` accepts only `all_votes`, `timer`, `host_skip`; it is audit context, never authorization.

### B06. Mode-aware RLS

In `04_gameplay_security_rls.sql`:

- Use `TO authenticated` explicitly.
- Wrap `auth.uid()` in `SELECT`.
- Scope room/player/hint/vote/participant/revision SELECT to room membership.
- Online vote INSERT/UPDATE: voter belongs to caller and snapshot.
- Local vote INSERT/UPDATE: caller is current Local host and voter/target are snapshot participants.
- UPDATE policies include both `USING` and `WITH CHECK`.
- Online hints: caller owns hint player and player is a snapshot participant.
- Local hint writes are denied (Local hints are verbal).
- Direct player INSERT is denied after `create_room`/`join_room` client migration.
- Direct sensitive round/room mutations remain temporarily compatible until enforcement.

### B07. Host migration and presence

Update host migration to use the same room lock as commands. Preserve deterministic oldest-online-player selection.

Replace global stale cleanup with room-scoped cleanup. It must reject Local rooms and non-host callers. Update all Dart call sites to pass `roomId` later.

### B08. Realtime additive setup

Add `round_revisions` to `supabase_realtime`; keep legacy publications until Phase D enforcement.

**Gate B:** additive SQL applies in a staging database, old client still loads, Local role reveal/vote regression is fixed, and all new RPC security tests pass.

## 9. Phase C — Flutter Compatible Client

### C01. Explicit redaction models

Modify `RoundInfo` and `RoundInfoModel`:

```dart
final String? imposterPlayerId;
final Character? character;
final int submittedVoteCount;
final int requiredVoteCount;

bool get hasVisibleImposter => imposterPlayerId != null;
bool get hasVisibleCharacter => character != null;
bool isImposter(String playerId) => imposterPlayerId == playerId;
bool get allRequiredVotesSubmitted =>
    requiredVoteCount > 0 && submittedVoteCount >= requiredVoteCount;
```

Do not convert SQL NULL into `''` or a fake `Character`. Update `copyWith` so callers can deliberately set nullable secrets to null; use an explicit sentinel parameter if necessary.

Add:

```dart
class LocalRoleRevealBundle extends Equatable {
  final String roundId;
  final Character character;
  final String imposterPlayerId;
}

class FinalizeVotingResult extends Equatable {
  final String roundId;
  final Map<String, int> scores;
  final bool alreadyFinalized;
}
```

Update UI rules:

- Online imposter card renders without `Character`.
- Online innocent requires character; otherwise show syncing state.
- Results require both secrets; otherwise show syncing state and refresh.
- Result widgets receive non-null values only after the guard.
- Local shared screen never consumes reveal bundle.

### C02. Remote data-source API

Add/replace methods in `GameRemoteDataSource`:

```dart
Future<Map<String, dynamic>> getRoundForPlayerV2({required String roundId});
Future<LocalRoleRevealBundleModel> getLocalRoleRevealBundle({required String roundId});
Future<VoteStateModel> getVoteState({required String roundId});
Future<FinalizeVotingResultModel> finalizeVoting({
  required String roundId,
  required String reason,
});
Future<RoundInfoModel> createNextRoundAuthoritatively({
  required String roomId,
  required int expectedRoundNumber,
});
Stream<Map<String, dynamic>> watchRoundRevision({required String roundId});
```

Snapshot mapping order:

1. Call v2 round RPC.
2. Load participant IDs from response.
3. Load `Character` only when `character_id != null`.
4. Load room-scoped hints.
5. Load identity-aware vote state.
6. Build one `RoundInfoModel` with vote counts.

Change round watch to:

```dart
return client
    .from('round_revisions')
    .stream(primaryKey: ['round_id'])
    .eq('round_id', roundId)
    .map((rows) => rows.first);
```

The repository `_watchWithRetry` maps every revision event to a full masked snapshot. Remove separate hints/votes subscriptions after the snapshot stream is proven.

### C03. Repository contracts

Replace client-authoritative methods in `GameRepository`:

```dart
Future<Either<Failure, FinalizeVotingResult>> finalizeVoting({
  required String roundId,
  required String reason,
});

Future<Either<Failure, RoundInfo>> advanceToVoting({required String roundId});

Future<Either<Failure, RoundInfo>> createNextRound({
  required String roomId,
  required int expectedRoundNumber,
});

Future<Either<Failure, void>> finishGame({required String roomId});

Future<Either<Failure, RoundInfo>> extendLocalRoleReveal({
  required String roundId,
  required int seconds,
});

Future<Either<Failure, LocalRoleRevealBundle>> getLocalRoleRevealBundle({
  required String roundId,
});
```

Remove after migration:

- `calculateScores(currentScores:)`
- Generic phase advance capable of voting→results
- Client-side next-round imposter/character selection
- Client per-player score writes

Create use cases:

```text
lib/features/game/domain/usecases/finalize_voting.dart
lib/features/game/domain/usecases/advance_to_voting.dart
lib/features/game/domain/usecases/create_next_round.dart
lib/features/game/domain/usecases/finish_game.dart
lib/features/game/domain/usecases/get_local_role_reveal_bundle.dart
```

### C04. Cubit changes

In `GameCubit`:

- Keep only round snapshot and players subscriptions.
- Await subscription cancellation before replacing when possible.
- Add one per-round in-flight finalize guard.
- `finalizeVoting(roundId, reason)` calls one use case, updates returned scores, and waits for revision snapshot to confirm results.
- `advanceToVoting` calls expected-phase RPC.
- `createNewRound` calls server RPC; never chooses secrets.
- Clear old round subscription before subscribing to new round.
- On resume, replace all subscriptions after authoritative reload.
- If identity is unresolved, fail closed and emit a nonfatal syncing message.

Delete `_scoredRoundIds`, `_lastKnownScores`, and client calculation logic only after server finalization tests pass.

### C05. Local reveal isolation

Refactor `LocalRoleRevealScreen`:

- Do not create a general `GameCubit` merely to obtain secrets.
- Use a dedicated reveal Cubit/controller with `GetLocalRoleRevealBundle` plus room participants.
- Hold bundle only for the reveal sequence.
- Clear bundle/controller before navigating to Local game screen.
- Local game screen loads general redacted round snapshot.

### C06. Online voting readiness

Update `VotingPhaseContent` and GameView auto-finalization:

- Use `submittedVoteCount`/`requiredVoteCount`, not `playerVotes.length / players.length`.
- Online pre-results `playerVotes` contains only caller vote.
- Do not render live target counts before results.
- Host auto-finalizes only when `allRequiredVotesSubmitted` changes false→true.
- Timer and skip call the same `finalizeVoting` with different reasons.
- A disconnected participant's existing vote remains scored; required count uses currently online snapshot participants.

### C07. Room commands and identity

Change Room data source/repository/use cases:

- Atomic `createRoom` returns room + host player (and complete Local roster where applicable).
- `joinRoom` uses lookup/join RPCs and returns stable player identity.
- `startGame` uses server command.
- `markStalePlayersOffline` requires `roomId`.
- Finish/leave/heartbeat never fall back to another player.

Remove `currentPlayer ??= players.first` from waiting room. Display syncing state until the authenticated player's row resolves.

### C08. Dependency injection

Update `lib/core/di/injection_container.dart`:

- Register every new use case.
- Pass `FinalizeVoting`, `AdvanceToVoting`, and server round commands to `GameCubit`.
- Register dedicated Local reveal Cubit/controller as a factory.
- Remove registrations only after no production code references old use cases.

### C09. Realtime lifecycle

For every channel/stream:

- One lifecycle owner.
- Errors flow to retry logic.
- Cancel retry timer before resubscribe.
- Cancel/remove channel on deactivate/dispose.
- No duplicate route navigation.
- No duplicate round finalization.

Reuse the cancellation-aware `_watchWithRetry`; do not add another unbounded retry loop.

**Gate C:** `dart format`, `flutter analyze`, focused tests, and full `flutter test` pass; manual Local + three-client Online staging flows pass with additive DB.

## 10. Phase D — Enforcement Deployment

Only proceed after compatible-client adoption or forced minimum version.

In `06_gameplay_security_enforcement.sql`:

1. Revoke table-level SELECT on `rounds` from `anon`, `authenticated`.
2. Grant only safe round columns; do not grant `character_id` or `imposter_player_id`.
3. Revoke direct SELECT on `votes`; reads go through vote-state RPC.
4. Revoke direct sensitive UPDATE/INSERT now replaced by commands.
5. Remove `rounds` and `votes` from raw Realtime publication.
6. Keep/add `round_revisions` publication.
7. Revoke/drop legacy read RPC only when old client use is zero/blocked.

Verification:

```sql
select has_table_privilege('authenticated', 'public.rounds', 'select');
select has_column_privilege('authenticated', 'public.rounds', 'character_id', 'select');
select has_column_privilege('authenticated', 'public.rounds', 'imposter_player_id', 'select');
select * from pg_publication_tables where pubname = 'supabase_realtime';
```

All three privilege checks above must be false for broad/secret access; safe-column checks must be true.

**Gate D:** complete authenticated-client security suite passes and no supported app version regresses.

## 11. Test Implementation

### E01. Database identity harness

Use separate Supabase clients where possible. Transaction test template:

```sql
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"USER_UUID","role":"authenticated"}';
-- test query
rollback;
```

Never use the SQL Editor's default superuser result as proof of RLS.

### E02. Required database tests

Implement all of these in `08_gameplay_security_tests.sql` or an automated integration harness:

```text
DB01 Local reveal bundle: Local host allowed; general Local state redacted.
DB02 Online innocent: character visible, imposter hidden.
DB03 Online imposter: imposter identity visible, character hidden.
DB04 Results participant: both visible.
DB05 Outsider/anon: no row or execute denied.
DB06 Online self-vote allowed; vote-as-other denied.
DB07 Local host votes for local participant; local outsider denied.
DB08 Cross-room/self-vote rejected.
DB09 Ballot state hides other Online targets before results.
DB10 Atomic finalization preserves +10/+20/tie/no-vote rules.
DB11 Two concurrent finalizations score once.
DB12 Two next-round calls create one round/snapshot.
DB13 Late join cannot vote or enter snapshot.
DB14 Old/new host race authorizes only current host.
DB15 Cleanup for room A cannot modify room B or Local rooms.
DB16 Direct secret columns and raw Realtime are unavailable after enforcement.
DB17 Create/join retries are idempotent; no orphan room/duplicate player.
```

### E03. Flutter tests

Use `flutter_test` and manual fakes; do not add a mocking package unless necessary and approved.

Create focused tests under:

```text
test/features/game/data/models/round_info_model_redaction_test.dart
test/features/game/data/repositories/game_repository_snapshot_test.dart
test/features/game/presentation/cubit/game_cubit_finalize_test.dart
test/features/game/presentation/views/local_role_reveal_view_test.dart
test/features/game/presentation/views/online_voting_visibility_test.dart
test/features/room/presentation/cubit/room_cubit_atomic_create_test.dart
test/features/room/presentation/views/waiting_room_identity_test.dart
```

Required assertions:

- Null secrets remain null; no empty-string/fake character fallback.
- Online imposter widget builds without character data.
- Online vote counts do not reveal targets.
- Duplicate finalization UI events call repository once.
- Revision event replaces one complete snapshot.
- Stream cancellation prevents retry/resubscribe.
- Local reveal state is cleared before shared game navigation.
- Waiting room does not select the first player when caller identity is missing.

### E04. Static repository checks

Run:

```powershell
rg -n "from\('rounds'\).*select\(\)|from\('rounds'\).*select\('\*'\)" lib
rg -n "imposterPlayerId.*\?\? ''|imposter_player_id.*\?\? ''" lib
rg -n "Random\(\)|nextInt" lib\features\game\data
rg -n "while \(true\)" lib\features\game lib\features\room
rg -n "service_role|SUPABASE_SERVICE" lib assets .env*
```

Expected:

- No unsafe round SELECT.
- No secret sentinel fallback.
- No client Online secret selection.
- No unbounded stream retry loops.
- No service secret in client files.

## 12. Work Packages for a Cheaper LLM

Execute one package per turn/commit-sized change. Never ask the model to implement the entire plan at once.

| Package | Scope | Must pass before next |
|---|---|---|
| WP-01 | Diagnostics + canonical SQL skeletons | Gate A |
| WP-02 | Schema, participants, revisions, indexes | SQL verification |
| WP-03 | Private locks/round helper + revision triggers | DB unit/security tests |
| WP-04 | Versioned read/reveal/vote-state RPCs | DB01–DB09 |
| WP-05 | Atomic room/start/phase/finalize/next/finish commands | DB10–DB17 |
| WP-06 | Mode-aware RLS + scoped presence | Policy tests + EXPLAIN |
| WP-07 | Dart nullable/redaction models | Model tests + analyze |
| WP-08 | Game data source complete snapshot/revision stream | Repository tests |
| WP-09 | Game repository/use cases/DI | Analyze + use-case tests |
| WP-10 | Cubit atomic finalization/subscription reduction | Cubit tests |
| WP-11 | Local reveal isolation | Local reveal widget tests |
| WP-12 | Online voting secrecy/readiness/results | Online widget tests |
| WP-13 | Atomic room create/join/start + identity | Room tests |
| WP-14 | Full staging regression | Gate C |
| WP-15 | Privilege/publication enforcement | Gate D |
| WP-16 | Cleanup old APIs/scripts + advisors | Full suite |

For every package, the implementation model must report:

```text
Files changed:
Behavior changed:
Security invariant covered:
Commands/tests run:
Failures or skipped verification:
Next package allowed: yes/no
```

## 13. STOP Conditions

Stop and ask for direction if:

- Live schema/function signatures contradict the captured assumptions.
- Duplicate `(room_id, user_id)` data exists.
- Existing invalid game modes cannot be classified safely.
- A migration would drop data, function overloads, or constraints not owned by this change.
- Product rejects secret Online ballots or the locked tie rule.
- No minimum-version/forced-update path exists before enforcement.
- Staging cannot simulate at least host, imposter, innocent, outsider, and Local host identities.
- Any unauthorized client receives either secret in REST/RPC/Realtime tests.
- Finalization can score twice or host migration produces more than one host.
- Flutter analysis/tests cannot run and the failure is not understood.

## 14. Completion Definition

Do not mark complete until:

- Gates A, B, C, and D pass.
- Database advisors are reviewed and relevant findings fixed.
- Full Flutter analysis/test suite passes.
- Multi-client Online and shared-device Local manual matrix passes.
- Rollback SQL is tested in staging.
- Legacy clients are blocked or migrated before secret enforcement.
- Old scoring, secret selection, direct round reads, raw vote subscriptions, and contradictory SQL scripts are removed or explicitly marked superseded.

## 15. Copy-Paste Prompt for Each Cheap-Model Work Package

Use this prompt, replacing `WP-XX` and its scope from Section 12:

```text
Implement only WP-XX from:
doc/online_local_security_implementation_runbook.md

Before editing, read the complete runbook and every file listed by that work
package. Preserve unrelated user changes. Do not use Spec Kit. Do not proceed
to the next work package.

Hard rules:
- Supabase is authoritative for Online Mode.
- Never trust client mode/host/player/score/secret values for authorization.
- Never expose character_id or imposter_player_id through direct rounds reads
  or raw Realtime.
- Use players.is_host as current host authority.
- Use apply_patch for file edits.
- Run the exact verification required by the package.
- If a STOP condition occurs, make no unsafe workaround; report it.

At the end report exactly:
Files changed:
Behavior changed:
Security invariant covered:
Commands/tests run:
Failures or skipped verification:
Next package allowed: yes/no
```
