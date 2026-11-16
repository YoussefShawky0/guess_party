# Guess Party — Full Project Review (2026-11-16)

Scope: whole repo at `b4d83bc` (master). Flutter client (`lib/`, ~20k LOC), Supabase
migrations + pgTAP contracts (`supabase/`), CI, specs/constitution.
Live Supabase project `bkpignyvtkqlicirpmmp` is **INACTIVE (paused)**, so the
database review is based on the canonical migration chain, not the live DB
(advisors/logs could not be pulled).

## Overall verdict

This is a well above-average hobby/indie codebase. Strengths:

- Clear constitution with enforceable rules; specs + phase docs show real discipline.
- Server-authoritative design: rooms/rounds/votes/finalization go through
  `SECURITY DEFINER` RPCs with `search_path = ''`, advisory locks, idempotency
  (`scores_finalized_at`, `p_request_id`, `p_expected_round_number`).
- Secret-state redaction is thought through (`get_round_for_player_v2`,
  `round_revisions` as a safe realtime signal, completed-round-only SELECT on `rounds`).
- pgTAP contract tests + CI that runs `supabase test db`, format, analyze, tests,
  release metadata validation. Secret scrubbing for Sentry. No secrets in git.
- Cubits guard `isClosed` after awaits; views mostly check `mounted`.

The biggest risks are **not in the RPCs — they're in the leftover broad
table policies** that let clients bypass those RPCs, and in **host-dependent
presence cleanup**.

---

## P0 — Security / game integrity (fix first)

> **Status (2026-11-16):** #1–#5 addressed in
> `supabase/migrations/20261116000100_p0_privilege_hardening.sql` with
> `supabase/tests/p0_privilege_hardening_contracts.test.sql` (48 assertions).
> The migration also fixes a pre-existing bug found while testing: the online
> hint INSERT/UPDATE policies joined RLS-hidden active rounds, so hint writes
> in the hints phase were denied (same bug votes had, fixed in
> `20260716183110`). Verified locally: migration applied with
> `supabase migration up --local`, `supabase test db` → 8 files, 189 tests,
> all pass. Deployed to the live project on 2026-11-16 via Supabase MCP
> `apply_migration` (name `p0_privilege_hardening`; the live ledger uses its
> own timestamp, not `20261116000100`). Post-deploy checks: dropped policies
> gone, anon has no SELECT on per-room tables, authenticated can update only
> `players.is_online/last_seen_at`, presence trigger installed.

### 1. Players can rewrite their own `score`, `is_host`, `room_id`
`20260712000100_production_schema.sql:2718`
```sql
CREATE POLICY "Players can update themselves" ON public.players FOR UPDATE
  TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
```
plus `grant all privileges on public.players to anon, authenticated`
(`20260712195404_table_grants.sql`). No BEFORE trigger restricts columns
(only `enforce_room_capacity`).

Failure scenario: any player runs
`supabase.from('players').update({'score': 999, 'is_host': true}).eq('user_id', me)`
→ wins the leaderboard and gains host powers (start/advance/finalize RPCs all
trust `is_host`). Two hosts in a room also breaks constitution §VI.

Fix: `revoke update on public.players from anon, authenticated;` then
`grant update (is_online) on public.players to authenticated;` — or better,
replace direct writes with a `heartbeat(p_room_id)` / `leave_room(p_room_id)`
RPC that sets `last_seen_at = now()` server-side. Add a pgTAP test that
self-promotion and score edits fail.

### 2. Direct INSERT on `players` and `rooms` is open to everyone (incl. `anon`)
`:2564` `"Anyone can create room" ... WITH CHECK (true)` and
`:2571` `"Anyone can join as player" ... WITH CHECK (true)`.
The client already uses `create_room` / `join_room` RPCs, so these policies are
pure attack surface: insert a player row into any room with `is_host = true`,
arbitrary `user_id`, any score; spam rooms anonymously.

Fix: drop both policies and revoke INSERT from `anon, authenticated`.

