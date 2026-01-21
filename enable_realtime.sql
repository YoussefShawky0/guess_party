-- Enable Realtime for all tables
-- This is required for Supabase Realtime to work with UPDATE/DELETE events

-- Enable REPLICA IDENTITY FULL for rooms table
-- This allows Realtime to send the full row data on UPDATE events
ALTER TABLE rooms REPLICA IDENTITY FULL;

-- Enable REPLICA IDENTITY FULL for other tables that use Realtime
ALTER TABLE players REPLICA IDENTITY FULL;
ALTER TABLE rounds REPLICA IDENTITY FULL;
ALTER TABLE hints REPLICA IDENTITY FULL;
ALTER TABLE votes REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;

-- Enable Realtime publication for these tables
-- (This should already be enabled in Supabase by default, but just to be sure)
-- You may need to run this in the Supabase dashboard if it's not working:
-- ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
-- ALTER PUBLICATION supabase_realtime ADD TABLE players;
-- ALTER PUBLICATION supabase_realtime ADD TABLE rounds;
-- ALTER PUBLICATION supabase_realtime ADD TABLE hints;
-- ALTER PUBLICATION supabase_realtime ADD TABLE votes;
-- ALTER PUBLICATION supabase_realtime ADD TABLE messages;
