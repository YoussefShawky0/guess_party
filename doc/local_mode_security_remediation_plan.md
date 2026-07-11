# Online and Local Gameplay Security Remediation Plan

**Status:** Implementation-ready  
**Owner:** Gameplay / Platform  
**Priority:** P0 game integrity and authorization  
**Scope:** Local role reveal, Local voting, Online vote ownership, imposter and selected-character secrecy, authoritative round creation, presence/host migration, round Realtime, and score finalization

## 1. Executive Summary

The production symptoms have two immediate causes:

1. Local Mode role reveal uses an RPC that masks `imposter_player_id` for the shared host session.
2. The deployed vote policy differs from the repository policy and rejects votes cast on behalf of local players.

The surrounding design also permits clients to query or receive secret round data through paths that bypass the masking RPC. Fixing only the two symptoms would leave Online Mode vulnerable to vote spoofing and imposter disclosure.

This plan delivers the remediation in four controlled stages:

1. Reconcile schema drift and restore Local Mode with mode-aware database authorization.
2. Introduce safe round-change notifications and an atomic voting finalization RPC.
3. Release a compatible Flutter client that no longer reads secret round rows directly.
4. Enforce column privileges and remove `rounds` from Realtime after the compatible client is adopted.

No client-provided mode or host flag is trusted. Online authority remains in Supabase. Local Mode remains a shared-device experience; moving it completely offline is tracked as a separate architectural follow-up because the current implementation persists Local games in Supabase.

## 2. Non-Negotiable Invariants

- An Online player can submit or update only their own vote.
- The authenticated Local host can submit votes for local players on the shared device.
- A voter and target must belong to the same room and round.
- `players.is_host` is the source of host authority; `rooms.host_id` is not used for authorization.
- `imposter_player_id` and the selected `character_id` are never available through direct round-table SELECT or raw Realtime payloads.
- The masking RPC is the only client-readable source of either round secret.
- A dedicated Local reveal flow receives both round secrets only for sequential pass-device reveal; normal shared Local game state remains redacted until results.
- An Online player receives the imposter ID only when they are the imposter or the round is in results; an Online imposter does not receive the selected character before results.
- Imposter and character selection occur only in PostgreSQL; the host client never generates or reads unmasked Online secrets.
- Every round has an immutable participant snapshot used by voting, readiness, scoring, and reconnect logic.
- Scoring is deterministic, persisted once, and transitions voting to results atomically.
- Cancellation and reconnect behavior must not create duplicate Realtime channels.

## 3. Product Decisions

### 3.1 Scoring

Preserve the current intended rules:

- Each player who voted for the imposter receives **+10**, regardless of the majority result.
- The imposter receives **+20** when they are not the unique most-voted player.
- If the highest vote count is tied, the imposter escapes and receives +20.
- If no votes exist, the imposter escapes and receives +20.

The explicit tie rule replaces the current iteration-order-dependent behavior.

### 3.2 Room mode

`game_mode` is selected when the room is created and becomes immutable. The mode is visible to participants and controls routing. A room cannot switch between Online and Local after creation.

### 3.3 Local Mode boundary

This remediation secures the existing Supabase-backed Local Mode. A subsequent project should move Local Mode state into an in-memory/local game engine so it is fully network-free, as required by the project constitution. That refactor is intentionally excluded from this production repair.

## 4. Target Architecture

### 4.1 Online Mode

- Supabase owns rooms, players, rounds, votes, phase, and scores.
- RLS verifies room membership and vote ownership.
- Imposter identity is returned only by `get_round_for_player`.
- The selected character is returned to Online innocents, but masked from the Online imposter until results.
- First- and next-round secret assignment runs server-side from an immutable participant snapshot.
- Clients observe a non-sensitive `round_revisions` stream, then refresh through the masking RPC.
- The host invokes one `finalize_voting` RPC to score and enter results.

### 4.2 Local Mode

- The authenticated shared-device host owns the Supabase room session.
- Local player rows retain distinct generated IDs.
- Mode-aware vote policies let the current database host vote for those local player IDs.
- The masking RPC recognizes the current Local host and returns the imposter ID for pass-device role reveal.
- The same atomic `finalize_voting` operation is used, preventing mode-specific score divergence.

## 5. Database Workstream

### DB-01: Capture deployed state

Before mutation, save:

