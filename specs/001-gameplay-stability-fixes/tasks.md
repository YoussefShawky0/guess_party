# Tasks: Gameplay Stability Fixes

**Input**: Design documents from `/specs/001-gameplay-stability-fixes/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-behavior-contract.md, quickstart.md

**Tests**: Required for this feature because the constitution marks crash fixes,
game integrity, synchronization, host recovery, cleanup, and widget disposal
safety as critical gameplay work.

**Organization**: Tasks are grouped by user story so each story can be
implemented and validated independently after foundational tasks are complete.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: User story label from `spec.md`; only used in user story phases.
- Every task includes an exact file path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create test scaffolding and confirm the feature context before implementation.

- [ ] T001 Create test helper directory structure in test/features/game/, test/features/room/, and test/shared/
- [ ] T002 [P] Create reusable Player, RoundInfo, Character, and GameState test factories in test/features/game/game_test_factories.dart
- [ ] T003 [P] Create a widget pump helper with MaterialApp, ScaffoldMessenger, and GoRouter-safe defaults in test/shared/widget_test_harness.dart
- [ ] T004 [P] Create fake GameRepository and fake use case helpers for GameCubit tests in test/features/game/fakes/fake_game_repository.dart
- [ ] T005 [P] Create fake RoomRepository or RoomCubit helpers for room join tests in test/features/room/fakes/fake_room_repository.dart
- [ ] T006 Review the Supabase host migration design and keep all schema changes documented in doc/schemas/fix_host_migration_and_room_cleanup.sql
- [ ] T007 Confirm the feature plan paths and artifact references in specs/001-gameplay-stability-fixes/plan.md

**Checkpoint**: Test helpers and feature context are ready.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared model, repository, and validation infrastructure required before user stories.

**Critical**: No user story implementation starts until this phase is complete.

- [ ] T008 Add `lastSeenAt` to Player entity equality and constructor in lib/features/auth/domain/entities/player.dart
- [ ] T009 Add `last_seen_at` parsing, serialization, and copy-safe defaults to PlayerModel in lib/features/auth/data/models/player_model.dart
- [ ] T010 [P] Add PlayerModel last_seen_at parsing tests in test/features/auth/data/models/player_model_test.dart
- [ ] T011 Add exact user-friendly mappings for self-vote, invalid room code, not-enough-players, room full, already started, and connection loss in lib/core/utils/error_handler.dart
- [ ] T012 [P] Add ErrorHandler mapping tests for all recoverable gameplay messages in test/core/utils/error_handler_test.dart
- [ ] T013 Add deduped snackbar helpers for info, success, warning, and room-code errors in lib/shared/widgets/error_snackbar.dart
- [ ] T014 [P] Add snackbar helper widget tests proving hide-then-show behavior and exact text in test/shared/widgets/error_snackbar_test.dart
- [ ] T015 Extend RoomRemoteDataSource with a `markStalePlayersOffline` method that calls the existing cleanup RPC in lib/features/room/data/datasources/room_remote_data_source.dart
- [ ] T016 Extend RoomRepository and RoomRepositoryImpl with `markStalePlayersOffline` in lib/features/room/domain/repositories/room_repository.dart and lib/features/room/data/repositories/room_repository_impl.dart
- [ ] T017 Register any new room cleanup use case in lib/core/di/injection_container.dart
- [ ] T018 Add `requestingPlayerId` to AdvancePhase use case parameters in lib/features/game/domain/usecases/advance_phase.dart
- [ ] T019 Update GameRepository.advancePhase signature to require `requestingPlayerId` in lib/features/game/domain/repositories/game_repository.dart
- [ ] T020 Update GameRepositoryImpl.advancePhase to verify `players.is_host = true` for `requestingPlayerId` before changing phase in lib/features/game/data/repositories/game_repository_impl.dart
- [ ] T021 Update GameCubit.progressPhase to pass the current room player id into advancePhase in lib/features/game/presentation/cubit/game_cubit.dart
- [ ] T022 Update all progressPhase call sites to pass through the new Cubit behavior without direct repository access in lib/features/game/presentation/views/game_view.dart and lib/features/game/presentation/views/local_mode_game_screen.dart

**Checkpoint**: Shared model fields, recoverable messages, cleanup RPC access, and host-authorized phase advancement are ready.

---

## Phase 3: User Story 1 - Vote Safely Without Flow Breaks (Priority: P1)

**Goal**: Self-vote attempts never crash, never open a full-screen error, and keep players in voting.

**Independent Test**: Start Local or Online voting, attempt self-vote, and verify `You cannot vote for yourself` appears in-flow with no ErrorScreen.

### Tests for User Story 1

- [ ] T023 [P] [US1] Add GameCubit self-vote test that emits GameLoaded.nonFatalMessage and never calls submitVote in test/features/game/presentation/cubit/game_cubit_vote_test.dart
- [ ] T024 [P] [US1] Add GameCubit test that repository self-vote failure text does not emit GameError in test/features/game/presentation/cubit/game_cubit_vote_test.dart
- [ ] T025 [P] [US1] Add VotingPhaseContent online self-vote widget test proving snackbar text and no ErrorScreen in test/features/game/presentation/views/widgets/voting_phase_content_test.dart
- [ ] T026 [P] [US1] Add VotingPhaseContent local dialog self-vote widget test proving dialog stays open safely and snackbar appears in test/features/game/presentation/views/widgets/voting_phase_content_test.dart
- [ ] T027 [P] [US1] Add disposal safety widget test for local self-vote dialog closing during async vote handling in test/features/game/presentation/views/widgets/voting_phase_content_disposal_test.dart

### Implementation for User Story 1

- [ ] T028 [US1] Update GameCubit.sendVote to emit one nonFatalMessage for self-vote and return without repository write in lib/features/game/presentation/cubit/game_cubit.dart
- [ ] T029 [US1] Update GameCubit.sendVote failure handling so self-vote and validation failures remain GameLoaded instead of GameError in lib/features/game/presentation/cubit/game_cubit.dart
- [ ] T030 [US1] Update VotingPhaseContent online vote handling to use ErrorSnackBar for self-vote and avoid any async BuildContext usage after await in lib/features/game/presentation/views/widgets/voting_phase_content.dart
- [ ] T031 [US1] Update VotingPhaseContent local target dialog to use dialogContext only for dialog navigation and parent context only after mounted checks in lib/features/game/presentation/views/widgets/voting_phase_content.dart
- [ ] T032 [US1] Update GameView BlocConsumer listener to show GameLoaded.nonFatalMessage once per nonFatalMessageId and never navigate for validation messages in lib/features/game/presentation/views/game_view.dart
- [ ] T033 [US1] Update LocalModeGameScreen BlocConsumer listener to show GameLoaded.nonFatalMessage and avoid ErrorScreen for self-vote validation in lib/features/game/presentation/views/local_mode_game_screen.dart

**Checkpoint**: US1 is complete when all self-vote tests pass and both modes stay on voting.

---

## Phase 4: User Story 2 - Protect Shared-Device Mode Secrets (Priority: P1)

**Goal**: Local shared screens do not expose secret character, placeholder card, role clue, or imposter information before intended reveal/results.

**Independent Test**: Start Shared-Device Mode, complete private reveal, inspect hints and voting shared screens, and confirm no secret card surface appears.

### Tests for User Story 2

- [ ] T034 [P] [US2] Add LocalModeGameScreen hints widget test proving no CharacterCard, no character name, and no placeholder card text before results in test/features/game/presentation/views/local_mode_game_screen_secret_test.dart
- [ ] T035 [P] [US2] Add LocalModeGameScreen voting widget test proving no CharacterCard, no imposter id/name, and no role clue before results in test/features/game/presentation/views/local_mode_game_screen_secret_test.dart
- [ ] T036 [P] [US2] Add LocalRoleRevealView private reveal widget test proving only current player reveal data is shown in test/features/game/presentation/views/local_role_reveal_view_test.dart
- [ ] T037 [P] [US2] Add online GameView character card regression test proving Online Mode still renders expected character visibility rules in test/features/game/presentation/views/game_view_character_card_test.dart

### Implementation for User Story 2

- [ ] T038 [US2] Remove the `_buildLocalCharacterCard` shared-screen card and its call from LocalModeGameScreen before results in lib/features/game/presentation/views/local_mode_game_screen.dart
- [ ] T039 [US2] Replace LocalModeGameScreen hidden-character copy with neutral phase instructions that mention no character, role, imposter, or card in lib/features/game/presentation/views/local_mode_game_screen.dart
- [ ] T040 [US2] Audit LocalModeGameContent for shared secret surfaces and remove any character/role card from active local phases in lib/features/game/presentation/views/widgets/local_mode_game_content.dart
- [ ] T041 [US2] Keep LocalRoleRevealView as the only pre-results local secret reveal surface and add comments only where needed to explain the privacy boundary in lib/features/game/presentation/views/local_role_reveal_view.dart
- [ ] T042 [US2] Ensure CharacterCard remains used only by Online Mode or explicit results/reveal contexts in lib/features/game/presentation/views/widgets/character_card.dart

**Checkpoint**: US2 is complete when Shared-Device Mode shared active screens contain no hidden-information surface and Online Mode is unchanged.

---

## Phase 5: User Story 3 - Keep Online Rooms Playable After Host Loss (Priority: P2)

**Goal**: Host loss automatically migrates authority to the oldest connected remaining player and all clients update from realtime state.

**Independent Test**: Disconnect the host in an online room with at least three players and verify one new host, one notice, and working host controls.

### Tests for User Story 3

- [ ] T043 [P] [US3] Add PlayerModel test for is_host, is_online, created_at ordering, and last_seen_at mapping in test/features/auth/data/models/player_model_test.dart
- [ ] T044 [P] [US3] Add GameCubit watchRoomPlayers test proving host changes update GameLoaded.players without GameError in test/features/game/presentation/cubit/game_cubit_presence_test.dart
- [ ] T045 [P] [US3] Add GameView presence notification widget test proving `{username} is now the host` appears once per new host id in test/features/game/presentation/views/game_view_presence_test.dart
- [ ] T046 [P] [US3] Add host control widget test proving old host loses skip controls and new host gains them after players update in test/features/game/presentation/views/game_view_host_controls_test.dart

### Implementation for User Story 3

- [ ] T047 [US3] Make doc/schemas/fix_host_migration_and_room_cleanup.sql idempotently enforce one online host by clearing other `is_host` values when a new host is selected
- [ ] T048 [US3] Make doc/schemas/fix_host_migration_and_room_cleanup.sql select the new host by `created_at ASC` among `is_online = true` players only
- [ ] T049 [US3] Make RoomRemoteDataSource.leaveRoom update only the leaving player presence and rely on database reconciliation for host migration in lib/features/room/data/datasources/room_remote_data_source.dart
- [ ] T050 [US3] Make GameRemoteDataSource.watchPlayersChanges sort by created_at and include `is_host`, `is_online`, and `last_seen_at` in emitted PlayerModel rows in lib/features/game/data/datasources/game_remote_data_source.dart
- [ ] T051 [US3] Make GameView resolve host controls exclusively from current Player.isHost in GameLoaded.players in lib/features/game/presentation/views/game_view.dart
- [ ] T052 [US3] Make GameLifecycleManager host migration notifications dedupe by new host player id in lib/features/game/presentation/views/game_view.dart
- [ ] T053 [US3] Ensure reconnecting old host does not regain controls unless latest GameLoaded.players marks it host in lib/features/game/presentation/views/game_view.dart

**Checkpoint**: US3 is complete when one and only one online host exists after host loss and UI controls follow realtime player state.

---

## Phase 6: User Story 4 - Clean Up Empty Online Rooms (Priority: P2)

**Goal**: Empty online rooms become finished within the cleanup window without affecting other rooms.

**Independent Test**: Leave or disconnect all players from one room and verify only that room becomes finished within 10 seconds of cleanup detection.

### Tests for User Story 4

- [ ] T054 [P] [US4] Add RoomRemoteDataSource cleanup RPC test with fake Supabase client or repository fake proving `mark_stale_players_offline` is called with stale seconds in test/features/room/data/datasources/room_remote_data_source_cleanup_test.dart
- [ ] T055 [P] [US4] Add RoomLifecycleManager or GameLifecycleManager disposal test proving heartbeat stops and offline status is requested on dispose/deactivate in test/features/game/presentation/views/game_lifecycle_manager_test.dart
- [ ] T056 [P] [US4] Add SQL text regression test checking cleanup function updates only rooms with no online players in test/doc/schemas/host_cleanup_sql_test.dart

### Implementation for User Story 4

- [ ] T057 [US4] Update doc/schemas/fix_host_migration_and_room_cleanup.sql so `reconcile_room_after_presence_change` marks only the target room finished when online count is zero
- [ ] T058 [US4] Update doc/schemas/fix_host_migration_and_room_cleanup.sql so `mark_stale_players_offline` includes `waiting` and `active` rooms and triggers reconciliation through `is_online` updates
- [ ] T059 [US4] Call `markStalePlayersOffline` during online heartbeat or presence refresh without blocking gameplay in lib/features/game/presentation/views/game_view.dart
- [ ] T060 [US4] Call `markStalePlayersOffline` from waiting-room lifecycle presence handling when applicable in lib/features/room/presentation/views/widgets/room_lifecycle_manager.dart
- [ ] T061 [US4] Ensure room status listeners navigate away only for finished room updates for the current room in lib/features/room/presentation/views/widgets/room_status_listener.dart
- [ ] T062 [US4] Add quickstart note that the SQL script must be applied before validating empty room cleanup in specs/001-gameplay-stability-fixes/quickstart.md

**Checkpoint**: US4 is complete when all-online-empty rooms finish and unrelated rooms remain active.

---

## Phase 7: User Story 5 - Let Hosts Advance Hints Responsibly (Priority: P3)

**Goal**: Current online host can confirm skip from hints to voting; non-hosts and old hosts cannot.

**Independent Test**: In online hints with at least two connected players, only host sees skip, confirmation appears, and all players move to voting together.

### Tests for User Story 5

- [ ] T063 [P] [US5] Add GameRepositoryImpl.advancePhase authorization test proving non-host requester gets validation failure and no phase update in test/features/game/data/repositories/game_repository_impl_phase_test.dart
- [ ] T064 [P] [US5] Add GameCubit.progressPhase test proving not-enough-connected-players emits nonFatalMessage instead of GameError in test/features/game/presentation/cubit/game_cubit_phase_test.dart
- [ ] T065 [P] [US5] Add GameView host skip widget test proving skip appears only for current host during hints in test/features/game/presentation/views/game_view_host_skip_test.dart
- [ ] T066 [P] [US5] Add GameView host skip confirmation test proving confirm calls progressPhase once and cancel calls nothing in test/features/game/presentation/views/game_view_host_skip_test.dart

### Implementation for User Story 5

- [ ] T067 [US5] Restrict the online skip button to GamePhase.hints only and keep voting results under the existing Show Results flow in lib/features/game/presentation/views/game_view.dart
- [ ] T068 [US5] Use confirmation copy `Are you sure you want to skip to voting?` for host hints skip in lib/features/game/presentation/views/game_view.dart
- [ ] T069 [US5] Disable host skip while fewer than two connected online players are in the current round and surface a nonFatalMessage in lib/features/game/presentation/cubit/game_cubit.dart
- [ ] T070 [US5] Ensure confirmed host skip writes phase change through GameRepository.advancePhase before UI accepts the transition in lib/features/game/data/repositories/game_repository_impl.dart
- [ ] T071 [US5] Ensure RoundHeaderWidget timer-driven hints phase advancement uses the same host-authorized Cubit path in lib/features/game/presentation/views/widgets/round_header_widget.dart and lib/features/game/presentation/views/game_view.dart

**Checkpoint**: US5 is complete when host skip is authorized, confirmed, and synchronized.

---

## Phase 8: User Story 6 - Prevent Accidental Mid-Game Leaving (Priority: P3)

**Goal**: Active online leave attempts require confirmation, remaining players get one notice, and reconnect feedback does not stack.

**Independent Test**: During hints/voting, back and leave actions show confirmation; confirmed leave notifies others; reconnect message appears once.

### Tests for User Story 6

- [ ] T072 [P] [US6] Add GameView leave confirmation widget test for hints and voting phases in test/features/game/presentation/views/game_view_leave_test.dart
- [ ] T073 [P] [US6] Add GameView leave cancellation test proving no leave use case call and no navigation in test/features/game/presentation/views/game_view_leave_test.dart
- [ ] T074 [P] [US6] Add GameView confirmed leave test proving LeaveRoom is called with current player id and host flag in test/features/game/presentation/views/game_view_leave_test.dart
- [ ] T075 [P] [US6] Add reconnect snackbar widget test proving `Back online. Game synced.` appears once per reconnect cycle in test/features/game/presentation/views/game_view_reconnect_test.dart
- [ ] T076 [P] [US6] Add presence leave notification widget test proving one `{username} has left the game` per player event in test/features/game/presentation/views/game_view_presence_test.dart

### Implementation for User Story 6

- [ ] T077 [US6] Cache navigator or route action before async leave work and check context.mounted after dialogs in lib/features/game/presentation/views/game_view.dart
- [ ] T078 [US6] Keep PopScope active during hints and voting and route all back/leave actions through `_handleLeaveGame` in lib/features/game/presentation/views/game_view.dart
- [ ] T079 [US6] Ensure `_handleLeaveGame` calls LeaveRoom before navigating home and never navigates after disposal in lib/features/game/presentation/views/game_view.dart
- [ ] T080 [US6] Dedupe leave/disconnect snackbars by player id and event key in GameLifecycleManager in lib/features/game/presentation/views/game_view.dart
- [ ] T081 [US6] Dedupe reconnect snackbar by reconnect cycle and cooldown in GameViewContent in lib/features/game/presentation/views/game_view.dart
- [ ] T082 [US6] Ensure lifecycle heartbeat sets current player offline on inactive/paused/detached and online on resume in lib/features/game/presentation/views/game_view.dart

**Checkpoint**: US6 is complete when leave and reconnect UX is clear, deduped, and context-safe.

---

## Phase 9: User Story 7 - Make Invalid Room Codes Clear (Priority: P4)

**Goal**: Invalid room codes show exact friendly copy, distinct styling, and clear on edit.

**Independent Test**: Enter an invalid room code, see the exact error message, edit the field, and verify the error clears.

### Tests for User Story 7

- [ ] T083 [P] [US7] Add RoomRemoteDataSource getRoomByCode test proving no-room errors map to exact friendly message in test/features/room/data/datasources/room_remote_data_source_test.dart
- [ ] T084 [P] [US7] Add ErrorHandler invalid room code mapping test for exact copy in test/core/utils/error_handler_test.dart
- [ ] T085 [P] [US7] Add JoinRoomView invalid room code widget test proving error icon, red styling, exact copy, and no navigation in test/features/room/presentation/views/join_room_view_test.dart
- [ ] T086 [P] [US7] Add JoinRoomView edit-after-error widget test proving the error clears when input changes in test/features/room/presentation/views/join_room_view_test.dart

### Implementation for User Story 7

- [ ] T087 [US7] Change RoomRemoteDataSource.getRoomByCode no-row error to `Room not found. Please check the code and try again.` in lib/features/room/data/datasources/room_remote_data_source.dart
- [ ] T088 [US7] Change ErrorHandler invalid room code mapping to `Room not found. Please check the code and try again.` in lib/core/utils/error_handler.dart
- [ ] T089 [US7] Update JoinRoomView room-code banner title/body to the exact friendly copy and keep the player on the join screen in lib/features/room/presentation/views/join_room_view.dart
- [ ] T090 [US7] Add an error-state parameter to RoomCodeInput so border/icon styling can reflect invalid room code state in lib/features/room/presentation/views/widgets/room_code_input.dart
- [ ] T091 [US7] Wire JoinRoomView `_clearRoomCodeError` to clear both banner and input error state on edit in lib/features/room/presentation/views/join_room_view.dart

**Checkpoint**: US7 is complete when invalid room code feedback is obvious, exact, and cleared by editing.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Validate the whole stabilization feature and keep regressions out.

- [ ] T092 Run Dart formatting on touched Dart files only and review diffs in lib/features/game/, lib/features/room/, lib/core/, lib/shared/, and test/
- [ ] T093 Run `flutter analyze` from pubspec.yaml and fix all new issues in lib/ and test/
- [ ] T094 Run `flutter test` from pubspec.yaml and fix all failing tests in test/
- [ ] T095 Manually validate Local self-vote from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T096 Manually validate Online self-vote from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T097 Manually validate Local hidden information from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T098 Manually validate Host migration from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T099 Manually validate Empty room cleanup from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T100 Manually validate Host skip from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T101 Manually validate Mid-game leave and reconnect from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T102 Manually validate Invalid room code from specs/001-gameplay-stability-fixes/quickstart.md
- [ ] T103 Update specs/001-gameplay-stability-fixes/quickstart.md with any final manual validation caveats discovered during testing
- [ ] T104 Review all changed files for unsafe BuildContext usage after async gaps in lib/features/game/, lib/features/room/, and lib/shared/
- [ ] T105 Review all changed files for Online/Shared-Device mode coupling and hidden information leaks in lib/features/game/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 and US2 (P1)**: Start after Foundational; both are MVP-critical and can proceed in parallel after shared helpers exist.
- **US3 and US4 (P2)**: Start after Foundational; US4 depends on the SQL/RPC shape confirmed in US3 tasks T047-T050.
- **US5 (P3)**: Depends on Foundational and US3 host authority rules.
- **US6 (P3)**: Depends on Foundational; benefits from US3/US4 presence cleanup but can be developed with fakes.
- **US7 (P4)**: Depends on Foundational only.
- **Polish**: Depends on all desired stories.

### User Story Completion Order

1. US1 Vote Safely Without Flow Breaks
2. US2 Protect Shared-Device Mode Secrets
3. US3 Keep Online Rooms Playable After Host Loss
4. US4 Clean Up Empty Online Rooms
5. US5 Let Hosts Advance Hints Responsibly
6. US6 Prevent Accidental Mid-Game Leaving
7. US7 Make Invalid Room Codes Clear

### Parallel Opportunities

- T002-T005 can run in parallel after T001.
- T010, T012, and T014 can run in parallel after their target files are understood.
- Test tasks inside each user story can run in parallel before implementation.
- US1 and US2 can run in parallel after Phase 2.
- US7 can run in parallel with online host/cleanup work after Phase 2.

---

## Parallel Example: User Story 1

```powershell
# Independent tests that can be written together:
Task: "T023 Add GameCubit self-vote test in test/features/game/presentation/cubit/game_cubit_vote_test.dart"
Task: "T025 Add VotingPhaseContent online self-vote widget test in test/features/game/presentation/views/widgets/voting_phase_content_test.dart"
Task: "T027 Add disposal safety widget test in test/features/game/presentation/views/widgets/voting_phase_content_disposal_test.dart"
```

## Parallel Example: User Story 3

```powershell
# Independent tests that can be written together:
Task: "T044 Add GameCubit watchRoomPlayers test in test/features/game/presentation/cubit/game_cubit_presence_test.dart"
Task: "T045 Add GameView presence notification widget test in test/features/game/presentation/views/game_view_presence_test.dart"
Task: "T046 Add host control widget test in test/features/game/presentation/views/game_view_host_controls_test.dart"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 and US2.
3. Run `flutter analyze`, `flutter test`, and manual Local/Online self-vote plus Local hidden-info checks.

### Incremental Delivery

1. Deliver P1 crash/game-integrity fixes first.
2. Deliver P2 host migration and empty room cleanup next.
3. Deliver P3 pacing and leave/reconnect UX.
4. Deliver P4 invalid room code polish.
5. Run full quickstart validation before considering the feature done.

### Cheaper LLM Guardrails

- Implement one task at a time in task ID order unless a task is marked `[P]`.
- Do not change files outside the task path unless a compile error proves a direct dependency must change.
- Do not convert recoverable validation into `GameError`.
- Do not add Supabase calls directly to presentation for new authoritative behavior.
- Do not reuse Online Mode secret widgets in Shared-Device Mode shared screens.
