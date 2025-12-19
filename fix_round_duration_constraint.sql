-- Fix round_duration CHECK constraint in rooms table
-- Current constraint allows only up to 300 seconds (5 minutes)
-- We need to support up to 900 seconds (15 minutes)

-- 1. Drop the old constraint
ALTER TABLE rooms 
DROP CONSTRAINT IF EXISTS rooms_round_duration_check;

-- 2. Add the new constraint with higher limit
ALTER TABLE rooms 
ADD CONSTRAINT rooms_round_duration_check 
CHECK (round_duration >= 30 AND round_duration <= 900);

-- Verify the constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'rooms_round_duration_check';