### 3. Host can write `rounds` and `rooms` directly
`:2644/2654/2664` host-only INSERT/UPDATE/DELETE on `rounds`, `:2674` host
UPDATE on `rooms` (keyed on `rooms.host_id`, not `players.is_host` — two
sources of truth). The client never writes these tables directly
(`git grep "from('rounds')"` is empty).

Failure scenario (online mode, host is also a player): host updates
`rounds set phase='results'` on the active round, then SELECTs it (results-phase
policy) → learns `imposter_player_id`; or sets `imposter_player_id` to
someone else; or edits `rooms.host_id`/`status`.

Fix: drop these policies; revoke INSERT/UPDATE/DELETE on `rounds`, `rooms`
from client roles. All transitions already exist as RPCs.

### 4. Client-supplied `last_seen_at`
`room_remote_data_source.dart:272,309`, `game_remote_data_source.dart:385`
write `DateTime.now()` from the device. A wrong device clock (common on
Android) or a malicious client setting a far-future value means the player is
never considered stale. Combined with #1, presence can't be trusted. Use
`now()` in a heartbeat RPC (or a BEFORE UPDATE trigger that overwrites it).

### 5. Broad SELECT policies leak cross-room data to `anon`
`"Anyone can view players|rooms|hints" USING (true)`. Any unauthenticated
client can enumerate every room, every player's `user_id` (auth UUID) and
username, and all hints of all rooms. Scope to room members
(`private.is_room_member(room_id, auth.uid())`), keep `join_room`/
`find_joinable_room` RPCs for discovery.

---

## P1 — Gameplay correctness (constitution violations)

> **Status (2026-11-16):** #6–#10 and the `isClosed`/polling parts of #11
> fixed on `fix/p0-privilege-hardening`: member-run stale cleanup
> (`20261116000200_member_stale_cleanup.sql` + pgTAP), inline action errors,
> subscription generation guard, room poll as realtime fallback only, and
> `AppErrorCode` → localized messages (en/ar). Verified locally: analyze
> clean, `flutter test` 148 pass, `supabase test db` 200 pass. The
> member-stale-cleanup migration is deployed to the live project (via
> `apply_migration`, name `member_stale_cleanup`). #11 countdown polling
> moved to `CountdownCubit` (see P2/P3 status below).

### 6. Host crash ⇒ no host migration, room never cleaned up (§VI)
`mark_stale_players_offline(p_room_id, …)` raises `HOST_REQUIRED` unless the
caller is the current online host (`production_schema.sql:1674`), and only the
host's client calls it (`game_lifecycle_manager.dart:87`).
If the host's app is killed, nobody is allowed to mark the host stale, so
`handle_player_presence_change` never fires and the room has a ghost host
forever. Exactly the crash/app-kill case §VI requires to self-heal.

Fix options: let any online room member call it (it only flips rows that are
already stale — safe), and/or schedule it server-side with `pg_cron` every
30 s. Add a pgTAP test "host stale → non-host cleanup promotes oldest player".

### 7. Recoverable failures render a fullscreen error (§V)
`GameCubit.sendHint`, `sendVote` (non-self-vote failures), `createNewRound`,
`finishGame` emit `GameError`, and `game_view.dart:429` renders `ErrorScreen`
for any `GameError`. A late vote rejected by RLS after the host skipped, or a
hint posted as the phase flips, ejects the player from the game screen.
Use `_emitInlineValidationMessage` for action failures; reserve `GameError`
for load failures.

### 8. Duplicate realtime subscriptions race
`_subscribeToGameUpdates` is fire-and-forget (`unawaited`). `loadGameState`
and `refreshGameStateOnResume` (or `createNewRound`) can run
`_replaceGameSubscriptions` concurrently: both cancel the (same) old subs,
then both assign → the first set of 3 subscriptions leaks and keeps emitting
(§ "No duplicate subscriptions"). Serialize with a generation counter or a
`Future` chain: capture `final gen = ++_subGen;` and drop results when
`gen != _subGen`.

