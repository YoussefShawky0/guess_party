# Quickstart: Gameplay Stability Fixes

## Preconditions

- Run the app with Supabase configured.
- Use at least three test accounts/devices for online host migration checks.
- Apply or verify the host migration/cleanup SQL described in `doc/schemas/fix_host_migration_and_room_cleanup.sql` before online cleanup validation.

## Manual Validation Flows

### Local self-vote

1. Create a Shared-Device Mode room with at least three players.
2. Complete private role reveal.
3. Reach voting.
4. Tap a player's own name, then select the same player as target.
5. Verify `You cannot vote for yourself` appears and no crash/fullscreen error occurs.

### Online self-vote

1. Create an Online Mode room with at least three players.
2. Reach voting.
3. Attempt any self-vote path available in the UI or through stale UI state.
4. Verify the voting screen remains visible and only the self-vote snackbar appears.

### Local hidden information

1. Start Shared-Device Mode and complete role reveal.
2. Inspect shared hints and voting screens.
3. Verify no character card, placeholder card, imposter identity, or hidden role clue appears before results.

### Host migration

1. Create an Online Mode room with host plus at least two players.
2. Reach hints.
3. Disconnect or leave as host.
4. Verify the oldest connected remaining player becomes host within 5 seconds of detection.
5. Verify only the new host sees host controls and everyone receives one host-change notice.

### Empty room cleanup

1. Create an Online Mode room.
2. Have all players leave or disconnect.
3. Verify the room becomes `finished` within 10 seconds of all players being offline/stale.
4. Verify unrelated active rooms are unchanged.

### Host skip

1. Create an Online Mode room with at least two connected players.
2. Reach hints.
3. Verify non-hosts cannot see skip.
4. Confirm skip as current host.
5. Verify all players transition to voting together.

### Mid-game leave and reconnect

1. Reach hints or voting in Online Mode.
2. Press back or leave.
3. Verify confirmation appears before leaving.
4. Confirm leave and verify remaining players see one leave notice.
5. Disconnect/reconnect a player and verify `Back online. Game synced.` appears once per reconnect cycle.

### Invalid room code

1. Open Join Room.
2. Enter a non-existent six-digit room code.
3. Verify the error uses the exact copy `Room not found. Please check the code and try again.`
4. Edit the code and verify the error clears.

## Automated Validation

Run:

```powershell
flutter analyze
flutter test
```