- `pg_get_functiondef`, owner, security mode, arguments, return type, and ACL for affected functions.
- `pg_policies` definitions for `rooms`, `players`, `rounds`, and `votes`.
- Table and column grants for `anon` and `authenticated`.
- `game_mode` type, nullability, default, allowed values, and existing invalid rows.
- Realtime publication membership.
- Existing indexes used by membership policies.

Store the diagnostic output with the deployment record. Do not assume the live database matches `doc/schemas`.

### DB-02: Reconcile `rooms.game_mode`

Apply in this order:

1. Add the column if missing.
2. Backfill null or invalid values using verified room history; default unresolved legacy rooms to `online`.
3. Set default `online`.
4. Add and validate `CHECK (game_mode IN ('online', 'local'))`.
5. Set `NOT NULL`.
6. Install `BEFORE UPDATE OF game_mode` trigger that rejects changes.

The immutability trigger is `SECURITY INVOKER`, uses a hardened search path, and watches only `UPDATE OF game_mode`.

### DB-03: Add policy-supporting index

Add if absent:

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_players_room_user
ON public.players (room_id, user_id);
```

Create it outside a transaction in production. Existing primary/foreign-key and vote indexes must also be confirmed with `EXPLAIN` on representative policy queries.

### DB-04: Replace vote policies

All policies target `authenticated` explicitly.

**SELECT:** caller must have a player row in the vote round's room.

**INSERT:** voter and target must belong to the round's room, then authorize one branch:

- Online: `p_voter.user_id = auth.uid()`.
- Local: caller has a player row in the room with `is_host = true` and `user_id = auth.uid()`.

**UPDATE:** repeat the same authorization in both `USING` and `WITH CHECK` so UPSERT is safe.

The policy must never use “any authenticated room member” as authority to vote for arbitrary Online players.

### DB-05: Version and harden `get_round_for_player`

Do not change the legacy RPC in a way that makes `character_id` nullable for already-installed clients. Use two rollout contracts:

- Patch legacy `get_round_for_player` only enough to restore the Local host imposter reveal while preserving its existing shape.
- Add `get_round_for_player_v2` with explicit nullable/redacted secret fields for the compatible client.

The v2 contract enforces:

1. Caller has a player row in the round's room.
2. General Local game-state branch masks both secrets before results.
3. Online imposter branch returns `imposter_player_id` but masks `character_id`.
4. Online innocent branch returns `character_id` but masks `imposter_player_id`.
5. Results return both secrets to authenticated round participants.
6. Otherwise return no row.

Add a separate `get_local_role_reveal_bundle(round_id)` RPC. It returns both Local secrets only to the current host of a Local room and only for the dedicated sequential reveal use case. It has no Realtime surface and uses the same hardened privileges. The reveal controller clears the bundle when reveal completes or is disposed; normal Local gameplay never stores it in shared `GameState`.

Function requirements:

- Fixed empty search path and fully schema-qualified relations/functions.
- Explicit `auth.uid()` check inside the body.
- `SECURITY DEFINER` only because the function must read the protected column.
- Revoke EXECUTE from `PUBLIC` and `anon`; grant only to `authenticated`.
- Explicit, versioned return signature whose nullable fields match the Dart model.
- Revoke the legacy function after minimum-version enforcement.
- Save both transitional and canonical definitions in `doc/schemas/get_round_for_player.sql` with removal criteria.

### DB-06: Introduce safe round revisions

Create `public.round_revisions` containing only:

- `round_id UUID PRIMARY KEY REFERENCES rounds(id) ON DELETE CASCADE`
- `room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE`
- `revision BIGINT NOT NULL DEFAULT 1`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`

An internal trigger on round INSERT/UPDATE atomically upserts and increments the revision. The trigger helper lives in a non-exposed schema, uses a fixed search path, and has no client EXECUTE grant.

RLS permits SELECT only for authenticated room members. Clients receive no INSERT, UPDATE, or DELETE grant. Add `round_revisions` to the Realtime publication.

This table becomes the only round-change subscription surface. It contains no secret columns and emits an initial row through Supabase `.stream()`.

### DB-07: Add atomic `finalize_voting`

Create a privileged RPC that accepts only `p_round_id`. It must not accept client-provided scores, voter identity, mode, or host flags.

Within one short transaction/function call:

