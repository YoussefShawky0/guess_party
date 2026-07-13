# Tasks: Fix Active Navigation

**Input**: Design documents from `/specs/002-fix-active-navigation/`

**Prerequisites**: spec.md

**Tests**: Tests are REQUIRED for this critical online synchronization and navigation fix.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Confirm branch `002-fix-active-navigation` and inspect waiting-room start flow in `lib/features/room/presentation/views/waiting_room_view.dart`
- [X] T002 [P] Inspect room contracts in `lib/features/room/domain/repositories/room_repository.dart`
- [X] T003 [P] Inspect room datasource in `lib/features/room/data/datasources/room_remote_data_source.dart`
- [X] T004 [P] Inspect DI registrations in `lib/core/di/injection_container.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

- [X] T005 Add `watchRoomDetails` to `lib/features/room/domain/repositories/room_repository.dart`
- [X] T006 Add `watchRoomDetails` to `lib/features/room/data/datasources/room_remote_data_source.dart`
- [X] T007 Implement realtime room watcher in `lib/features/room/data/datasources/room_remote_data_source.dart`
- [X] T008 Implement repository passthrough in `lib/features/room/data/repositories/room_repository_impl.dart`
- [X] T009 Create `WatchRoomDetails` use case in `lib/features/room/domain/usecases/watch_room_details.dart`
- [X] T010 Register `WatchRoomDetails` in `lib/core/di/injection_container.dart`
- [X] T011 Inject room watcher into `lib/features/room/presentation/cubit/room_cubit.dart`

---

## Phase 3: User Story 1 - Non-hosts enter game when host starts (Priority: P1)

**Goal**: All connected waiting-room players navigate to countdown when room status becomes active.

**Independent Test**: Host starts an online room and every connected non-host waiting-room client transitions to countdown without manual refresh.

- [X] T012 [P] [US1] Add room watcher state transition tests in `test/features/room/presentation/cubit/room_cubit_test.dart`
- [X] T013 [P] [US1] Add waiting-room single navigation test in `test/features/room/presentation/views/waiting_room_view_test.dart`
- [X] T014 [US1] Implement `watchRoomStatus` orchestration in `lib/features/room/presentation/cubit/room_cubit.dart`
- [X] T015 [US1] Start room watching from `lib/features/room/presentation/views/waiting_room_view.dart`
- [X] T016 [US1] Move waiting-room active navigation to `BlocConsumer` listener in `lib/features/room/presentation/views/waiting_room_view.dart`

---

## Phase 4: User Story 2 - Late waiting-room state still transitions correctly (Priority: P2)

**Goal**: Players still transition when the room is already active before their subscription or rebuild catches up.

**Independent Test**: A waiting-room client opened after the host starts still transitions to countdown from the current authoritative room state.

- [X] T017 [P] [US2] Add initial-active-room emission coverage in `test/features/room/presentation/cubit/room_cubit_test.dart`
- [X] T018 [US2] Emit current room before relying on updates in `lib/features/room/data/datasources/room_remote_data_source.dart`
- [X] T019 [US2] Add fallback room polling while waiting-room cubit is alive in `lib/features/room/presentation/cubit/room_cubit.dart`

---

## Phase 5: User Story 3 - Start transition remains single and safe (Priority: P3)

**Goal**: Active updates never cause duplicate navigation or stale-context crashes.

**Independent Test**: Repeated active state updates or disposal during transition never push duplicate countdown routes or crash the waiting room.

- [X] T020 [P] [US3] Add duplicate active navigation coverage in `test/features/room/presentation/views/waiting_room_view_test.dart`
- [X] T021 [P] [US3] Add cubit close cleanup coverage in `test/features/room/presentation/cubit/room_cubit_test.dart`
- [X] T022 [US3] Cancel room watcher resources in `lib/features/room/presentation/cubit/room_cubit.dart`
- [X] T023 [US3] Add one-shot finished-room handling and mounted guards in `lib/features/room/presentation/views/waiting_room_view.dart`

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T024 Run `flutter analyze`
- [X] T025 Run `flutter test`
- [ ] T026 Manually validate host and non-host start flow for Online Mode
- [ ] T027 Verify Shared-Device Mode create/start flow is unchanged
