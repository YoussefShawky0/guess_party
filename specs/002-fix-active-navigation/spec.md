# Feature Specification: Fix Active Navigation

**Feature Branch**: `002-fix-active-navigation`

**Created**: 2026-05-22

**Status**: Draft

**Input**: User description: "Game starts but only host navigates to game screen. When host presses Start, only host's device goes to the game screen - other players stay on waiting room. The room status changes to active in Supabase but non-host players don't react to it. Please investigate the Realtime subscription in the waiting room for non-host players and fix the navigation trigger so all players navigate when status becomes active."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Non-hosts enter game when host starts (Priority: P1)

As a non-host player waiting in an online room, I need my device to move to the game screen when the host starts the game so that every player begins the round together.

**Why this priority**: This is the primary failure. If non-host players stay in the waiting room after the room becomes active, Online Mode cannot start a playable session.

**Independent Test**: Can be fully tested with one host and at least one non-host in the same online room: the host starts the game, and each connected non-host reaches the game screen without manual refresh, leaving, or rejoining.

**Acceptance Scenarios**:

1. **Given** an online room with one host and one connected non-host on the waiting room, **When** the host starts the game and the room becomes active, **Then** both devices navigate to the game screen.
2. **Given** an online room with one host and multiple connected non-hosts on the waiting room, **When** the host starts the game and the room becomes active, **Then** every connected player navigates to the same game session.
3. **Given** a non-host joins an online room before the host starts the game, **When** the room becomes active while the non-host remains on the waiting room, **Then** the non-host reacts automatically without needing a manual action.

---

### User Story 2 - Late waiting-room state still transitions correctly (Priority: P2)

As a player whose device receives the active room state after a delay, I need the waiting room to recognize that the game already started so I am not stranded on a stale screen.

**Why this priority**: Network timing can differ across devices. The start transition must be reliable even when a player receives the active status after the host has already moved on.

**Independent Test**: Can be tested by starting an online room while a non-host has delayed connectivity, then confirming the non-host moves to the game screen as soon as the active room state is observed.

**Acceptance Scenarios**:

1. **Given** a connected non-host is still shown on the waiting room, **When** the latest room state indicates the game is active, **Then** the app navigates that player to the game screen.
2. **Given** the waiting room is recreated or refreshed after the room is already active, **When** the current room state is loaded, **Then** the player is routed to the game screen instead of remaining in the waiting room.

---

### User Story 3 - Start transition remains single and safe (Priority: P3)

As any online player, I need the waiting-room transition to happen once and only when the room is actually active so that the app does not push duplicate game screens or navigate from stale UI state.

**Why this priority**: Duplicate or unsafe navigation can create crashes, confusing back stacks, or inconsistent gameplay after the start event.

**Independent Test**: Can be tested by triggering or receiving repeated active room updates and verifying the player reaches one game screen with no duplicate navigation, crash, or flicker.

**Acceptance Scenarios**:

1. **Given** the waiting room receives more than one update showing the room is active, **When** navigation has already started or completed, **Then** no duplicate game-screen navigation occurs.
2. **Given** a player leaves the waiting room or the waiting room is disposed during a start transition, **When** an active room update arrives afterward, **Then** the app does not crash or navigate from an invalid screen.

### Edge Cases

- If a non-host reconnects after the room has already become active, the player should be sent to the game screen when their current room state is restored.
- If a player has formally left the room before the room becomes active, that player should not be navigated into the game.
- If a room becomes finished, cancelled, or unavailable instead of active, waiting-room players should remain in a recoverable flow with a human-friendly message or be returned through the existing room-exit behavior.
- If the host disconnects while starting the game, the final observed room state determines navigation: active rooms take connected players to the game screen, while non-active rooms keep players in the waiting room or existing recovery flow.
- Repeated active notifications must not create duplicate navigation events or repeated game-screen entries.
- Shared-Device Mode is not affected and must not receive online waiting-room navigation behavior.

## Gameplay Integrity & Mode Scope *(mandatory for game features)*

- **Affected Mode(s)**: Online Mode only.
- **Affected Phase(s)**: Join Room and the transition from waiting room to Role Reveal/game start.
- **Hidden Information Risk**: Low. The change only routes eligible players into the already-started game and must not reveal roles, imposter identity, unrevealed characters, or host-only controls before the appropriate game phase.
- **Authoritative State**: The shared online room status is the source of truth for whether the waiting room should transition to active gameplay. The UI must not treat a host-only local action as sufficient for non-host navigation.
- **Host/Disconnect Impact**: Connected non-hosts must react to the active room state. Host disconnect recovery remains governed by existing online room recovery behavior and must not be weakened.
- **Recoverable Validation UX**: Players who cannot enter because they left, lost access, or the room is no longer available should receive existing human-friendly in-flow feedback rather than a crash or technical error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST navigate every connected online waiting-room player to the game screen when the shared room status becomes active.
- **FR-002**: Non-host players MUST observe active room status changes while they remain on the waiting room.
- **FR-003**: The waiting room MUST evaluate the current room status when it is loaded or refreshed, so players are not stranded if the room is already active.
- **FR-004**: The start transition MUST be based on authoritative shared room status, not only on the host's local button action.
- **FR-005**: The system MUST prevent duplicate navigation when active room status is observed more than once.
- **FR-006**: The system MUST avoid navigating players who are no longer eligible for the room, including players who already left or are no longer associated with the room.
- **FR-007**: The transition MUST preserve Online Mode and Shared-Device Mode separation; Shared-Device Mode behavior MUST remain unchanged.
- **FR-008**: The transition MUST NOT expose hidden role, imposter, unrevealed character, or host-only information to unauthorized players.
- **FR-009**: If a waiting-room player cannot enter the game due to a recoverable room state problem, the system MUST keep the player in an understandable flow with human-friendly feedback.
- **FR-010**: The transition MUST be safe when the waiting room closes, refreshes, or is no longer visible during the status change.

### Key Entities *(include if feature involves data)*

- **Online Room**: Represents the shared multiplayer room, including its lifecycle status and whether gameplay has started.
- **Online Player**: Represents a participant in the room, including whether the player is connected, eligible, and host or non-host.
- **Waiting Room Session**: Represents a player's current waiting-room view and its responsibility to react to room lifecycle changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a two-player online room, 100% of connected non-host players reach the game screen within 3 seconds after the room becomes active during manual validation.
- **SC-002**: In an online room with at least four connected players, all connected players reach the game screen after the host starts the game in at least 9 out of 10 repeated start attempts.
- **SC-003**: Repeated active room updates produce no duplicate game-screen entries or visible repeated navigation in validation runs.
- **SC-004**: No waiting-room crash occurs when an active status update arrives after the waiting room has been closed or refreshed.
- **SC-005**: Shared-Device Mode start behavior remains unchanged in regression validation.

## Assumptions

- The issue is limited to Online Mode waiting-room navigation and does not require changing Shared-Device Mode.
- A player who is still connected and associated with the room when it becomes active is eligible to enter the game.
- Existing room recovery behavior handles host disconnects, finished rooms, and unavailable rooms; this feature must not replace those broader recovery rules.
- The game screen already has enough context to load the active online session once navigation occurs.
