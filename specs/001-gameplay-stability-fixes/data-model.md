# Data Model: Gameplay Stability Fixes

## Room

**Purpose**: Online play session state.

**Authoritative fields**:
- `id`: unique room identifier.
- `phase`: current gameplay phase when represented on room state.
- `status`: `waiting`, `active`, or `finished`.
- `current_round`: current round number.
- `host_id`: user id of current host when maintained by schema.

**Validation rules**:
- A room with zero online players must transition to `finished`.
- Cleanup must affect only the room whose players are all offline/stale.
- Active gameplay must remain navigable through the next round after fixes.

## Player

**Purpose**: Participant in a room.

**Authoritative fields**:
- `id`: player row identifier used by rounds, votes, hints, and scores.
- `room_id`: owning room.
- `user_id`: authenticated user id or generated local participant id.
- `username`: display name.
- `is_host`: source of truth for host-only controls.
- `is_online`: source of truth for connected status.
- `last_seen_at`: heartbeat/staleness timestamp.
- `created_at`: deterministic host migration ordering.

**Validation rules**:
- Exactly one online host may exist when a room has online players.
- If the host is offline, the oldest online player by `created_at` becomes host.
- A reconnecting old host must not regain host privileges unless `is_host` is true.

## Round

**Purpose**: Current gameplay round.

**Fields**:
- `id`, `room_id`, `round_number`.
- `phase`: `hints`, `voting`, or `results`.
- `phase_end_time`.
- `imposter_player_id`.
- `character_id`.

**State transitions**:
- `hints` -> `voting`: host skip or timer, with at least two connected online players for Online Mode.
- `voting` -> `results`: host action/timer after score calculation.
- `results` -> next round or game over.

## Vote

**Purpose**: Player voting selection for a round.

**Fields**:
- `round_id`.
- `voter_player_id`.
- `voted_player_id`.

**Validation rules**:
- `voter_player_id` must not equal `voted_player_id`.
- Repeated votes by the same voter update the existing vote.
- Recoverable vote validation must not emit a fatal game error.

## Notification

**Purpose**: Player-facing in-flow feedback.

**Types**:
- Self-vote validation.
- Invalid room code validation.
- Host migration notice.
- Player left/disconnected notice.
- Reconnect banner/snackbar.
- Not-enough-connected-players validation.

**Validation rules**:
- Reconnect snackbar appears once per reconnect cycle.
- Presence/leave and host migration messages are deduped by event identity.
- Messages must be human-friendly and non-technical.

## Local Shared Screen State

**Purpose**: Pass-and-play display during Shared-Device Mode gameplay.

**Rules**:
- Must not render secret character card, placeholder character card, imposter identity, or hidden role clues before intended reveal/results.
- Private role reveal remains the only role disclosure flow before play.
- Shared-Device Mode requires connectivity and an authenticated Supabase session. Its pass-and-play presentation remains separate from Online Mode presence and host-migration UI.
