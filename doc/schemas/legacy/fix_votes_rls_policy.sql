-- ============================================================
-- Fix Votes RLS Policies - Final Version
-- Run this in Supabase SQL Editor
-- ============================================================

-- Drop ALL existing vote policies
DROP POLICY IF EXISTS "Players can vote" ON votes;
DROP POLICY IF EXISTS "Players can update their vote" ON votes;
DROP POLICY IF EXISTS "Players can update their votes" ON votes;
DROP POLICY IF EXISTS "Anyone can view votes" ON votes;

-- Read: anyone can view votes
CREATE POLICY "Anyone can view votes" ON votes
  FOR SELECT USING (true);

-- INSERT:
-- The voter and voted player must both be in the same room as the round.
-- The authenticated user must also be in that same room. This covers local
-- mode, where local players use generated UUIDs but the host auth user is in
-- the room.
CREATE POLICY "Players can vote" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rounds r
      JOIN players p_voter ON p_voter.id = votes.voter_player_id
        AND p_voter.room_id = r.room_id
      JOIN players p_target ON p_target.id = votes.voted_player_id
        AND p_target.room_id = r.room_id
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
      JOIN players p_target ON p_target.id = votes.voted_player_id
        AND p_target.room_id = r.room_id
      JOIN players p_auth ON p_auth.room_id = r.room_id
        AND p_auth.user_id = (SELECT auth.uid())
      WHERE r.id = votes.round_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rounds r
      JOIN players p_voter ON p_voter.id = votes.voter_player_id
        AND p_voter.room_id = r.room_id
      JOIN players p_target ON p_target.id = votes.voted_player_id
        AND p_target.room_id = r.room_id
      JOIN players p_auth ON p_auth.room_id = r.room_id
        AND p_auth.user_id = (SELECT auth.uid())
      WHERE r.id = votes.round_id
    )
  );
