-- ============================================================
-- Fix Votes RLS Policies - Final Version
-- Run this in Supabase SQL Editor
-- ============================================================

-- Drop ALL existing vote policies
DROP POLICY IF EXISTS "Players can vote" ON votes;
DROP POLICY IF EXISTS "Players can update their vote" ON votes;
DROP POLICY IF EXISTS "Anyone can view votes" ON votes;

-- Read: anyone can view votes
CREATE POLICY "Anyone can view votes" ON votes
  FOR SELECT USING (true);

-- INSERT:
-- The voter (voter_player_id) must be in the same room as the round.
-- The authenticated user must be in that same room (covers both host and local players,
-- because in local mode the host's auth.uid() IS in the room).
CREATE POLICY "Players can vote" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rounds r
      JOIN players p_voter ON p_voter.id = votes.voter_player_id
        AND p_voter.room_id = r.room_id
      JOIN players p_auth ON p_auth.room_id = r.room_id
        AND p_auth.user_id = (SELECT auth.uid())
      WHERE r.id = votes.round_id
    )
  );

-- UPDATE: same logic (for changing a vote)
CREATE POLICY "Players can update their vote" ON votes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM rounds r
      JOIN players p_voter ON p_voter.id = votes.voter_player_id
        AND p_voter.room_id = r.room_id
      JOIN players p_auth ON p_auth.room_id = r.room_id
        AND p_auth.user_id = (SELECT auth.uid())
      WHERE r.id = votes.round_id
    )
  );
