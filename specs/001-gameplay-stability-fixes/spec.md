# Feature Specification: Gameplay Stability Fixes

**Feature Branch**: `001-gameplay-stability-fixes`

**Created**: 2026-05-21

**Status**: Draft

**Input**: User description: "read plan.md and constitution.md and make best practice"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vote Safely Without Flow Breaks (Priority: P1)

As a player in either Shared-Device Mode or Online Mode, I need invalid vote attempts to
be handled without crashes or full-screen interruptions so the voting phase can
continue normally.

**Why this priority**: Voting is a critical active-game phase. A crash or
navigation away from the voting screen stops the round and damages trust in the
game.

**Independent Test**: Start a round, enter the voting phase, attempt to vote for
yourself, and verify the player remains in the voting screen with a clear
message and no crash.

**Acceptance Scenarios**:

1. **Given** a Shared-Device Mode player is voting, **When** they select their own name,
   **Then** the game shows "You cannot vote for yourself" and remains on the
   voting screen.
2. **Given** an Online Mode player is voting, **When** they select their own
   name, **Then** the game shows "You cannot vote for yourself" without opening
   a full-screen error.
3. **Given** a voting screen is closed during a pending action, **When** the
   action completes, **Then** no crash or stale-screen message is shown.

---

### User Story 2 - Protect Shared-Device Mode Secrets (Priority: P1)

As a Shared-Device Mode group sharing one device, we need the shared game screen to hide
secret character and role information so the Imposter cannot infer hidden
information before or during role reveal.

**Why this priority**: Secret leakage breaks the core social deduction premise
and can make an entire local round unfair.

**Independent Test**: Start a Shared-Device Mode round, pass the device through role
reveal, then inspect every shared game screen before hints begin and confirm no
secret character card, placeholder card, or role clue is visible.

**Acceptance Scenarios**:

1. **Given** Shared-Device Mode is active before all roles are privately revealed,
   **When** the shared screen is visible, **Then** no character card or hidden
   round clue is shown.
2. **Given** each Shared-Device Mode player receives their role reveal turn, **When**
   they view their private reveal, **Then** only that player's intended role
   information is visible.
3. **Given** Online Mode is active, **When** players view online game screens,
   **Then** online layout and synchronization remain unaffected by Shared-Device Mode
   changes.

---

### User Story 3 - Keep Online Rooms Playable After Host Loss (Priority: P2)

As online players, we need the room to automatically recover when the host
leaves or loses connection so the game can continue without manual restart.

**Why this priority**: Host loss currently blocks progression and leaves players
stuck during active play.

**Independent Test**: Start an online room with at least three players,
disconnect the host, and verify another connected player becomes host quickly,
all players are notified, and phase controls work for the new host.

**Acceptance Scenarios**:

1. **Given** an online room has a connected host and other connected players,
   **When** the host leaves or disconnects, **Then** the oldest connected
   remaining player becomes host.
2. **Given** a new host is assigned, **When** all players receive the room
   update, **Then** only the new host can use host-only controls.
3. **Given** the previous host reconnects after migration, **When** they rejoin
   the room, **Then** they do not regain host privileges unless selected by the
   room state.

---

### User Story 4 - Clean Up Empty Online Rooms (Priority: P2)

As the game operator and as players rejoining later, online rooms must finish
themselves after everyone leaves so stale active rooms do not remain available
or consume resources.

**Why this priority**: Orphaned rooms create confusing rejoin behavior and can
interfere with room discovery or recovery.

**Independent Test**: Create an online room, have all players leave or lose
connection, and verify the room is no longer considered active within the
expected cleanup window.

**Acceptance Scenarios**:

1. **Given** the last online player leaves formally, **When** the room becomes
   empty, **Then** the room is marked finished within 10 seconds.
2. **Given** all online players lose connection unexpectedly, **When** their
   presence becomes stale, **Then** the room is marked finished within the
   cleanup window.
3. **Given** one room becomes empty, **When** cleanup runs, **Then** unrelated
   active rooms remain unaffected.

---

### User Story 5 - Let Hosts Advance Hints Responsibly (Priority: P3)

As the current online host, I need a confirmed way to skip from hints to voting
when the group is ready so rounds do not wait unnecessarily.

**Why this priority**: This improves pacing, but it depends on host authority
and synchronization being correct first.

**Independent Test**: In an online hints phase with enough connected players,
verify only the current host can see the skip option, confirmation is required,
and all players enter voting together.