1. Lock the round row with `FOR UPDATE`.
2. Confirm the caller owns the current `players.is_host = true` row for the room.
3. Confirm the round is in `voting`.
4. If already finalized, return the persisted scores without awarding again.
5. Read the authoritative imposter and votes.
6. Award +10 to each voter whose target is the imposter.
7. Determine the highest vote count deterministically; a tie means escape.
8. Award +20 to the imposter when not uniquely most-voted.
9. Persist score increments to `players` in a set-based update.
10. Set `rounds.scores_finalized_at` and transition the round to `results` with the configured results deadline.
11. Return the resulting score map and round/phase metadata.

Add `scores_finalized_at TIMESTAMPTZ NULL` to `rounds` as the idempotency marker. The RPC is the only path for voting→results. Apply the same EXECUTE restrictions and hardened search path as the masking RPC.

Save the canonical definition in `doc/schemas/finalize_voting.sql`.

### DB-08: Restrict secret-column access

This is an enforcement step and must occur only after the compatible client is released.

1. Revoke table-level SELECT on `rounds` from `anon` and `authenticated`.
2. Grant SELECT on the explicit non-sensitive column list to `authenticated`; exclude both `imposter_player_id` and `character_id`.
3. Confirm `has_table_privilege(..., 'SELECT')` is false.
4. Confirm `has_column_privilege` is true for required safe columns and false for both secret columns.
5. Remove `rounds` from the Realtime publication after all clients use `round_revisions`.

A column-level REVOKE alone is insufficient because table-level privileges are additive.

### DB-09: Add immutable round participants

Create `public.round_participants` with a composite primary key `(round_id, player_id)`, foreign keys to `rounds` and `players`, and the player's join-order/eligibility metadata needed for deterministic play.

When a round is created, snapshot:

- Online Mode: players who are online at round creation.
- Local Mode: every local player row belonging to the shared-device room.

Rules:

- Participants never change during a round, including after disconnect/reconnect.
- A disconnected imposter remains the imposter; secrets are never reassigned mid-round.
- Vote voter/target checks use `round_participants`, not general room membership.
- A reconnecting participant regains voting eligibility if the round is still in voting.
- A late or malicious post-start room join is not a participant and cannot vote or influence scoring.

Expose participant IDs through a safe room-scoped query/RPC. `RoundInfo.playerIds` must come from this snapshot rather than rebuilding it from every room player on each refresh.

### DB-10: Move all round creation server-side

Create one private helper, conceptually `private.create_round_for_room(room_id, round_number)`, used by both first-round creation and the authenticated next-round RPC.

The helper:

1. Serializes commands for the room.
2. Locks and validates the room state/current round.
3. Builds the participant snapshot.
4. Enforces the minimum eligible player count.
5. Selects the imposter only from the snapshot.
6. Selects an active category character without immediate repetition and maintains `used_character_ids` transactionally.
7. Inserts the round and participant rows.
8. Updates `rooms.current_round` in the same transaction.
9. Returns only the new round ID to its caller; the public RPC returns masked data through `get_round_for_player`.

Replace the client-side `Random()` imposter/character selection in `GameRepositoryImpl.createNextRound`. The Online host must never know the raw secret pair merely because it starts the next round.

Harden the existing first-round trigger to call the same helper during the compatibility window. After supported clients use command RPCs, replace direct room status updates with `start_game(room_id)` and remove the legacy trigger path.

### DB-11: Replace direct phase mutations with commands

Direct authenticated UPDATE of sensitive round/room state must be removed after client migration. Provide narrowly scoped commands:

- `start_game(room_id)`: current host only; validates waiting status, mode, capacity/minimum participants, and creates round 1 once.
- `advance_to_voting(round_id)`: current host only; compares expected `hints` phase and uses database time.
- `finalize_voting(round_id, reason)`: current host only; atomically scores and enters results. Allowed reasons are `all_votes`, `timer`, and `host_skip`; reason is logged, not used as identity authority.
- `create_next_round(room_id, expected_round_number)`: current host only; requires previous results and is idempotent.
- `finish_game(room_id)`: current host only; marks finished once.
- `extend_local_role_reveal(round_id, seconds)`: Local current host only; bounded extension, never available to Online rooms.

Every command verifies the current host from `players.is_host`, checks expected current state, and is idempotent. Hints→voting cannot accidentally become voting→results on a duplicate/stale call.

