-- ========================================
-- Remove Mix Category
-- ========================================
-- Run this in Supabase SQL Editor before deploying the Flutter app change.
-- This deletes old mix rooms, removes the mix category row, and keeps all
-- concrete categories selectable.

BEGIN;

DELETE FROM public.votes v
USING public.rounds r
WHERE v.round_id = r.id
  AND r.room_id IN (
    SELECT id
    FROM public.rooms
    WHERE category = 'mix'
  );

DELETE FROM public.hints h
USING public.rounds r
WHERE h.round_id = r.id
  AND r.room_id IN (
    SELECT id
    FROM public.rooms
    WHERE category = 'mix'
  );

DELETE FROM public.rounds r
WHERE r.room_id IN (
  SELECT id
  FROM public.rooms
  WHERE category = 'mix'
);

DO $$
BEGIN
  IF to_regclass('public.messages') IS NOT NULL THEN
    EXECUTE '
      DELETE FROM public.messages msg
      WHERE msg.room_id IN (
        SELECT id
        FROM public.rooms
        WHERE category = ''mix''
      )
    ';
  END IF;
END $$;

DELETE FROM public.players p
WHERE p.room_id IN (
  SELECT id
  FROM public.rooms
  WHERE category = 'mix'
);

DELETE FROM public.rooms r
WHERE r.category = 'mix';

DELETE FROM public.categories
WHERE key = 'mix';

INSERT INTO public.categories (key, name, sort_order)
VALUES
  ('football_players', 'Football Players', 10),
  ('islamic_figures', 'Islamic Figures', 20),
  ('daily_products', 'Daily Products', 30),
  ('places', 'Places', 40),
  ('foods', 'Foods', 50),
  ('animals', 'Animals', 60)
ON CONFLICT (key) DO UPDATE
SET name = EXCLUDED.name,
    sort_order = EXCLUDED.sort_order,
    is_active = TRUE;

ALTER TABLE public.rooms
DROP CONSTRAINT IF EXISTS rooms_category_check;

ALTER TABLE public.rooms
ADD CONSTRAINT rooms_category_check
CHECK (
  category IN (
    'football_players',
    'islamic_figures',
    'daily_products',
    'places',
    'foods',
    'animals'
  )
);

COMMIT;