**Acceptance Scenarios**:

1. **Given** an online room is in the hints phase, **When** a non-host views the
   screen, **Then** no skip control is available.
2. **Given** the current host chooses to skip, **When** they confirm the action,
   **Then** all connected players move to voting together.
3. **Given** host migration has occurred, **When** the hints phase is active,
   **Then** the old host cannot skip and the new host can.

---

### User Story 6 - Prevent Accidental Mid-Game Leaving (Priority: P3)

As an online player, I need a clear warning before leaving active phases so I
understand the impact and the room can recover cleanly if I continue.

**Why this priority**: Leaving mid-game affects everyone, but it is less
critical than crash prevention and host recovery.

**Independent Test**: During active online phases, attempt to leave with the
back action and with any visible leave action, then verify confirmation,
notifications, reconnect behavior, and cleanup behavior.

**Acceptance Scenarios**:

1. **Given** an online player is in hints or voting, **When** they press back or
   choose to leave, **Then** they see a confirmation explaining the impact.
2. **Given** a player confirms leaving, **When** they exit, **Then** remaining
   players receive a human-friendly notification.
3. **Given** a player disconnects and reconnects, **When** connection returns,
   **Then** "Back online" appears once for that reconnect cycle.

---

### User Story 7 - Make Invalid Room Codes Clear (Priority: P4)

As a player joining an online room, I need an invalid code message that is easy
to notice and understand so I can correct the code without confusion.

**Why this priority**: This is a polish issue that improves onboarding but does
not affect active gameplay integrity.

**Independent Test**: Enter an invalid room code, confirm the error is visually
distinct and helpful, then start editing and verify the error clears.

**Acceptance Scenarios**:

1. **Given** a player enters a room code that cannot be found, **When** they
   submit it, **Then** the join screen shows "Room not found. Please check the
   code and try again."
2. **Given** the invalid code message is visible, **When** the player edits the
   code, **Then** the error clears or updates without leaving the screen.

---

### Edge Cases

- What happens when a player attempts to vote for themselves repeatedly?
- How does the game handle a voting action that completes after the player has
  left the screen?
- If Online Mode is affected, what happens when the host disconnects mid-action?
- If Online Mode is affected, what happens when a player disconnects and
  reconnects during the phase?
- If Shared-Device Mode is affected, how is hidden role or character data protected on
  the shared device?
- How are duplicate actions, self-votes, invalid room codes, and invalid phase
  actions kept in-flow?
- What happens if host migration and room cleanup are both eligible at nearly
  the same time?
- What happens if the old host reconnects after another player has already
  become host?
- What happens if only one connected player remains and then leaves?
- What happens if a non-host attempts to use a host-only control from stale UI?

## Gameplay Integrity & Mode Scope *(mandatory for game features)*

- **Affected Mode(s)**: Online Mode and Shared-Device Mode.
- **Affected Phase(s)**: Join Room, Role Reveal, Hints, Voting, Results, and
  active mid-game leaving.
- **Hidden Information Risk**: Shared-Device Mode shared screens could expose secret
  character or role clues; the feature prevents shared character cards,
  placeholder clues, and unintended role data from appearing outside private
  reveal moments.
- **Authoritative State**: Online rooms use the shared room and player records
  as the authority for host status, player connection state, room status, phase,
  votes, and skip decisions. Shared-Device Mode uses a distinct shared-device
  presentation boundary while authoritative state remains in Supabase;
  connectivity and an authenticated session are required.
- **Host/Disconnect Impact**: The feature covers host migration, empty room
  cleanup, leave confirmation, unexpected disconnect notifications, and
  reconnect notification hygiene.
- **Recoverable Validation UX**: Self-votes, invalid room codes, duplicate
  actions, invalid phase actions, and unauthorized host actions remain on the
  current screen with inline errors, snackbars, or dialogs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST keep players on the current voting screen when they
  attempt to vote for themselves.
- **FR-002**: The game MUST show the message "You cannot vote for yourself" for
  self-vote attempts in both Shared-Device Mode and Online Mode.
- **FR-003**: The game MUST NOT show a full-screen error for recoverable
  validation failures such as self-votes, invalid room codes, duplicate actions,
  invalid phase actions, or unauthorized host actions.
- **FR-004**: Shared-Device Mode shared screens MUST NOT display secret character cards,
  placeholder character cards, or role clues before the relevant private reveal.
- **FR-005**: Shared-Device Mode role reveal MUST remain private to the current player
  holding the device.