### DB-12: Serialize host migration and game commands

Host migration, phase transitions, round creation, and finalization can race during disconnects. Use one consistent per-room transaction lock strategy across these functions (transaction-scoped advisory lock or an equivalent locked room row), then acquire round/player rows in a documented order.

After taking the lock, re-read `players.is_host` and room/round state before authorization. Expected behavior:

- If the old host loses authority first, their command is denied and the new host may retry.
- If an authorized command commits first, host migration observes the committed state.
- Two hosts can never finalize or create a round twice.

### DB-13: Scope presence cleanup

Replace global `mark_stale_players_offline(stale_seconds)` with a room-scoped command:

```text
mark_stale_players_offline(room_id, stale_seconds)
```

It must:

- Require the current Online host for that room (or run from a trusted scheduled job).
- Reject/skip Local rooms.
- Update only Online participant rows in the specified room.
- Reconcile host migration and empty-room cleanup under the same per-room lock.
- Use a bounded server-controlled stale interval.

The current global RPC can mark unrelated Local players offline when any Online host runs cleanup. It must be retired.

### DB-14: Harden room membership and identity

- Restore/enforce one player identity per `(room_id, user_id)`; generated Local user IDs remain distinct, so this does not block Local Mode.
- Enforce unique username per room separately if required by product behavior.
- Introduce an atomic `create_room` command that inserts the room and its host player together. For Local Mode it validates and inserts the full supplied local-name roster in the same transaction. This prevents orphan rooms/partial Local rosters when one client insert fails and retries room-code collisions server-side.
- Replace permissive player INSERT with a `join_room` command that requires `rooms.status = 'waiting'`, enforces capacity atomically, prevents joining Local rooms remotely, and returns the caller's existing row idempotently on retry.
- Remove fallback identity behavior: absence of the caller's player row is a synchronization/authorization failure, never permission to act as the first player.

### DB-15: Enforce secret Online ballots

Decision: Online ballots are secret during voting. A caller sees only their own submitted target plus aggregate submitted/required counts; full votes become readable to participants in results. Local host continues to see all Local votes for shared-device sequencing.

Replace raw `votes.stream()` with the safe round-revision refresh and an identity-aware vote-state RPC. Remove `votes` from raw Realtime and revoke direct SELECT during enforcement. This decision does not change vote ownership or scoring rules.

### DB-16: Scope Online hints

The current hints policies/read stream must not remain globally readable.

- SELECT requires membership in the hint round's room.
- Online INSERT/UPDATE requires `hints.player_id` to belong to `auth.uid()` and the round participant snapshot.
- Local Mode performs verbal hints and receives no database-write exception by default.
- Cross-room reads/writes are denied.
- If hints are considered public to all room participants during the hints phase, document that visibility explicitly; otherwise introduce the same revision/RPC pattern selected for ballots.

### DB-17: Scope room and player visibility

Replace global room/player SELECT policies:

- Authenticated room members may read their room and its players.
- A non-member may look up only safe join metadata for a waiting Online room through `find_joinable_room(room_code)`; do not expose unrestricted room-table reads.
- Local rooms are not returned through the join lookup.
- Player usernames, presence, host flags, and scores are not readable across rooms.
- Room/player Realtime subscriptions rely on the same membership predicates.

The atomic `create_room` RPC is required before enforcing these policies because a newly inserted room does not yet have a host player row under the current two-step client flow.

## 6. Flutter Workstream

### APP-01: Replace round Realtime source

In `game_remote_data_source.dart`:

- Replace `rounds.stream()` with `round_revisions.stream()` filtered by `round_id`.
- Map revision events to the existing lightweight change notification.
- Keep `_watchWithRetry` as the lifecycle/backoff owner.
- Verify cancellation removes the underlying Supabase subscription immediately.

Because `.stream()` supplies the current revision row, initial-load semantics are retained without exposing the round record.

### APP-02: Remove secret-bearing direct reads

Replace every `SELECT *`/implicit SELECT on `rounds`:

- `updateRoundPhase` and `updatePhaseEndTime`: update, then fetch via masking RPC.
- `createRound`: return only the inserted ID, then fetch via masking RPC.
- `createNextRound` duplicate guard: select safe identity columns, then fetch the existing round via masking RPC.
- `getCurrentRound`: retain its explicit safe metadata query and RPC fetch.

