# UI Behavior Contract: Gameplay Stability Fixes

## Recoverable Validation

- Self-vote in Shared-Device Mode and Online Mode displays `You cannot vote for yourself`.
- Self-vote never emits a fullscreen game error and never leaves the voting screen.
- Invalid room code displays `Room not found. Please check the code and try again.` on the join screen.
- Invalid room code feedback clears when the player edits the code.

## Shared-Device Mode Secret Protection

- Local shared game screens before results do not show character cards, placeholder character cards, imposter identity, or role clues.
- Private role reveal screens may show only the current player's intended secret.
- Online Mode character rendering is not changed by Shared-Device Mode secret protection.

## Online Host Authority

- Host-only controls render only when the current player's player row has `is_host = true`.
- Host skip from hints to voting requires confirmation text: `Are you sure you want to skip to voting?`
- Confirmed host skip updates the shared phase first; all players transition from the same stored update.
- Old hosts lose controls after realtime player updates remove their `is_host` authority.

## Presence, Leave, and Reconnect

- Host migration notice displays `{username} is now the host` once per new host event.
- Player leave notice displays `{username} has left the game` once per player leave/disconnect event.
- Active phase leave attempts show: `Are you sure you want to leave? This will affect the current game.`
- Reconnect banner appears while reconnecting.
- `Back online. Game synced.` appears no more than once per reconnect cycle and does not stack.

## Fatal Error Boundary

- Fullscreen error is reserved for unrecoverable load/corruption/initialization failures.
- Recoverable validation, permission, duplicate action, and invalid phase actions remain in the current screen.
