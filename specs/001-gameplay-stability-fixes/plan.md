# Implementation Plan: Gameplay Stability Fixes

**Branch**: `001-gameplay-stability-fixes` | **Date**: 2026-05-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-gameplay-stability-fixes/spec.md`

## Summary

Stabilize Guess Party's active gameplay by keeping validation errors in-flow,
separating Shared-Device Mode secret surfaces from Online Mode UI, and making Online
Mode self-healing for host loss, empty rooms, reconnects, leave actions, and
host-controlled phase skips. The implementation preserves the existing
feature-first Clean Architecture and routes authoritative online state through
Supabase before UI acceptance.

## Technical Context

**Language/Version**: Dart `^3.9.2` with Flutter project dependency versions from `pubspec.yaml`

**Primary Dependencies**: flutter_bloc, GoRouter, Supabase, Sentry, get_it, Equatable, dartz, flutter_test

**Storage**: Supabase Database for both modes, with Realtime synchronization where required; Shared-Device Mode remains connected and authenticated while using a separate pass-and-play presentation flow

**Testing**: flutter_test with Cubit/repository/widget tests; manual multi-player quickstart validation for realtime behavior

**Target Platform**: Flutter mobile targets (Android/iOS)

**Project Type**: Mobile app using feature-first Clean Architecture

**Performance Goals**: No duplicate realtime subscriptions, no snackbar stacking, responsive phase transitions, heartbeat every 25 seconds or existing configured cadence

**Constraints**: Online/Shared-Device mode separation, Supabase authority online, hidden information protection, BuildContext safety after async gaps, recoverable errors stay in-flow

**Scale/Scope**: Join Room, Role Reveal, Hints, Voting, Results, Next Round; affected code spans game Cubit, game repository/data source, room data source, online game view, local game view, voting widget, room join UI, shared snackbar/error helpers, and tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Game flow preserved**: PASS. Work is scoped to Create Room -> Join Room -> Role Reveal -> Hints -> Voting -> Results -> Next Round and includes final full-flow validation.
- **Mode separation protected**: PASS. Shared-Device Mode hidden information work is isolated to local screens; Online Mode keeps its synchronized view and authority rules.
- **Supabase authority online**: PASS. Online host, presence, room status, votes, skips, and phase transitions are planned as Supabase-first updates with UI changes from realtime/state refresh.
- **BuildContext safety**: PASS. All async dialogs, snackbars, and navigation tasks require `mounted` checks or cached messenger/navigator references.
- **Recoverable errors stay in flow**: PASS. Self-vote, invalid room code, duplicate actions, not-enough-players, and unauthorized host actions use inline/snackbar/dialog feedback.
- **Host recovery and cleanup intact**: PASS. Host migration and empty room cleanup are foundational tasks using deterministic oldest-online-player selection.
- **Realtime synchronization covered**: PASS. Room players, round, vote, hint, phase, reconnect, and leave changes are represented in data model and contracts.
- **Hidden information protected**: PASS. Local shared game screen must not render character or role clue cards before intended reveal/results.
- **Human-friendly messaging**: PASS. Required copy is specified for self-vote, invalid room code, host migration, leave confirmation, disconnect, and reconnect.
- **Architecture aligned**: PASS. Tasks will preserve repositories, use cases, Cubit state, DI, and presentation boundaries.
- **Validation plan complete**: PASS. Required tests cover happy path, edge cases, disconnect, reconnect, synchronization, host migration, and widget disposal safety.

## Project Structure

### Documentation (this feature)

```text
specs/001-gameplay-stability-fixes/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-behavior-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── router/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── game/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── room/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    └── widgets/

test/
├── features/
│   ├── game/
│   └── room/
└── shared/
```

**Structure Decision**: Keep changes in existing `game`, `room`, `core`, and
`shared` boundaries. Do not create a new feature module because the work
stabilizes existing gameplay flows rather than introducing a separate feature.

## Complexity Tracking

No constitution violations are planned.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