### 9. Error-message mapping is substring guessing
`core/utils/error_handler.dart`: `'duplicate'` → "An account already uses this
email" (also matches vote/hint unique violations); `'not_found'` matches
`ROUND_NOT_FOUND` → "Unable to sign in"; the default branch shows up to 100
chars of the raw exception to players (§IX). Your RPCs already raise stable
codes (`HOST_REQUIRED`, `ROOM_PARTICIPANT_REQUIRED`, `CHAT_RATE_LIMITED`…).
Map `PostgrestException.message` codes → l10n keys in one table, and make the
fallback a generic localized message (send the raw error only to Sentry).

### 10. Localization leaks
Cubits emit hard-coded English (`'Game Over'`, `'You cannot vote for yourself'`,
`'Not enough connected players…'`), and `game_lifecycle_manager.dart:190`
builds `'X has left the game'`. Arabic users see English. Emit message
*codes/enums* from cubits and localize in the view.

### 11. Small async bugs
- `RoomCubit.loadRoomDetails` emits after `await` without `isClosed` check
  (throws `StateError` if the screen is popped mid-load). Same pattern worth
  grepping in `loadRoomPlayers` callers.
- `countdown_view.dart:94` calls `sl<GameRepository>()` from the widget and
  polls 5×; business logic in a widget (§X) and it navigates "anyway" when the
  round never appears — would land on a game screen that then shows
  `GameError`. Move to a cubit and treat "no round" as a recoverable state.
- `RoomCubit` polls every 10 s *in addition to* realtime streams (§ perf rule
  "avoid polling when Realtime is available"). Make it a fallback that only
  runs while a stream is in error.

---

## P2 — Design / maintainability (codebase-design lens)

- **Shallow use-case layer.** ~30 use-case classes are one-line pass-throughs
  to the repository (deletion test: removing them adds no complexity to
  callers). `GameCubit` takes 10 constructor dependencies. Consider letting
  cubits depend on the repository interface directly and keep use-cases only
  where they own logic. Fewer files, same seams, easier tests.
- **Two implementations of "watch room players"** — `GameRemoteDataSource`
  (all players, sorted by created_at) and `RoomRemoteDataSource` (online only,
  tiebreak by id). Different ordering ⇒ UI can disagree on "oldest". Make one
  deep module (`RoomPresence`) that owns ordering, filtering, retry.
- **Presence logic in widgets.** `GameLifecycleManager` (366 LOC) rebuilds
  entities into `Map<String, dynamic>`, decides who left, decides host-only
  cleanup. That is domain logic: move to a `PresenceCubit`/coordinator with a
  small interface (`onlinePlayers`, `departures` stream) and unit-test it.
- **Service locator in views** — 17 presentation files call `sl<>()`
  directly; inject via `BlocProvider`/constructor so widget tests don't need
  GetIt setup.
- **Large widgets**: `voting_phase_content.dart` (662), `game_view.dart` (535),
  `local_role_reveal_view.dart` (528), `local_mode_game_screen.dart` (500).
  Split by phase/state, not by visual chunk.
- **Pointless `try { … } catch (e) { rethrow; }`** throughout
  `room_remote_data_source.dart` — delete.
- **Mixed timestamp types**: `players.created_at`, `rounds.phase_end_time`,
  `rounds.created_at` are `timestamp without time zone`; others are
  `timestamptz`. History shows a "fix_timezone_trigger" already — migrate all
  to `timestamptz` to avoid the next timer-skew bug.
- **Self-vote detection by Arabic string match** (`game_cubit.dart:376`) —
  switch to the DB error code.

## P3 — Tests & tooling

Local run on 2026-11-16: `flutter analyze` → **No issues found**;
`flutter test` → **126 tests, all passed**. (`supabase test db` not run
locally.) Note: none of the P0/P1 findings above are caught by the current
suite — green CI does not mean these paths are safe.