All compatible-client reads use `get_round_for_player_v2`; the legacy RPC remains only for the staged mobile transition.

Add a repository-wide test/CI grep preventing new `.from('rounds').select()` or `.select('*')` patterns outside approved safe helpers.

### APP-03: Replace two-step voting finalization

Introduce `FinalizeVoting` through the existing Clean Architecture layers:

- Data source RPC call.
- Repository abstraction and implementation.
- Domain use case.
- `GameCubit.finalizeVoting(roundId)`.
- Local and Online views call this single operation instead of `calculateRoundScores().then(progressPhase())`.

On success, accept the returned score map and wait for Realtime to confirm the phase/round state. Preserve the Cubit's per-round double-submit guard. Recoverable validation failures remain inline.

Hints→voting continues to use the existing host-authorized phase advancement path. Voting→results is exclusively `finalizeVoting`.

### APP-04: Remove obsolete scoring path

After rollout:

- Remove direct imposter reads from `calculateScores`.
- Remove or deprecate the old scoring repository method and use case.
- Remove best-effort per-player score writes from the client.
- Keep display state driven by persisted player scores and Realtime updates.

### APP-05: Error and telemetry behavior

Add structured breadcrumbs for:

- `getRoundForPlayer.denied`
- `submitVote.denied`
- `finalizeVoting.started/succeeded/alreadyFinalized/denied/failed`
- `roundRevisions.subscribed/retrying/cancelled`

Player-facing RLS/authorization errors must map to concise in-flow messages. Do not expose SQL, policy names, IDs, or RPC internals.

### APP-06: Model redacted Online secrets explicitly

`RoundInfo` currently requires a concrete `Character` and uses an empty string for a masked imposter. Replace sentinel values with an explicit redacted model/nullable fields so these states are representable and testable:

- Online innocent: visible character, hidden imposter.
- Online imposter: hidden character, visible own imposter identity.
- Online results: both visible.
- Local role reveal: both secrets exist only in a dedicated ephemeral reveal state; shared `GameState` remains redacted.

The data source must not call `getCharacter` when the RPC masks `character_id`. Logs, Equatable props, debug output, and error breadcrumbs must not serialize secret values.

Refactor `LocalRoleRevealScreen` away from the general `loadGameState` path. Give it a dedicated reveal use case/state object for `get_local_role_reveal_bundle` and clear that state before navigating to the Local game screen.

### APP-07: Use round participants for Online readiness

Filter the Online voting UI and progress calculation by the immutable round participant IDs.

Auto-finalization readiness must count votes from currently online round participants, not `round.playerVotes.length` against a changing room-player count. A vote cast by a player who later disconnects remains valid for scoring but does not satisfy another online participant's missing vote.

The host may still finalize through timer expiry or the explicit host-skip flow. Reconnect before finalization restores the participant's ability to vote; reconnect after finalization loads results.

### APP-08: Route shared actions through authoritative commands

Update Room/Game repositories and use cases so both modes share command contracts without sharing UI assumptions:

- Waiting-room Start → `start_game`.
- Hints expiry/skip → `advance_to_voting`.
- Voting completion/expiry/skip → `finalize_voting`.
- Results Next Round → `create_next_round`.
- Final leaderboard → `finish_game`.
- Local role-reveal extension → Local-only bounded RPC.

Online screens resolve the current authenticated player and host from synchronized player state. Local screens use the shared-device host session. Presentation code never supplies an authorization boolean.

### APP-09: Fail closed on Online identity loss

Remove the waiting-room fallback that treats `players.first` as the current player when the authenticated row is absent. Show a reconnecting/identity-sync state and retry the authoritative query. Do not send heartbeat, leave, host, vote, or phase commands until identity resolves.

### APP-10: Reconcile shared Realtime ownership

Inventory the overlapping player subscriptions in `GameCubit`, `GameLifecycleManager`, waiting-room widgets, and presence banners. Assign one owner per data concern and ensure every channel:

- Has a unique lifecycle owner.
- Reports channel error/closed/timed-out status into retry logic.
- Cancels retry timers and removes the channel on disposal.
- Does not cause duplicate navigation or duplicate host/finalize actions after reconnect.

### APP-11: Make room creation/join atomic

Replace the current client sequences of room INSERT followed by one-or-many player INSERTs:

