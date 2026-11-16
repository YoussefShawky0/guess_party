-- ========================================
-- Player Presence Cleanup (stale online users)
-- ========================================
-- Run once in Supabase SQL editor.
-- Then schedule: select public.mark_stale_players_offline(90);

-- 1) Track last heartbeat per player
ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT NOW();

UPDATE public.players
SET last_seen_at = COALESCE(last_seen_at, created_at, NOW())
WHERE last_seen_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_players_presence
ON public.players (room_id, is_online, last_seen_at DESC);

-- 2) Mark stale online players as offline
CREATE OR REPLACE FUNCTION public.mark_stale_players_offline(
  p_stale_seconds INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  UPDATE public.players p
  SET
    is_online = FALSE,
    last_seen_at = NOW()
  WHERE p.is_online = TRUE
    AND p.last_seen_at < NOW() - make_interval(secs => p_stale_seconds)
    AND EXISTS (
      SELECT 1
      FROM public.rooms r
      WHERE r.id = p.room_id
        AND r.status = 'waiting'
    );

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

-- Optional one-time manual run
-- SELECT public.mark_stale_players_offline(90);
