# Research: Gameplay Stability Fixes

## Decision: Keep recoverable validation out of GameError

**Rationale**: Self-vote, invalid room code, not-enough-players, duplicate
actions, and unauthorized host actions are normal user mistakes or race
conditions. They must use `GameLoaded.nonFatalMessage`, inline field errors,
snackbars, or dialogs so the current phase stays visible.

**Alternatives considered**: Reusing `GameError` was rejected because
`GameView` renders `ErrorScreen` for `GameError`, which violates the
constitution for recoverable validation.

## Decision: Make Online Mode Supabase-first

**Rationale**: Online votes, phase changes, host migration, player presence,
room cleanup, and skips must persist to Supabase before clients accept them as
authoritative. Existing realtime streams in `GameRepository` and presence
listeners in `GameView` should refresh UI from stored state.

**Alternatives considered**: Client-only optimistic phase advancement was
rejected because it can desynchronize players. Vote-local optimistic display is
allowed only when the Supabase write succeeds and realtime remains the final
state.

## Decision: Use database reconciliation for host migration and empty cleanup

**Rationale**: The SQL design in `doc/schemas/fix_host_migration_and_room_cleanup.sql`
keeps host migration deterministic and handles formal leave, offline status,
and stale players with the same rules. The oldest online player by `created_at`
becomes host; rooms with zero online players become `finished`.

**Alternatives considered**: Host election only in `GameView` was rejected
because clients can disconnect and cannot be trusted as the source of truth.

## Decision: Keep Shared-Device Mode UI separate and remove shared secret surfaces

**Rationale**: Shared-Device Mode is shared-device. Even a hidden or placeholder
character card on the shared game screen can reveal structure and affect player
deduction. Shared-Device Mode should show neutral phase instructions until results,
while private role reveal remains the only secret reveal surface.

**Alternatives considered**: Reusing Online Mode `CharacterCard` with masked
content was rejected because the shared component still represents secret card
state.

## Decision: Centralize snackbar dedupe for reconnect and presence events

**Rationale**: Reconnect and presence notifications are frequent. The current
view already tracks reconnect cycles and presence dedupe keys; tasks should
tighten this behavior and tests rather than add another notification channel.

**Alternatives considered**: Emitting every presence event as a snackbar was
rejected because it stacks and distracts players during active phases.

## Decision: Preserve current architecture boundaries

**Rationale**: The project already uses feature-first Clean Architecture,
repositories, Cubits, use cases, and DI. Stabilization should reinforce these
boundaries instead of moving Supabase calls into widgets.

**Alternatives considered**: Quick direct Supabase queries from presentation
were rejected for new authoritative behavior. Existing presentation presence
queries may remain only as best-effort UI observation and should not become the
authority for host permissions or phase changes.
