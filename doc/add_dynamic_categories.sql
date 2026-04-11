-- ========================================
-- Dynamic Categories for Create Room
-- ========================================
-- Run this in Supabase SQL Editor.

-- 1) Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_active_sort
ON public.categories (is_active, sort_order, name);

-- 2) Seed required categories
INSERT INTO public.categories (key, name, sort_order)
VALUES
  ('places', 'Places', 10),
  ('foods', 'Foods', 20),
  ('animals', 'Animals', 30)
ON CONFLICT (key) DO UPDATE
SET name = EXCLUDED.name,
    sort_order = EXCLUDED.sort_order,
    is_active = TRUE;

-- 3) Enable RLS and public read policy
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'categories'
      AND policyname = 'Anyone can view categories'
  ) THEN
    CREATE POLICY "Anyone can view categories" ON public.categories
      FOR SELECT USING (true);
  END IF;
END $$;

-- 4) Update rooms category check constraint
ALTER TABLE public.rooms
DROP CONSTRAINT IF EXISTS rooms_category_check;

ALTER TABLE public.rooms
ADD CONSTRAINT rooms_category_check
CHECK (
  category IN (
    'mix',
    'places',
    'foods',
    'animals',
    'football_players',
    'islamic_figures',
    'daily_products'
  )
);
