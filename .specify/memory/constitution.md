<!--
Sync Impact Report
Version change: 1.0.0 -> 1.0.1
Modified principles:
- II. Keep Online and Shared-Device Modes Separate: formally records the approved connected, authenticated, Supabase-backed Shared-Device product model.
Added principles:
- None
Added sections:
- None
Removed sections:
- None
Templates requiring updates:
- ✅ updated .specify/templates/plan-template.md
- ✅ updated .specify/templates/spec-template.md
- ✅ updated .specify/templates/tasks-template.md
- ✅ checked .specify/extensions/git/commands/*.md (no product-mode wording required changes)
- ✅ updated README.md
- ✅ updated AGENTS.md
- ✅ updated .github/copilot-instructions.md
Follow-up TODOs:
- None
-->
# Guess Party Constitution

## Core Principles

### I. Preserve Existing Game Flow
All changes MUST preserve the complete gameplay flow: Create Room -> Join Room ->
Role Reveal -> Hints Phase -> Voting Phase -> Results -> Next Round. Before
modifying any gameplay feature, the implementer MUST identify the affected
phase, mode, Cubit state, repository call, and navigation path. A change that
risks breaking another phase or mode MUST stop for a safer implementation plan
before code is changed.

Rationale: Guess Party depends on uninterrupted social play; fixing one issue
cannot justify regressions in another part of the round loop.

### II. Keep Online and Shared-Device Modes Separate
Online Mode and Shared-Device Mode MUST be treated as independently implemented
experiences. Screens, widgets, role reveal logic, voting flows, and phase
handling MUST NOT be tightly coupled across modes when shared code could expose
hidden information. Shared-Device Mode MUST remain pass-and-play on one device,
require connectivity and authentication, use Supabase as its authoritative
state source, and protect each player's secret character visibility. Online
Mode MUST remain synchronized multi-device multiplayer with Supabase as the
source of truth.

Rationale: The two modes have different trust boundaries and visibility rules;
convenient reuse must never leak secret game state.

### III. Supabase Is Authoritative Online
For Online Mode, all authoritative state changes MUST be written to Supabase
before local UI state changes are treated as accepted. The required order is:
update database, receive Supabase Realtime update, then update local UI state.
Critical permissions and state MUST come from Supabase fields, including
`players.is_host`, `players.is_online`, `players.last_seen_at`, `rooms.phase`,
`rooms.status`, `rooms.current_round`, and mode indicators such as `is_online`.
Presentation code MUST NOT grant host privileges, advance phases, submit votes,
or infer critical permissions from local-only state.

Rationale: Multiplayer fairness requires one authoritative state source shared
by all connected clients.

### IV. Enforce BuildContext and Navigation Safety
Flutter code MUST NOT use `BuildContext` unsafely after an async gap. After any
`await`, code that uses `context`, `Navigator`, `GoRouter`, `ScaffoldMessenger`,
or `showDialog` MUST either check `mounted` or cache the required messenger or
navigator before the await and still verify disposal safety where needed.
GoRouter navigation MUST NOT run from stale contexts, disposed widgets, or
duplicate route pushes.

Rationale: Async UI work is common in room and game flows; stale context usage
causes crashes during exactly the moments players are joining, reconnecting, or
leaving.

### V. Keep Recoverable Errors In Flow
Validation failures and user mistakes MUST stay on the current screen through
inline errors, snackbars, or dialogs. Fullscreen error pages are reserved for
unrecoverable failures, corrupted game state, or network initialization failure.
Examples of in-flow validation include self-vote attempts, invalid room codes,
duplicate actions, invalid phase actions, and non-host control attempts.

Rationale: Recoverable mistakes are part of normal play and must not eject
players from the room or phase they are trying to complete.

### VI. Host Recovery and Empty Room Cleanup Must Self-Heal
Online rooms MUST never remain without a host, with multiple hosts, or orphaned
after all players disconnect. Host migration MUST be automatic, deterministic,
and persisted through Supabase, selecting the oldest connected player as host.
Host authority MUST come only from `players.is_host`. When all players are
offline or gone, the room MUST be marked finished, subscriptions MUST stop, and
resources MUST be released. Cleanup MUST handle formal leave, crashes, app
kills, and network loss using `is_online`, `last_seen_at`, heartbeat, or
presence data.

Rationale: A multiplayer room must continue without manual recovery when the
original host disappears, and empty rooms must not consume state forever.

### VII. Realtime Synchronization and Reconnect Hygiene
Important online actions MUST propagate through Supabase Realtime, including
joins, leaves, host migration, phase changes, votes, skip actions, reconnects,
and player status changes. Client-only phase progression and hidden local-only
multiplayer state are forbidden. Reconnect UX MUST show a disconnect banner once
per disconnect cycle, show one "Back online" snackbar per reconnect cycle,
avoid snackbar stacking, and restore subscriptions automatically.

Rationale: Players must see the same room state and receive clear connection
feedback without notification spam.

### VIII. Protect Hidden Game Information
The UI, state models, repositories, and logs MUST NOT expose imposter identity,
hidden role data, unrevealed characters, or host-only actions to unauthorized
players. Shared-Device Mode MUST never show another player's secret card.
Online Mode MUST not send or render secret data where a non-authorized client
can infer it before reveal. UI decisions MUST prioritize fair gameplay, clarity,
accessibility, and responsiveness in that order.

Rationale: Social deduction games fail if the interface leaks information that
players are meant to deduce.

### IX. Use Human-Friendly Player Messaging
Player-facing errors MUST be concise, non-technical, and actionable. Messages
MUST explain what happened and, when useful, how to recover. Technical wording
such as "Exception occurred", "Invalid operation", or "Null reference" MUST NOT
be shown to players. Examples of acceptable messages include "You cannot vote
for yourself", "Room not found. Please check the code and try again", and
"Connection lost. Reconnecting...".

Rationale: Clear language keeps players oriented without exposing implementation
details or creating support burden.

### X. Keep State, Architecture, and Tests Deterministic
Feature work MUST follow Clean Architecture with feature-first folders,
repository abstractions, dependency injection, and Cubit/BLoC state management.
Cubit states MUST be immutable, comparable with Equatable where practical, and
free of contradictory transitions. Critical gameplay fixes MUST include
validation for happy paths, edge cases, disconnect scenarios, reconnect
scenarios, multi-player synchronization, host migration, and widget disposal
safety. Business logic MUST live outside widgets, and presentation code MUST NOT
access Supabase directly.

Rationale: Deterministic state and focused tests make multiplayer behavior
reviewable, replayable, and safer to change.

## Technology and Architecture Standards

Guess Party is a Flutter and Dart application. The approved stack is Flutter,
Dart, `flutter_bloc`, GoRouter, Supabase Database, Supabase Realtime, Sentry,
repository abstractions, dependency injection, and feature-first Clean
Architecture. New code MUST prefer existing project patterns in `lib/core`,
`lib/features`, and `lib/shared` before introducing new abstractions.

Authoritative online database fields MUST remain in Supabase tables rather than
duplicated as independent local truth. The core authoritative schema includes:

- `players.id`
- `players.room_id`
- `players.username`
- `players.is_host`
- `players.is_online`
- `players.last_seen_at`
- `players.created_at`
- `rooms.id`
- `rooms.phase`
- `rooms.status`
- `rooms.current_round`

Performance work MUST avoid excessive realtime subscriptions, large unnecessary
widget rebuilds, polling when Realtime is available, and repeated Supabase
queries. Implementations MUST prefer stream filtering, selective rebuilds, and
lightweight Cubit states.

Security and fairness rules are mandatory: never trust client-side permissions,
local host assumptions, or unsynced state; never expose hidden role data,
imposter identity, unrevealed character data, or admin-only controls to
non-host users.

## Development Workflow and Quality Gates

Planning and implementation MUST prioritize work in this order:

1. Crash fixes
2. Game integrity
3. Synchronization correctness
4. Host recovery systems
5. Cleanup systems
6. UX improvements
7. Visual polish

Every feature plan MUST include a Constitution Check covering gameplay flow,
mode separation, Supabase authority, BuildContext safety, recoverable error UX,
host migration, empty room cleanup, realtime synchronization, hidden
information protection, human-friendly messaging, architecture, and required
tests.

Before finalizing any implementation, reviewers MUST verify:

- No unsafe context usage after async gaps
- No hidden regressions in the game flow
- No Online/Shared-Device coupling that leaks information
- Supabase Realtime synchronization works for online actions
- Host migration still works
- Empty room cleanup still works
- Validation errors stay inline
- Fullscreen errors are used only for unrecoverable failures
- Reconnect messaging does not stack or spam
- No duplicate subscriptions are introduced
- Critical state cannot desynchronize across players
- Tests or documented validation cover the risk level of the change

If a change cannot satisfy a mandatory rule, implementation MUST stop and the
plan MUST document the conflict, the risk to gameplay integrity, and the safer
alternative.

## Governance

This constitution supersedes conflicting project practices, generated plans,
agent instructions, and informal conventions. Amendments MUST be explicit,
reviewed against affected templates and guidance docs, and recorded in the Sync
Impact Report at the top of this file.

Versioning follows semantic versioning:

- MAJOR: Backward-incompatible governance changes, principle removals, or rule
  redefinitions that materially change compliance obligations.
- MINOR: New principles, new mandatory sections, or materially expanded
  guidance.
- PATCH: Clarifications, typo fixes, or non-semantic wording refinements.

Compliance is required during planning, coding, refactoring, debugging, and code
review. Any PR or task that violates a MUST rule is blocked until the violation
is removed or the constitution is amended through this governance process.

**Version**: 1.0.1 | **Ratified**: 2026-05-21 | **Last Amended**: 2026-07-13
