-- ========================================
-- Fix Timezone Issue in Round Creation
-- ========================================

-- Update the create_first_round function to use UTC timestamps
CREATE OR REPLACE FUNCTION create_first_round()
RETURNS TRIGGER AS $$
DECLARE
  random_player_id UUID;
  random_character_id UUID;
  room_duration INTEGER;
  phase_end TIMESTAMPTZ;
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
      
      -- Calculate phase end time using CURRENT_TIMESTAMP (UTC)
      phase_end := CURRENT_TIMESTAMP + (room_duration || ' seconds')::INTERVAL;
      
      RAISE NOTICE 'Creating round with phase_end: %', phase_end;
      
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
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Trigger function updated to use UTC timestamps!';
END $$;
