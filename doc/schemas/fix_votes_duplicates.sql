-- ========================================
-- Fix Votes Duplicates and Add UNIQUE Constraint
-- ========================================

-- Step 1: Delete duplicate votes, keep only the latest one for each voter per round
DELETE FROM votes
WHERE id NOT IN (
  SELECT DISTINCT ON (round_id, voter_player_id) id
  FROM votes
  ORDER BY round_id, voter_player_id, created_at DESC
);

-- Note: UNIQUE constraint already exists in schema
-- Step 2 is skipped as votes table already has: UNIQUE(round_id, voter_player_id)

-- Step 3: Add UPDATE policy for votes (if not exists)
DROP POLICY IF EXISTS "Players can update their votes" ON votes;

CREATE POLICY "Players can update their votes" ON votes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM players p
      INNER JOIN rounds r ON r.id = votes.round_id
      WHERE p.id = votes.voter_player_id
        AND p.room_id = r.room_id
    )
  );

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Votes duplicates cleaned and UPDATE policy added successfully!';
END $$;
