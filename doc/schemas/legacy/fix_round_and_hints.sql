-- ========================================
-- Create Trigger to Auto-Create First Round
-- ========================================

-- First, fix the players table constraint for local mode
-- Drop the old constraint that prevents multiple players with same user_id
ALTER TABLE players DROP CONSTRAINT IF EXISTS players_room_id_user_id_key;

-- Drop if already exists, then add new constraint: unique username per room (not user_id)
ALTER TABLE players DROP CONSTRAINT IF EXISTS players_room_username_unique;
ALTER TABLE players ADD CONSTRAINT players_room_username_unique 
  UNIQUE(room_id, username);

-- Function to create first round when room status changes to 'active'
CREATE OR REPLACE FUNCTION create_first_round()
RETURNS TRIGGER AS $$
DECLARE
  random_player_id UUID;
  random_character_id UUID;
  room_duration INTEGER;
  phase_end TIMESTAMP;
  existing_round_count INTEGER;
BEGIN
  -- Only run when status changes to 'active' and current_round is 0
  IF NEW.status = 'active' AND NEW.current_round = 0 AND (OLD.status IS NULL OR OLD.status != 'active') THEN
    
    -- Check if a round already exists for this room
    SELECT COUNT(*) INTO existing_round_count
    FROM rounds
    WHERE room_id = NEW.id;
    
    -- Only create round if none exists
    IF existing_round_count = 0 THEN
      
      -- Get a random player from the room to be the impostor
      SELECT id INTO random_player_id
      FROM players
      WHERE room_id = NEW.id
      ORDER BY RANDOM()
      LIMIT 1;
      
      -- Get a random character from the selected category
      SELECT id INTO random_character_id
      FROM characters
      WHERE category = NEW.category
        AND is_active = true
        AND id NOT IN (
          SELECT jsonb_array_elements_text(NEW.used_character_ids)::UUID
        )
      ORDER BY RANDOM()
      LIMIT 1;
      
      -- Get round duration from room
      room_duration := NEW.round_duration;
      
      -- Calculate phase end time (current time + duration)
      phase_end := NOW() + (room_duration || ' seconds')::INTERVAL;
      
      -- Create the first round
      INSERT INTO rounds (
        room_id,
        round_number,
        imposter_player_id,
        character_id,
        phase,
        phase_end_time,
        imposter_revealed
      ) VALUES (
        NEW.id,
        1,
        random_player_id,
        random_character_id,
        'hints',
        phase_end,
        false
      );
      
      -- Update room's current_round to 1
      UPDATE rooms
      SET current_round = 1,
          used_character_ids = used_character_ids || jsonb_build_array(random_character_id)
      WHERE id = NEW.id;
      
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_create_first_round ON rooms;
CREATE TRIGGER trigger_create_first_round
  AFTER UPDATE ON rooms
  FOR EACH ROW
  EXECUTE FUNCTION create_first_round();

-- ========================================
-- Fix RLS Policies for Hints
-- ========================================

-- Drop old policy
DROP POLICY IF EXISTS "Players can add hints" ON hints;

-- Create new policy that checks if player exists in the same room as the round
CREATE POLICY "Players can add hints" ON hints
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM rounds r
      INNER JOIN players p ON p.room_id = r.room_id
      WHERE r.id = hints.round_id 
        AND p.id = hints.player_id
    )
  );

-- ========================================
-- Fix RLS Policies for Votes
-- ========================================

-- Drop old policy
DROP POLICY IF EXISTS "Players can vote" ON votes;

-- Create new policy that checks if voter exists in the same room as the round
CREATE POLICY "Players can vote" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM rounds r
      INNER JOIN players p ON p.room_id = r.room_id
      WHERE r.id = votes.round_id 
        AND p.id = votes.voter_player_id
    )
  );
