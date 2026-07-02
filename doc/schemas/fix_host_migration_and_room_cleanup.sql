-- ========================================
-- Host Migration + Empty Room Cleanup
-- ========================================
-- Apply in Supabase SQL editor.
-- This script ensures:
-- 1) When host goes offline/leaves, the oldest online player becomes host.
-- 2) When no online players remain, room is marked finished.
-- 3) Stale presence cleanup also affects active rooms.

-- Ensure presence timestamp exists (idempotent safety).
ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_players_presence
ON public.players (room_id, is_online, last_seen_at DESC);

-- Reconcile room after any presence change.
CREATE OR REPLACE FUNCTION public.reconcile_room_after_presence_change(
  p_room_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_online_count INTEGER;
  v_has_online_host BOOLEAN;
  v_new_host_player_id UUID;
  v_new_host_user_id UUID;
BEGIN
  IF p_room_id IS NULL THEN
    RETURN;
  END IF;

  SELECT COUNT(*)
  INTO v_online_count
  FROM public.players
  WHERE room_id = p_room_id
    AND is_online = TRUE;

  IF v_online_count = 0 THEN
    UPDATE public.rooms
    SET status = 'finished'
    WHERE id = p_room_id
      AND status <> 'finished';
    RETURN;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.players
    WHERE room_id = p_room_id
      AND is_online = TRUE
      AND is_host = TRUE
  )
  INTO v_has_online_host;

  IF v_has_online_host THEN
    RETURN;
  END IF;

  SELECT p.id, p.user_id
  INTO v_new_host_player_id, v_new_host_user_id
  FROM public.players p
  WHERE p.room_id = p_room_id
    AND p.is_online = TRUE
  ORDER BY p.created_at ASC
  LIMIT 1;

  IF v_new_host_player_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.players
  SET is_host = (id = v_new_host_player_id)
  WHERE room_id = p_room_id
    AND is_host IS DISTINCT FROM (id = v_new_host_player_id);

  UPDATE public.rooms
  SET host_id = v_new_host_user_id
  WHERE id = p_room_id;
END;
$$;

-- Trigger room reconciliation whenever player online status changes.
CREATE OR REPLACE FUNCTION public.handle_player_presence_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_online IS DISTINCT FROM OLD.is_online THEN
    PERFORM public.reconcile_room_after_presence_change(NEW.room_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_handle_player_presence_change ON public.players;
CREATE TRIGGER trigger_handle_player_presence_change
AFTER UPDATE OF is_online
ON public.players
FOR EACH ROW
EXECUTE FUNCTION public.handle_player_presence_change();

-- Expand stale-player cleanup to include active rooms too.
CREATE OR REPLACE FUNCTION public.mark_stale_players_offline(
  p_stale_seconds INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
        AND r.status IN ('waiting', 'active')
    );

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

-- Optional manual run:
-- SELECT public.mark_stale_players_offline(90);