- Online create calls `create_room` once and receives room + host player.
- Local create calls the same command with the validated local roster and receives a complete room; it never exposes a half-created room to countdown/start logic.
- Join-by-code calls `find_joinable_room` for safe metadata and `join_room` for the atomic membership write.
- Retry responses are idempotent and preserve the same player identity.

Waiting-room identity resolution must use the player returned by these commands or a membership-scoped query, never `players.first`.

## 7. Repository Artifacts

Create or update:

- `doc/schemas/reconcile_game_mode.sql`
- `doc/schemas/mode_aware_votes_rls.sql`
- `doc/schemas/get_round_for_player.sql`
- `doc/schemas/round_revisions.sql`
- `doc/schemas/finalize_voting.sql`
- `doc/schemas/round_participants.sql`
- `doc/schemas/game_commands.sql`
- `doc/schemas/scoped_presence_cleanup.sql`
- `doc/schemas/room_membership_security.sql`
- `doc/schemas/rounds_secret_column_grants.sql`
- `doc/schemas/supabase_schema.sql`
- `lib/features/game/data/datasources/game_remote_data_source.dart`
- `lib/features/game/data/repositories/game_repository_impl.dart`
- `lib/features/game/domain/repositories/game_repository.dart`
- `lib/features/game/domain/usecases/finalize_voting.dart`
- Authoritative start/advance/next-round/finish command use cases
- `lib/features/game/presentation/cubit/game_cubit.dart`
- `lib/features/room/data/datasources/room_remote_data_source.dart`
- `lib/features/room/data/repositories/room_repository_impl.dart`
- `lib/features/room/presentation/cubit/room_cubit.dart`
- Local and Online voting views that currently chain scoring and phase progression
- Focused database, repository, Cubit, and widget tests

SQL files must be canonical and ordered; do not keep multiple contradictory “final” policy scripts.

## 8. Test Strategy

### 8.1 Database security tests

Run through separate authenticated clients or transaction-scoped roles with JWT claims. SQL Editor superuser results are not acceptance evidence.

Required identities:

- Local host
- Online host who is not imposter
- Online imposter
- Online ordinary member
- Authenticated outsider
- Anonymous caller

Required cases:

- Dedicated Local reveal RPC returns both secrets to the Local host; general Local game-state RPC remains redacted before results.
- Online non-imposter, including host, receives NULL before results.
- Online imposter receives their own ID.
- Online imposter receives no selected character before results.
- Online innocent receives the selected character but no imposter identity.
- Room member sees the ID in results.
- Outsider receives no row; anon cannot execute the RPC.
- Direct secret-column SELECT fails.
- Raw `rounds` Realtime subscription is unavailable after enforcement.
- `round_revisions` contains no secret fields and is room-scoped.
- Online self-vote succeeds; Online vote-as-other fails.
- Local host voting for each local player succeeds.
- Local non-host and outsider voting fail.
- Cross-room targets and self-votes fail.
- Finalization rejects non-hosts and wrong phases.
- Finalization is idempotent under two concurrent calls.
- Correct individual voters receive +10.
- Unique miss awards imposter +20.
- Tie and no-vote cases award imposter +20.
- Persisted scores match the returned map.
- First- and next-round secrets are generated server-side and returned masked to the Online host.
- Duplicate start/next-round commands create exactly one round and one participant snapshot.
- Late joiners cannot become round participants or vote in an active room.
- Room creation never leaves an orphan room or partial Local roster after a failed/retried request.
- Join retries return one stable membership; active/Local/full-room joins are rejected atomically.
- Room/player reads and Realtime events are invisible across rooms.
- Disconnect/reconnect does not mutate the participant snapshot or reassign the imposter.
- Old-host/new-host concurrent commands produce one authorized transition.
- Presence cleanup in room A cannot modify Online room B or any Local room.
- Direct reads and raw Realtime cannot disclose the selected character or imposter identity.

### 8.2 Flutter automated tests

- Local role reveal identifies exactly one imposter.
- Local sequential voting records one vote per local player.
- Online vote ownership errors stay inline.
- Finalization invokes one repository operation despite duplicate UI triggers.
- Realtime revision updates refresh the masked RPC state.
- Cancelled streams do not reconnect or leak channels.
- Duplicate round guard returns RPC-derived masked/unmasked state correctly.
- Online and Local flows remain routed to separate views.
- Online host never receives raw next-round secrets during creation.
- Online imposter state contains no character object before results.
- Online voting readiness uses online round participants rather than total room rows.
- Identity loss never falls back to another player or grants host controls.
- Atomic room create/join commands preserve the caller's player identity across retries.

