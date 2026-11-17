-- ========================================
-- Fix General Chat Messages
-- ========================================
-- Run this in Supabase SQL Editor.
-- Assumes public.messages already exists.

BEGIN;

CREATE INDEX IF NOT EXISTS idx_messages_room_id
ON public.messages (room_id);

CREATE INDEX IF NOT EXISTS idx_messages_created_at
ON public.messages (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_room_created_at
ON public.messages (room_id, created_at ASC);

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS round_id UUID;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'messages_round_id_fkey'
      AND conrelid = 'public.messages'::regclass
  ) THEN
    ALTER TABLE public.messages
    ADD CONSTRAINT messages_round_id_fkey
    FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_messages_round_created_at
ON public.messages (round_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_messages_room_round_created_at
ON public.messages (room_id, round_id, created_at ASC);

ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Room players can view messages" ON public.messages;
DROP POLICY IF EXISTS "Room players can send messages" ON public.messages;
DROP POLICY IF EXISTS "Anyone can view messages" ON public.messages;
DROP POLICY IF EXISTS "Players can send messages" ON public.messages;

CREATE POLICY "Room players can view messages" ON public.messages
  FOR SELECT USING (
    round_id IS NOT NULL
    AND
    EXISTS (
      SELECT 1
      FROM public.rounds r
      JOIN public.players p_auth ON p_auth.room_id = r.room_id
      WHERE r.id = messages.round_id
        AND r.room_id = messages.room_id
        AND p_auth.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Room players can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    round_id IS NOT NULL
    AND
    EXISTS (
      SELECT 1
      FROM public.rounds r
      JOIN public.players p_sender ON p_sender.id = messages.player_id
        AND p_sender.room_id = r.room_id
      WHERE r.id = messages.round_id
        AND r.room_id = messages.room_id
        AND p_sender.user_id = (SELECT auth.uid())
    )
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
END $$;

COMMIT;
