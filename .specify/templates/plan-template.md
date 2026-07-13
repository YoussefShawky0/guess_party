# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart [version] with Flutter [version] or NEEDS CLARIFICATION

**Primary Dependencies**: flutter_bloc, GoRouter, Supabase, Sentry, get_it, Equatable or NEEDS CLARIFICATION

**Storage**: Supabase Database for Online and connected Shared-Device modes, with Realtime where required, or N/A

**Testing**: flutter_test with Cubit/repository/widget validation or NEEDS CLARIFICATION

**Target Platform**: Flutter mobile targets (Android/iOS) or NEEDS CLARIFICATION

**Project Type**: Mobile app using feature-first Clean Architecture

**Performance Goals**: Responsive gameplay UI, minimal rebuilds, no redundant realtime subscriptions or NEEDS CLARIFICATION

**Constraints**: Online/Shared-Device mode separation, Supabase authority for both modes, hidden information protection, BuildContext safety

**Scale/Scope**: Number of affected game phases, screens, repositories, Cubits, and synchronized player actions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Answer each gate with PASS/FAIL plus concrete evidence. FAIL requires a
Complexity Tracking entry and a safer alternative before implementation.

- **Game flow preserved**: Identifies affected phase(s) in Create Room -> Join Room -> Role Reveal -> Hints -> Voting -> Results -> Next Round and avoids regressions.
- **Mode separation protected**: States whether Online Mode, Shared-Device Mode, or both are affected; no shared UI/state leaks hidden information.
- **Supabase authority online**: Online authoritative changes write to Supabase first and update UI from Realtime.
- **BuildContext safety**: Async UI/navigation work uses `mounted` checks or cached messenger/navigator patterns.
- **Recoverable errors stay in flow**: Validation failures use inline errors, snackbars, or dialogs, not fullscreen error pages.
- **Host recovery and cleanup intact**: Host migration, single-host invariant, and empty room cleanup remain valid.
- **Realtime synchronization covered**: Joins, leaves, votes, phase changes, skips, reconnects, and player status changes propagate through Realtime when affected.
- **Hidden information protected**: Imposter identity, role data, unrevealed characters, and host-only controls remain private.
- **Human-friendly messaging**: Player-facing errors are concise, non-technical, and actionable.
- **Architecture aligned**: Uses feature-first Clean Architecture, repositories, DI, Cubit/BLoC, immutable Equatable states where practical.
- **Validation plan complete**: Critical gameplay work covers happy path, edge cases, disconnect, reconnect, synchronization, host migration, and widget disposal safety.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── error/
│   ├── router/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   └── [feature]/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── cubit/
│           └── views/
└── shared/
    ├── presentation/
    └── widgets/

test/
├── features/
│   └── [feature]/
└── shared/
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., shared Online/Shared-Device widget] | [current need] | [why separate mode-specific widgets are insufficient] |
| [e.g., local optimistic UI] | [specific problem] | [why Supabase-first Realtime update is insufficient] |
