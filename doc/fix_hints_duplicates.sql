-- ========================================
-- Fix Hints Duplicates and Add UNIQUE Constraint
-- ========================================

-- Step 1: Delete duplicate hints, keep only the latest one for each player per round
DELETE FROM hints
WHERE id NOT IN (
  SELECT DISTINCT ON (round_id, player_id) id
  FROM hints
  ORDER BY round_id, player_id, timestamp DESC
);

-- Step 2: Add UNIQUE constraint to prevent future duplicates (if not exists)
ALTER TABLE hints 
  DROP CONSTRAINT IF EXISTS hints_round_player_unique;

ALTER TABLE hints 
  ADD CONSTRAINT hints_round_player_unique 
  UNIQUE(round_id, player_id);

-- Step 3: Update RLS policy to allow UPDATE (in case player wants to edit their hint)
DROP POLICY IF EXISTS "Players can add hints" ON hints;

CREATE POLICY "Players can add hints" ON hints
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM players p
      INNER JOIN rounds r ON r.id = hints.round_id
      WHERE p.id = hints.player_id
        AND p.room_id = r.room_id
    )
  );

-- Allow players to update their own hints
DROP POLICY IF EXISTS "Players can update their hints" ON hints;

CREATE POLICY "Players can update their hints" ON hints
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM players p
      INNER JOIN rounds r ON r.id = hints.round_id
      WHERE p.id = hints.player_id
        AND p.room_id = r.room_id
    )
  );

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Hints duplicates cleaned and UNIQUE constraint added successfully!';
END $$;
