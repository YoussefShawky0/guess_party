-- ========================================
-- Time Synchronization Function Migration
-- ========================================
-- Run this in Supabase SQL Editor to enable time synchronization
-- This function is used by clients to sync their clocks with the server

CREATE OR REPLACE FUNCTION get_server_time()
RETURNS TABLE(server_time TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
  RETURN QUERY SELECT NOW();
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_server_time() TO authenticated;
GRANT EXECUTE ON FUNCTION get_server_time() TO anon;