### 8.3 Manual matrix

Test at least three physical clients for Online Mode and one shared device for Local Mode:

- Full round lifecycle, including next round.
- Network loss and reconnection during each phase.
- Host migration before and during voting.
- Host migration racing with hints advancement, finalization, next-round creation, and finish-game.
- Imposter disconnect/reconnect and non-imposter disconnect after casting a vote.
- Late join attempts after room activation.
- App background/resume.
- Old-client rejection or forced-upgrade behavior once privilege enforcement begins.

## 9. Deployment Plan

### Phase 0: Diagnostics and backup

- Capture DB definitions, grants, policies, indexes, and publication state.
- Export rollback SQL generated from the live state.
- Confirm production identifiers and function signatures.

**Gate:** reviewed diagnostic package and rehearsed rollback.

### Phase 1: Compatible database repair

- Reconcile `game_mode`, then install immutability.
- Add the composite membership index.
- Deploy mode-aware vote policies.
- Patch the legacy masking RPC compatibly for Local reveal and add the hardened v2 redaction contract.
- Add `scores_finalized_at`, `round_participants`, `round_revisions`, triggers, and command RPCs.
- Deploy room-scoped Online presence cleanup and membership hardening where backward compatible.
- Keep existing `rounds` SELECT grants and publication temporarily for old clients.

This phase fixes Local role reveal and Local votes without breaking the installed application.

**Gate:** database security tests pass except final column/publication enforcement tests.

### Phase 2: Compatible application release

- Release APP-01 through APP-11.
- Monitor RPC failures, voting failures, Realtime subscriptions, and score mismatches.
- Confirm the client no longer performs unsafe round reads.

**Gate:** full Local/Online matrix passes and supported client adoption meets the enforcement threshold.

### Phase 3: Secret enforcement

- Revoke table-level round SELECT.
- Grant safe columns only, excluding both selected character and imposter identity.
- Remove `rounds` from Realtime publication.
- Revoke direct mutations replaced by game command RPCs.
- Enforce the selected Online ballot-visibility contract.
- Revoke/drop the legacy masking RPC only after minimum-version enforcement.
- Run the complete post-deployment security suite.
- Use a minimum-version gate/forced update before enforcement if old mobile clients remain active.

**Gate:** no unauthorized column or Realtime access and no supported-client regressions.

### Phase 4: Cleanup

- Remove obsolete scoring APIs and contradictory SQL scripts.
- Update the base schema and operational documentation.
- Run Supabase database advisors and resolve relevant findings.
- Record the production schema fingerprint.

## 10. Rollback Strategy

- Every database phase is a separate reviewed migration/deployment unit.
- Preserve live pre-change function definitions, policies, grants, and publication membership.
- Phase 1 rollback restores previous compatible functions/policies but must not restore Online vote spoofing.
- Phase 2 is rolled back through the application release mechanism; additive DB objects remain harmless.
- Phase 3 emergency rollback may temporarily restore table SELECT and `rounds` publication only while supported clients are repaired; treat this as a security incident and time-box it.
- Score finalization data is never blindly reversed. Any correction uses an audited compensating migration.

## 11. Acceptance Criteria

The remediation is complete only when:

- Exactly one Local player receives the imposter role on every round.
- All Local players can vote through the shared host device.
- Online players cannot vote as another player.
- Unauthorized clients cannot read the imposter or selected character through REST, RPC, or Realtime.
- Online hosts do not generate or receive raw round secrets unless authorized by role/results.
- Round participants are stable across join, leave, disconnect, reconnect, and host migration.
- Voting finalization is atomic and cannot award twice.
- Persisted and displayed scores follow the documented rules.
- Online and Local full-round flows, next-round flow, reconnect, and disposal tests pass.
- Flutter analysis/tests and Supabase security tests pass.
- Database advisors have no unresolved findings relevant to the changed objects.

## 12. Online/Local Compatibility Matrix