- **FR-006**: Online authoritative state changes MUST be accepted only after the
  shared room state records the change and connected players receive the updated
  room state.
- **FR-007**: When the online host leaves or disconnects and at least one other
  player remains connected, the game MUST assign host authority to the oldest
  connected remaining player.
- **FR-008**: Host migration MUST leave exactly one connected host in the room.
- **FR-009**: All online players MUST receive a clear notification when host
  authority changes.
- **FR-010**: A previous host who reconnects after migration MUST NOT regain
  host privileges unless the shared room state assigns them.
- **FR-011**: When all players have left or become stale in an online room, the
  room MUST stop being active within 10 seconds of the cleanup condition being
  detected.
- **FR-012**: Empty room cleanup MUST affect only the empty room and MUST NOT
  change unrelated active rooms.
- **FR-013**: During the online hints phase, only the current host MUST be able
  to initiate a skip to voting.
- **FR-014**: The host MUST confirm before skipping from hints to voting.
- **FR-015**: When a host skip is confirmed, all connected online players MUST
  transition to voting from the same shared phase update.
- **FR-016**: During active online phases, attempts to leave MUST show a
  confirmation explaining that leaving affects the current game.
- **FR-017**: When a player leaves an active online game, remaining players MUST
  receive a human-friendly notification.
- **FR-018**: Unexpected disconnects during active online play MUST show a
  non-stacking notification or banner to affected remaining players.
- **FR-019**: A "Back online" message MUST appear no more than once per
  disconnect/reconnect cycle.
- **FR-020**: Invalid room codes MUST show the message "Room not found. Please
  check the code and try again." on the join screen.
- **FR-021**: Invalid room code feedback MUST be visually distinct from the
  normal input state and MUST clear or update when the player edits the code.
- **FR-022**: Player-facing error messages MUST be concise, non-technical, and
  actionable.
- **FR-023**: The feature MUST NOT expose hidden role, imposter, unrevealed
  character, or host-only information to unauthorized players.
- **FR-024**: The game MUST avoid duplicate player notifications for the same
  validation, disconnect, reconnect, host migration, or leave event.
- **FR-025**: The complete game flow from room creation through the next round
  MUST remain available after these fixes.

### Key Entities *(include if feature involves data)*

- **Room**: An online play session with a status, current phase, current round,
  room code, and group of players.
- **Player**: A participant in a room with a display name, host status,
  connection status, join order, and gameplay actions.
- **Vote**: A player's selected target during voting, subject to validation that
  prevents self-voting.
- **Phase**: The current stage of play, including role reveal, hints, voting,
  results, and next round setup.
- **Notification**: A player-facing message for recoverable validation, host
  changes, leave events, disconnects, reconnects, and room-code errors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of self-vote attempts in Shared-Device Mode and Online Mode keep the
  player on the voting screen and show a clear message.
- **SC-002**: During Shared-Device Mode validation, no shared screen before private
  reveal exposes the secret character, a placeholder character card, or an
  unintended role clue.
- **SC-003**: In online rooms with at least two remaining connected players,
  host migration completes within 5 seconds of host disconnect detection.
- **SC-004**: Empty online rooms stop being active within 10 seconds of all
  players leaving or becoming stale.
- **SC-005**: 100% of confirmed host skips move all connected players from hints
  to voting without phase disagreement.
- **SC-006**: During active online phases, 100% of leave attempts require
  confirmation before the player exits.
- **SC-007**: Reconnect messaging appears no more than once per reconnect cycle
  during repeated disconnect/reconnect testing.
- **SC-008**: At least 95% of tested invalid room-code attempts are understood
  by users without needing help text beyond the displayed message.
- **SC-009**: No tested recovery path for validation failures opens a full-screen
  error.
- **SC-010**: A full room can complete Create Room -> Join Room -> Role Reveal
  -> Hints -> Voting -> Results -> Next Round after all P1 and P2 fixes are in
  place.

## Assumptions

- The eight items in the master fix plan are treated as one coordinated
  stabilization feature so shared gameplay integrity rules are validated
  together.
- Online rooms have a reliable way to determine player join order and recent
  connection status.
- "Oldest connected remaining player" means the connected player who joined the
  room earliest.
- A stale disconnected player is considered offline by the existing room
  connection rules.
- The existing private Shared-Device Mode role reveal flow remains the intended
  behavior and is preserved.
- Human-friendly messages are written in English for this specification; any
  localization work must preserve the same meaning.
