# Debug: Start Game Button Issue

## Problem

When pressing the "Start Game" button in the waiting room, nothing happens - no navigation to countdown screen.

## Root Cause Analysis

The flow is:

1. Button press → `onStartGame` callback
2. Calls `RoomCubit.startGameSession(roomId)`
3. Calls `StartGame` usecase → Repository → RemoteDataSource
4. Updates room status to 'active' in database
5. `RoomStatusListener` should hear the change via Supabase Realtime
6. Navigate to countdown screen

**Most Likely Issue**: Supabase Realtime is not properly configured for the `rooms` table.

## Solution

### Step 1: Enable Realtime for Database Tables

Run this SQL in your Supabase SQL Editor:

```sql
-- Enable REPLICA IDENTITY FULL for rooms table
-- This allows Realtime to send the full row data on UPDATE events
ALTER TABLE rooms REPLICA IDENTITY FULL;
ALTER TABLE players REPLICA IDENTITY FULL;
ALTER TABLE rounds REPLICA IDENTITY FULL;
ALTER TABLE hints REPLICA IDENTITY FULL;
ALTER TABLE votes REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
```

### Step 2: Enable Realtime Publication

In Supabase Dashboard:

1. Go to **Database** → **Replication**
2. Make sure these tables are enabled for Realtime:
   - rooms ✅
   - players ✅
   - rounds ✅
   - hints ✅
   - votes ✅
   - messages ✅

If any are missing, click "Add table" and enable them.

### Step 3: Test with Debug Logs

I've added debug logging throughout the code. When you press "Start Game", you should see these logs in your console:

```
🎮 Starting game session for room: [room-id]
🔵 Updating room [room-id] status to active
🔵 Room update response: [...]
✅ Game started successfully, waiting for Realtime update
```

Then from RoomStatusListener:

```
👂 Setting up room status listener for room: [room-id]
📡 Subscription status: subscribed, error: null
🔔 Room status changed: {...}
📊 New status: active
🎯 Game started, navigating to countdown
✅ Context is valid, navigating to: /room/[room-id]/countdown
```

### Step 4: Test Scenarios

#### Scenario A: No logs appear

**Problem**: Button is not wired correctly
**Check**: Verify you're the host (button only shows for host)

#### Scenario B: Logs stop at "Game started successfully"

**Problem**: Realtime is not working
**Solution**:

- Run the SQL from Step 1
- Enable tables in Replication (Step 2)
- Restart your app

#### Scenario C: "Room update response" shows error

**Problem**: Database permissions issue
**Check**: RLS policies for rooms table - update should be allowed for host

#### Scenario D: "Subscription status" shows error

**Problem**: Realtime subscription failed
**Solution**: Check your Supabase project settings, ensure Realtime API is enabled

## Additional Fixes Applied

I've also updated the code to:

1. Add `.select()` to the room update query (this returns the updated row)
2. Add subscription status callback to see connection errors
3. Add comprehensive logging at every step

## Testing Steps

1. **Run the SQL** from Step 1 in Supabase SQL Editor
2. **Enable Replication** for all tables in Step 2
3. **Hot restart your app** (don't just hot reload)
4. **Create a room** as host
5. **Press Start Game**
6. **Watch the console** for debug logs
7. **Report back** which logs you see

## Expected Behavior After Fix

1. Press "Start Game" button
2. See loading indicator for ~1 second
3. Automatically navigate to countdown screen
4. Countdown shows 3...2...1...
5. Navigate to game screen

## Files Modified

- `room_cubit.dart` - Added logging to startGameSession
- `room_remote_data_source.dart` - Added logging and .select() to update
- `room_status_listener.dart` - Added comprehensive logging and subscription callback
- `enable_realtime.sql` - Created SQL file with all commands

## Next Steps

After running the SQL and testing:

1. If it works → Move on to fixing timer issue
2. If it doesn't work → Send me the console logs you see
3. We'll debug based on which step fails
