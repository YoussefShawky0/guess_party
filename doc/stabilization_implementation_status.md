# Guess Party Stabilization and Release Program

## Table of Contents

- [Purpose](#purpose)
- [Locked Decisions](#locked-decisions)
- [Phase Status](#phase-status)
- [Completed Work](#completed-work)
- [Current Verification Baseline](#current-verification-baseline)
- [Environment and Production State](#environment-and-production-state)
- [Remaining Runbooks](#remaining-runbooks)
- [Delegation and Review Protocol](#delegation-and-review-protocol)
- [Mandatory Phase Gate](#mandatory-phase-gate)

## Purpose

This file is the authoritative ledger for the corrected stabilization and
release plan. It replaces the earlier candidate-backend status report, which
became obsolete after the production schema was reconstructed and verified.

The program prioritizes gameplay integrity and backend reproducibility before
release packaging. Each phase is implemented, reviewed, and accepted before the
next phase begins.

## Locked Decisions

- Supabase remains authoritative for Online and Shared-Device gameplay.
- Shared-Device Mode remains connected, authenticated pass-and-play on one
  physical device. The database wire value remains `local` for compatibility.
- Online and Shared-Device presentation and secret-bearing state stay separate.
- Canonical migrations are the only deployment authority; `doc/schemas/` is
  historical reference material.
- RPC names and client response shapes remain compatible unless a failing
  contract proves that a versioned change is required.
- No automatic Auth identity merging is permitted.
- Production Supabase, Auth, Sentry, store, signing, and application identifiers
  require separate authorization and company-owned values.
- The approved local database rebuild sequence is
  `supabase stop --no-backup` followed by
  `supabase start --ignore-health-check`; do not use `supabase db reset` on this
  machine.

## Phase Status

| Phase | Workstream | Status | Evidence |
|---:|---|---|---|
| 0 | Baseline safety and repository hygiene | Complete | Analyzer clean; bootstrap validation and public-key terminology implemented |
| 1 | Canonical Supabase foundation | Complete | Canonical migrations, seed, grants, publication, manifest, clean local construction |
| 2 | Gameplay/security contracts | Complete | RLS/RPC, redaction, scoring, capacity, hint, and vote contracts |
| 3 | Presence and host lifecycle | Complete | Deterministic host migration, reconnect, cleanup, and stale-player contracts |
| 4 | Realtime and architecture ownership | Complete | Repository/coordinator ownership and subscription-count validation |
| 5 | Gameplay presentation decomposition | Complete | Online/Shared-Device orchestration shells and phase widget tests |
| 6 | Connected Shared-Device alignment | Complete | UI, README, architecture, and constitution aligned; internal `local` value preserved |
| 7 | Authentication identity and recovery | Complete | Commit `d1e8891`; 58 Flutter tests, 71 database contracts, local Auth/gameplay smoke pass |
| 8 | Chat security and reliability | Complete | Commit `21310ff`; 66 Flutter tests, 104 database contracts, local REST/Auth chat smoke pass |
| 9 | Environment separation and observability | Implemented and locally verified; pending review/commit | 72 Flutter tests, 104 database contracts, development flavor APK build, define guard pass/fail checks |
| 10 | Release engineering | Not started; partial safeguards pre-exist | [Phase 10 runbook](phase_10_release_engineering_implementation_plan.md) |
| 11 | Platform policy, localization, accessibility | Not started | [Phase 11 runbook](phase_11_platform_localization_accessibility_plan.md) |

## Completed Work

### Phase 0

- Removed analyzer findings, unsafe asynchronous Settings navigation, and
  deprecated color API usage.
- Added validated startup configuration and a controlled fatal-startup screen.
- Migrated client initialization to publishable-key terminology with temporary
  legacy-key compatibility.
- Replaced placeholder product metadata and narrowed governance ignore rules.

### Phase 1

- Rebuilt the database from the authoritative production schema export.
- Added canonical schema, routine-grant, Realtime-publication, table-grant, and
  recursive-RLS remediation migrations.
- Preserved 29 functions, both stale-player overloads, routine grants, tables,
  constraints, indexes, triggers, and the exact eight-table Realtime
  publication.
- Tightened raw `rounds` and `votes` visibility without weakening secure RPCs.
- Seeded six production categories and 243 production characters with IDs
  preserved.
- Confirmed `round_participants` is intentionally absent from Realtime and is
  accessed through secure snapshots.

### Phase 2

- Added repository/Cubit characterization coverage for creation, start,
  hints, votes, finalization, next round, and finish.
- Added database proof for non-participant denial, host-only operations,
  identity-aware redaction, local reveal authorization, idempotent scoring,
  uniqueness, capacity, and self-vote rejection.

### Phase 3

- Added lifecycle scenarios for heartbeat, stale timeout, formal leave,
  disconnect, reconnect, host departure/reclaim, concurrent presence changes,
  and final-player cleanup.
- Verified one deterministic host, oldest-online promotion, duplicate-membership
  prevention, finished empty rooms, and disposal-safe retry behavior.

### Phase 4

- Moved route/widget database and Realtime access behind typed services and
  repositories.
- Centralized room-session and online-game lifecycle ownership.
- Removed duplicate subscription/polling owners and fixed duplicate end-game
  navigation with explicit regression coverage.

### Phase 5

- Decomposed large gameplay views into lifecycle shells, connection feedback,
  phase headers, host controls, and mode-specific phase content.
- Kept navigation at screen/coordinator boundaries and kept secret-bearing
  Online/Shared-Device components independently tested.

### Phase 6

- Renamed user-facing Local Mode to Shared Device and disclosed its connectivity
  and session requirements.
- Updated README, CTO documentation, how-to-play material, architecture
  documentation, constitution, agent guidance, and Git tracking rules.
- Preserved existing rooms by leaving `game_mode = 'local'` unchanged.

### Phase 7

- Added real-email registration/login, legacy username login, anonymous-account
  upgrade, password recovery, email-verification gating, and UID preservation.
- Added Android/iOS callback registration for
  `io.supabase.guessparty://login-callback`.
- Added single-owner navigation for expiry, recovery, and intentional logout.
- Added generic reset responses, no-merge enforcement, room-scoped display-name
  contracts, and a repeatable local Auth/gameplay smoke script.
- Physical-device email callback delivery and production SMTP/Auth settings
  remain release-environment gates.

### Phase 8

- Added a canonical chat security migration with `player_mutes`,
  `message_reports`, `send_chat_message`, `list_chat_messages`,
  `set_player_muted`, and `report_chat_message`.
- Removed direct authenticated `messages` inserts; sender identity now comes
  from `auth.uid()` membership inside the RPC.
- Added server-side content length checks, room/round membership checks, one
  player-derived sender, five-message-per-ten-second rate limiting,
  deterministic cursor pagination, mute filtering, idempotent reporting, and
  least-privilege report access.
- Moved chat history, sending, pagination, Realtime merge, deduplication, mute
  filtering, and disposal ownership into a `ChatCubit`; `ChatWidget` now
  renders state and forwards user intent.
- Added database contracts for non-member denial, direct insert blocking,
  impersonation resistance, throttling, cursor behavior, mutes, duplicate
  reports, and report moderation lockout.
- Added Flutter Cubit/widget coverage for bounded loading, older-page merge,
  Realtime deduplication, subscription cancellation, mute filtering, safe copy,
  and presentation-level send/mute behavior.

## Current Verification Baseline

The Phase 8 local baseline is:

```text
flutter analyze
No issues found!

flutter test
00:14 +66: All tests passed!

supabase test db
Files=4, Tests=103
Result: PASS

Phase 8 local REST/Auth chat smoke
Phase 8 local REST/Auth chat smoke: PASS
```

Commits containing accepted earlier work:

- `4757778` — `feat: stabilize gameplay architecture through phase 5`
- `e7ab980` — `docs: align connected shared-device mode`
- `d1e8891` — `feat: implement auth identity migration`

Phase 8 has been reviewed, committed, and pushed. Phase 9 is implemented in the
working tree and locally verified. It has not been committed, pushed, or applied
to production Supabase/Sentry.

## Environment and Production State

- No Phase 1–8 task wrote to the production Supabase project.
- Canonical migrations have been applied only to the disposable local stack.
- Local Auth uses test configuration; it is not production authorization.
- During Phase 8 verification, Kong/Auth/PostgREST and the database were
  usable locally. The Realtime container started and served logs, but Docker
  continued to mark its healthcheck unhealthy with timeout/connection messages;
  no production Realtime setting was changed.
- The app selects its backend through its runtime configuration. The local
  stack does not silently replace the deployed backend.
- Production still needs approved SMTP, callback allowlisting, Auth linking and
  confirmation policy, staging/production project values, permanent app IDs,
  and signing credentials.

## Remaining Runbooks

Implement in this exact order:

1. [Phase 8 — Chat Security and Reliability](phase_08_chat_security_implementation_plan.md)
2. [Phase 9 — Environment Separation and Observability](phase_09_environment_observability_implementation_plan.md)
3. [Phase 10 — Release Engineering](phase_10_release_engineering_implementation_plan.md)
4. [Phase 11 — Platform Policy, Localization, and Accessibility](phase_11_platform_localization_accessibility_plan.md)

## Delegation and Review Protocol

The implementation model receives only this ledger, the current phase runbook,
`AGENTS.md`, the constitution, and the relevant source files. It must implement
one phase and stop.

Its report must include:

- complete changed-file list;
- migrations and public interfaces changed;
- exact analyzer, Flutter test, and database-contract output;
- manual validation evidence;
- unresolved risks or unavailable external inputs;
- confirmation that production was not changed.

The senior reviewer then checks scope, architecture, direct Supabase access,
RLS/RPC safety, hidden-state integrity, test validity, migration compatibility,
privacy, and every acceptance criterion. A failed review returns a bounded fix
list and blocks the next phase.

## Mandatory Phase Gate

Before accepting any remaining phase:

1. Construct a clean local Supabase stack with the approved stop/start pattern.
2. Run all database/RLS/RPC contracts.
3. Run `flutter analyze` and the complete Flutter suite.
4. Run the phase-specific automated tests and smoke scripts.
5. Verify guest sign-in, create/join/start, role reveal, hints, voting, results,
   next round, leave, reconnect, and game over.
6. Verify the Shared-Device pass/reveal/vote flow without secret leakage.
7. Search for new direct Supabase access outside approved data infrastructure.
8. Record all schema, RPC, client, environment, and navigation changes.
