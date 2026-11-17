-- ========================================
-- Enforce Room Capacity
-- ========================================
-- Run this in Supabase SQL Editor.
-- Protects rooms.max_players at the database level so direct inserts cannot
-- bypass the app's join-room checks.

BEGIN;

-- Merge duplicate player rows for the same room/user before adding the
-- uniqueness guard. This keeps the oldest row and repoints dependent rows.
DROP TABLE IF EXISTS public._duplicate_players_cleanup;

CREATE TABLE public._duplicate_players_cleanup AS
WITH ranked AS (
  SELECT
    id,
    first_value(id) OVER (
      PARTITION BY room_id, user_id
      ORDER BY created_at ASC, id ASC
    ) AS keep_id,
    row_number() OVER (
      PARTITION BY room_id, user_id
      ORDER BY created_at ASC, id ASC
    ) AS rn
  FROM public.players
)
SELECT id AS duplicate_id, keep_id
FROM ranked
WHERE rn > 1;

DELETE FROM public.votes v
USING public._duplicate_players_cleanup d
WHERE (v.voter_player_id = d.keep_id AND v.voted_player_id = d.duplicate_id)
   OR (v.voter_player_id = d.duplicate_id AND v.voted_player_id = d.keep_id)
   OR (v.voter_player_id = d.duplicate_id AND v.voted_player_id = d.duplicate_id);

DELETE FROM public.votes v
USING public._duplicate_players_cleanup d
WHERE v.voter_player_id = d.duplicate_id
  AND EXISTS (
    SELECT 1
    FROM public.votes existing
    WHERE existing.round_id = v.round_id
      AND existing.voter_player_id = d.keep_id
  );

UPDATE public.votes v
SET voter_player_id = d.keep_id
FROM public._duplicate_players_cleanup d
WHERE v.voter_player_id = d.duplicate_id;

UPDATE public.votes v
SET voted_player_id = d.keep_id
FROM public._duplicate_players_cleanup d
WHERE v.voted_player_id = d.duplicate_id;

DELETE FROM public.hints h
USING public._duplicate_players_cleanup d
WHERE h.player_id = d.duplicate_id
  AND EXISTS (
    SELECT 1
    FROM public.hints existing
    WHERE existing.round_id = h.round_id
      AND existing.player_id = d.keep_id
  );

UPDATE public.hints h
SET player_id = d.keep_id
FROM public._duplicate_players_cleanup d
WHERE h.player_id = d.duplicate_id;

UPDATE public.rounds r
SET imposter_player_id = d.keep_id
FROM public._duplicate_players_cleanup d
WHERE r.imposter_player_id = d.duplicate_id;

UPDATE public.messages msg
SET player_id = d.keep_id
FROM public._duplicate_players_cleanup d
WHERE msg.player_id = d.duplicate_id;

DELETE FROM public.players p
USING public._duplicate_players_cleanup d
WHERE p.id = d.duplicate_id;

ALTER TABLE public.players
DROP CONSTRAINT IF EXISTS players_room_id_user_id_key;

ALTER TABLE public.players
ADD CONSTRAINT players_room_id_user_id_key UNIQUE (room_id, user_id);

CREATE OR REPLACE FUNCTION public.enforce_room_capacity()
RETURNS TRIGGER AS $$
DECLARE
  v_room_status TEXT;
  v_max_players INTEGER;
  v_online_count INTEGER;
BEGIN
  SELECT status, max_players
  INTO v_room_status, v_max_players
  FROM public.rooms
  WHERE id = NEW.room_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Room not found';
  END IF;

  IF TG_OP = 'INSERT' AND v_room_status <> 'waiting' THEN
    RAISE EXCEPTION 'This room has already started';
  END IF;

  IF COALESCE(NEW.is_online, true) THEN
    SELECT COUNT(*)
    INTO v_online_count
    FROM public.players
    WHERE room_id = NEW.room_id
      AND is_online = true
      AND id <> NEW.id;

    IF v_online_count >= v_max_players THEN
      RAISE EXCEPTION 'This room is full (% players max)', v_max_players;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_enforce_room_capacity ON public.players;

CREATE TRIGGER trigger_enforce_room_capacity
BEFORE INSERT OR UPDATE OF room_id, is_online
ON public.players
FOR EACH ROW
EXECUTE FUNCTION public.enforce_room_capacity();

DROP TABLE IF EXISTS public._duplicate_players_cleanup;

COMMIT;