| Shared capability | Online Mode contract | Local Mode contract | Required implementation |
|---|---|---|---|
| Create room | Authenticated room with remote join enabled | Shared-device room; remote join denied | Immutable DB `game_mode`; server-enforced membership rules |
| Add player | One authenticated identity per room, waiting status only | Host creates distinct generated local identities | `join_room`/policy validation plus `(room_id, user_id)` uniqueness |
| Start game | Current synchronized host; online participants only | Shared-device host; all local rows | `start_game` + server-side round helper |
| Assign character/imposter | PostgreSQL only; caller receives a redacted result | PostgreSQL only; host gets both for sequential reveal | Private round creation helper + masking RPC |
| Load round | Innocent gets character; imposter gets role; neither gets the other secret | Host reveal controller gets both; shared surface remains redacted | Explicit redaction model and RPC contract |
| Submit hint | Authenticated participant may write only their own hint | Verbal hints; no database write required | Mode/ownership-aware hint policy and room-scoped reads |
| Submit vote | Participant may vote only as self | Current Local host may vote for each local participant | Mode-aware vote RLS using round snapshot |
| Vote progress | Count currently online round participants; caller sees own target plus aggregate progress only | Count every local participant; host sees Local votes | Safe vote-state RPC plus revision contract |
| Hints→voting | Current host command with expected phase | Shared-device host command | Idempotent `advance_to_voting` RPC |
| Voting→results | Current host; atomic scoring/phase; safe after migration | Shared-device host; same scoring rules | Idempotent `finalize_voting` RPC |
| Disconnect | Presence changes only; participant snapshot remains | Not applicable to fake local identities | Room-scoped Online cleanup; Local excluded |
| Host migration | Oldest online participant becomes authoritative host | Original shared-device host remains | Serialized migration/command locking using `players.is_host` |
| Next round | Current host; secrets generated server-side | Shared-device host; sequential reveal follows | Idempotent `create_next_round` RPC |
| Finish game | Current host only; all clients observe room finished | Shared-device host | `finish_game` RPC and room-status Realtime |
| Realtime | Safe revisions/events only; no secret payload | Optional refresh for current backend-backed Local implementation | `round_revisions`, scoped player/vote streams, owned cancellation |
| Resume/reconnect | Reload authoritative round, participants, host, votes/progress, and scores | Reload shared-device session until offline refactor | Fail-closed identity resolution and subscription replacement |

## 13. Deep-Dive Edge-Case Decisions

- **Host disconnects during finalization:** the per-room lock decides ordering. A stale host is denied after migration; the new host retries safely. Finalization remains idempotent.
- **Player votes then disconnects:** their vote remains valid for scoring. Completion checks are based on currently online round participants, not raw vote count.
- **Player reconnects during voting:** if not finalized, they may vote or change their own vote; if finalized, they load results.
- **Imposter disconnects:** the imposter is not reassigned. Remaining participants may vote/finalize and the disconnected imposter remains eligible for the escape bonus.
- **Late join after start:** rejected by the database. Even a malformed client cannot enter the participant snapshot.
- **Two next-round taps/devices:** unique `(room_id, round_number)`, per-room serialization, and idempotent RPC return one round.
- **Timer and manual skip race:** both call the same expected-phase command; one transition commits and the other receives the committed result without rescoring.
- **Host migration and next round:** only the host authoritative after the lock may create it; the client never chooses secrets.
- **Old mobile client during enforcement:** use minimum-version gating before revoking grants/publication access.
- **Local players appear stale:** room-scoped cleanup rejects Local rooms, so fake identities are never marked offline by another room's host.
- **Room closes while RPC is in flight:** locked state is rechecked; commands on finished rooms return an idempotent terminal result or a recoverable validation failure.
- **No character remains unused:** server starts a new used-character cycle while avoiding the immediately previous character when possible.
- **Tie vote:** imposter escapes; UI result calculation must use the same deterministic outcome returned by the server rather than recomputing a different winner locally.
- **Ballot privacy:** Online clients see only their own target and aggregate completion before results; raw votes never travel through Realtime.

## 14. Follow-Up Architecture

Create a separate project to implement a true offline Local game engine:

- Local-only room, player, round, vote, and score state.
- No Supabase Auth, Database, Realtime, or RLS dependency.
- Shared domain rules where safe, with separate Online and Local repositories.
- Migration of the Local screens without changing Online authority.

That follow-up resolves the underlying architectural tension instead of continuing to adapt online security policies to fake Local player identities.
