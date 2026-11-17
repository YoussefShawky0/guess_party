-- ========================================
-- Fix RLS Performance Issues
-- Apply this to your existing Supabase database
-- ========================================

-- Drop and recreate policies with optimized auth.uid() calls

-- 1. Fix "Only host can update room" policy
DROP POLICY IF EXISTS "Only host can update room" ON rooms;
CREATE POLICY "Only host can update room" ON rooms
  FOR UPDATE USING (host_id = (SELECT auth.uid()));

-- 2. Fix "Players can update themselves" policy
DROP POLICY IF EXISTS "Players can update themselves" ON players;
CREATE POLICY "Players can update themselves" ON players
  FOR UPDATE USING (user_id = (SELECT auth.uid()));

-- 3. Fix "Only host can manage rounds" policy - Split into separate actions
DROP POLICY IF EXISTS "Only host can manage rounds" ON rounds;

-- INSERT policy for hosts
CREATE POLICY "Only host can manage rounds" ON rounds
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

-- UPDATE policy for hosts
CREATE POLICY "Only host can modify rounds" ON rounds
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

-- DELETE policy for hosts
CREATE POLICY "Only host can delete rounds" ON rounds
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

-- 4. Fix "Players can add hints" policy
DROP POLICY IF EXISTS "Players can add hints" ON hints;
CREATE POLICY "Players can add hints" ON hints
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM players p
      WHERE p.id = hints.player_id
      AND p.user_id = (SELECT auth.uid())
    )
  );

-- 5. Fix "Players can vote" policy
DROP POLICY IF EXISTS "Players can vote" ON votes;
CREATE POLICY "Players can vote" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM players p
      WHERE p.id = votes.voter_player_id
      AND p.user_id = (SELECT auth.uid())
    )
  );
