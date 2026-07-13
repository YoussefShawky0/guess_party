---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are REQUIRED for critical gameplay changes. Include happy path,
edge case, disconnect, reconnect, multi-player synchronization, host migration,
and widget disposal safety coverage when those risks are affected. Tests are
optional only for non-critical documentation or visual-only work.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/core/`, `lib/features/`, `lib/shared/`
- **Feature code**: `lib/features/[feature]/data`, `domain`, and `presentation`
- **Tests**: `test/features/[feature]/` and `test/shared/`
- Paths shown below assume Guess Party's Flutter feature-first structure - adjust based on plan.md structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Verify affected Supabase tables, fields, policies, and Realtime channels
- [ ] T005 [P] Define or update domain entities and repository contracts
- [ ] T006 [P] Define Cubit states and events/actions with immutable Equatable state
- [ ] T007 Implement or update repository/data source boundaries without presentation-layer Supabase access
- [ ] T008 Configure human-friendly error handling and Sentry reporting boundaries
- [ ] T009 Verify GoRouter navigation and BuildContext safety approach
- [ ] T010 Verify Online/Shared-Device mode separation and hidden-information boundaries

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1

> **NOTE: For critical gameplay changes, write these tests FIRST and ensure they FAIL before implementation**

- [ ] T011 [P] [US1] Cubit/repository test for [state transition] in test/features/[feature]/[name]_test.dart
- [ ] T012 [P] [US1] Widget test for [user journey/context safety] in test/features/[feature]/[name]_test.dart
- [ ] T013 [P] [US1] Realtime synchronization or disconnect/reconnect test for [scenario] in test/features/[feature]/[name]_test.dart

### Implementation for User Story 1

- [ ] T014 [P] [US1] Create/update domain entity in lib/features/[feature]/domain/entities/[entity].dart
- [ ] T015 [P] [US1] Create/update model in lib/features/[feature]/data/models/[model].dart
- [ ] T016 [US1] Implement repository/use case in lib/features/[feature]/domain and data layers
- [ ] T017 [US1] Implement Cubit orchestration in lib/features/[feature]/presentation/cubit/
- [ ] T018 [US1] Implement Flutter UI in lib/features/[feature]/presentation/views/
- [ ] T019 [US1] Add recoverable validation UX and human-friendly messages
- [ ] T020 [US1] Add Sentry/error handling only for unrecoverable failures

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2

- [ ] T021 [P] [US2] Cubit/repository test for [state transition] in test/features/[feature]/[name]_test.dart
- [ ] T022 [P] [US2] Widget test for [user journey/context safety] in test/features/[feature]/[name]_test.dart

### Implementation for User Story 2

- [ ] T023 [P] [US2] Create/update domain or data model in lib/features/[feature]/
- [ ] T024 [US2] Implement use case/repository behavior in lib/features/[feature]/
- [ ] T025 [US2] Implement Cubit/UI behavior in lib/features/[feature]/presentation/
- [ ] T026 [US2] Integrate with User Story 1 components without coupling Online/Shared-Device secrets

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3

- [ ] T027 [P] [US3] Cubit/repository test for [state transition] in test/features/[feature]/[name]_test.dart
- [ ] T028 [P] [US3] Widget test for [user journey/context safety] in test/features/[feature]/[name]_test.dart

### Implementation for User Story 3

- [ ] T029 [P] [US3] Create/update domain or data model in lib/features/[feature]/
- [ ] T030 [US3] Implement use case/repository behavior in lib/features/[feature]/
- [ ] T031 [US3] Implement Cubit/UI behavior in lib/features/[feature]/presentation/

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX [P] Additional unit tests (if requested) in tests/unit/
- [ ] TXXX Security and fairness hardening for hidden role/host-only data
- [ ] TXXX Verify host migration and empty room cleanup remain intact
- [ ] TXXX Verify reconnect messaging does not stack or spam
- [ ] TXXX Run `flutter analyze`
- [ ] TXXX Run `flutter test`
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Required tests MUST be written and FAIL before implementation for critical gameplay changes
- Domain entities before models and repositories
- Repositories/use cases before Cubit orchestration
- Cubit state before UI wiring
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Cubit/repository test for [state transition] in test/features/[feature]/[name]_test.dart"
Task: "Widget test for [user journey/context safety] in test/features/[feature]/[name]_test.dart"
Task: "Realtime synchronization or disconnect/reconnect test for [scenario] in test/features/[feature]/[name]_test.dart"

# Launch independent Flutter layer tasks together:
Task: "Create/update domain entity in lib/features/[feature]/domain/entities/[entity].dart"
Task: "Create/update model in lib/features/[feature]/data/models/[model].dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