- Good: cubit characterization tests, widget tests for key screens, pgTAP
  contracts for RLS/presence/chat/account deletion.
- Missing: pgTAP for #1–#3 (privilege escalation via direct table writes),
  #6 (host-crash migration), and a cubit test for concurrent
  `loadGameState` + `refreshGameStateOnResume` (#8).
- `doc/schemas/*.sql` legacy files are still in the repo; the manifest says
  "never apply" — move to `doc/schemas/legacy/` or delete to avoid accidents.
- Live Supabase project is paused; restore before running `get_advisors`
  (security + performance) to confirm the live DB matches the migration chain
  (the `production_policy_and_chat_delta` migration suggests drift existed).

## P2/P3 status (2026-11-16, branch `fix/p0-privilege-hardening`)

Done (commits `1f075c6`, `bd2be05`, `665cded`, and the widget-split commit):

| Finding | Result |
|---|---|
| #11 countdown polling in widget | `CountdownCubit`; "no round" and failed room lookup are retryable states (never guesses Online vs Shared-Device) |
| Two "watch room players" impls | `lib/core/data/room_players_watcher.dart`, ordered `created_at, id` = server's host pick |
| Presence logic in widget | `PresenceCoordinator` (plain Dart, typed notices); heartbeat only for online rooms |
| `sl<>` in views | Removed; router is the composition root. Only DI, router, `main.dart` use `sl` |
| Shallow use-cases | 30 pass-throughs deleted; `SubmitHint`/`SubmitVote` kept (own validation). `GameCubit` 10 → 2 deps |
| Large widgets | Split by phase/state: voting 662→127, game_view 535→356, local game 500→222, role reveal 510→221 |
| `try/rethrow` no-ops | Removed from `room_remote_data_source.dart` |
| Mixed timestamp types | Migration `20261116000300_timestamptz_columns.sql` + pgTAP; models parse offset-less as UTC |
| Legacy `doc/schemas` | Moved to `doc/schemas/legacy/` with a never-apply README |
| `supabase/.temp` tracked | Untracked + gitignored |

Verified locally: `flutter analyze` clean, `flutter test` 183 pass,
`supabase test db` 10 files / 212 pass.

### Remaining (on hold until a device test)

1. **Device test (owner).** Nothing above has run on a phone. Test online
   (2+ devices: create/join, hints, votes, results, host leaves mid-round,
   app background/resume) and Shared-Device (role reveal, voting, next round).
2. **Apply `timestamptz_columns` to live — NOT applied yet.** Apply in a quiet
   window via MCP `apply_migration` (never `db push`: ledger drift). Takes
   brief ACCESS EXCLUSIVE locks (15s `lock_timeout`, rolls back on timeout).
   Ship the app build with the new model parsing together with it.
3. **Ship a new app build** — host self-heal, inline errors, countdown retry
   and presence changes are client-side.
4. **Leaked Password Protection** — advisor still reported it disabled on
   2026-11-16 after the owner enabled it; re-check in the Auth dashboard
   (Settings → Password security) that it is saved.
5. Small follow-ups found during the refactor:
   - Role reveal: a successful load with an empty player list shows the
     loading spinner forever (pre-existing). Should become an error state.
   - Countdown "GO!" text is hardcoded (not localized).
   - `game_view_rules.dart` pure helpers have no unit tests yet.
   - `RoomRepository.getRoomByCode` is now unused by any cubit.
   - `message_reports` has RLS with no policies (INFO advisor; fine while
     only the definer RPC writes it).
6. Push the branch and open a PR to `master` (not done; waiting for owner).

## Suggested order of work

1. One migration: revoke direct writes (#1–#3), heartbeat RPC (#4), scoped
   SELECTs (#5) + pgTAP tests. Ship before anything else.
2. Presence: open `mark_stale_players_offline` to members / add `pg_cron` (#6).
3. `GameCubit`: inline errors (#7), subscription generation guard (#8).
4. Error-code → l10n mapping (#9, #10).
5. Refactors from P2 as you touch each area.
