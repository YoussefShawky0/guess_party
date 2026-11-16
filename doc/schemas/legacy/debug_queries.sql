-- Debug queries to check database state

-- 1. Check if any rounds exist and their phase_end_time
SELECT 
  r.id,
  r.room_id,
  r.round_number,
  r.phase,
  r.phase_end_time,
  r.created_at,
  ro.room_code,
  ro.status,
  ro.current_round
FROM rounds r
JOIN rooms ro ON ro.id = r.room_id
ORDER BY r.created_at DESC
LIMIT 5;

-- 2. Check players in the latest room
SELECT 
  p.id as player_id,
  p.username,
  p.user_id,
  p.room_id,
  p.is_host,
  r.room_code
FROM players p
JOIN rooms r ON r.id = p.room_id
ORDER BY p.created_at DESC
LIMIT 10;

-- 3. Check if hints can be inserted (test the policy)
-- Replace these UUIDs with actual values from your database
-- SELECT 
--   r.id as round_id,
--   p.id as player_id,
--   EXISTS (
--     SELECT 1 
--     FROM rounds r2
--     INNER JOIN players p2 ON p2.room_id = r2.room_id
--     WHERE r2.id = r.id 
--       AND p2.id = p.id
--   ) as can_insert_hint
-- FROM rounds r
-- CROSS JOIN players p
-- WHERE r.room_id = p.room_id
-- LIMIT 5;

-- 4. Check current RLS policies on hints table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'hints';

-- 5. Check if trigger exists and is enabled
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_create_first_round';
