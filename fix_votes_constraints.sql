-- ============================================================
-- Fix Votes Table Constraints
-- Run this in Supabase SQL Editor
-- ============================================================

-- Step 1: Remove duplicate votes (keep only the latest per voter per round)
-- (Needed because UNIQUE constraint will fail if duplicate rows already exist)
WITH latest_votes AS (
  SELECT DISTINCT ON (round_id, voter_player_id) id
  FROM votes
  ORDER BY round_id, voter_player_id, created_at DESC NULLS LAST
)
DELETE FROM votes
WHERE id NOT IN (SELECT id FROM latest_votes);

-- Step 2: Add UNIQUE constraint (one vote per voter per round)
ALTER TABLE votes DROP CONSTRAINT IF EXISTS votes_unique_voter_round;
ALTER TABLE votes ADD CONSTRAINT votes_unique_voter_round
  UNIQUE (round_id, voter_player_id);

-- Verify
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'votes'::regclass;
