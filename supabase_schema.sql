-- ========================================
-- Guess Party - Supabase Database Schema
-- ========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- 1. Characters Table
-- ========================================
CREATE TABLE IF NOT EXISTS characters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  emoji TEXT NOT NULL DEFAULT '❓',
  category TEXT NOT NULL,
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_characters_category ON characters(category) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_characters_active ON characters(is_active);

-- ========================================
-- 2. Rooms Table
-- ========================================
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  host_id UUID NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('mix', 'football_players', 'islamic_figures', 'daily_products')),
  max_rounds INTEGER NOT NULL DEFAULT 5 CHECK (max_rounds BETWEEN 1 AND 10),
  max_players INTEGER NOT NULL DEFAULT 6 CHECK (max_players BETWEEN 4 AND 10),
  round_duration INTEGER NOT NULL DEFAULT 60 CHECK (round_duration BETWEEN 30 AND 300),
  current_round INTEGER DEFAULT 0,
  room_code TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'finished')),
  used_character_ids JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_code ON rooms(room_code);
CREATE INDEX IF NOT EXISTS idx_rooms_status ON rooms(status);

-- ========================================
-- 3. Players Table
-- ========================================
CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  username TEXT NOT NULL CHECK (length(username) >= 2 AND length(username) <= 20),
  score INTEGER DEFAULT 0 CHECK (score >= 0),
  is_host BOOLEAN DEFAULT false,
  is_online BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_players_room ON players(room_id);
CREATE INDEX IF NOT EXISTS idx_players_online ON players(room_id, is_online);
CREATE INDEX IF NOT EXISTS idx_players_host ON players(room_id, is_host);

-- ========================================
-- 4. Rounds Table
-- ========================================
CREATE TABLE IF NOT EXISTS rounds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  imposter_player_id UUID NOT NULL REFERENCES players(id),
  character_id UUID NOT NULL REFERENCES characters(id),
  round_number INTEGER NOT NULL CHECK (round_number > 0),
  phase TEXT DEFAULT 'hints' CHECK (phase IN ('hints', 'voting', 'results')),
  phase_end_time TIMESTAMP NOT NULL,
  imposter_revealed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(room_id, round_number)
);

CREATE INDEX IF NOT EXISTS idx_rounds_room ON rounds(room_id, round_number);
CREATE INDEX IF NOT EXISTS idx_rounds_phase ON rounds(phase);

-- ========================================
-- 5. Hints Table
-- ========================================
CREATE TABLE IF NOT EXISTS hints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  round_id UUID NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id),
  content TEXT NOT NULL CHECK (length(content) >= 2 AND length(content) <= 200),
  timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hints_round ON hints(round_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_hints_player ON hints(round_id, player_id);

-- ========================================
-- 6. Votes Table
-- ========================================
CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  round_id UUID NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
  voter_player_id UUID NOT NULL REFERENCES players(id),
  voted_player_id UUID NOT NULL REFERENCES players(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(round_id, voter_player_id),
  CHECK (voter_player_id != voted_player_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_round ON votes(round_id);
CREATE INDEX IF NOT EXISTS idx_votes_voted ON votes(round_id, voted_player_id);

-- ========================================
-- 7. Enable Realtime
-- ========================================
ALTER PUBLICATION supabase_realtime ADD TABLE characters;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE players;
ALTER PUBLICATION supabase_realtime ADD TABLE rounds;
ALTER PUBLICATION supabase_realtime ADD TABLE hints;
ALTER PUBLICATION supabase_realtime ADD TABLE votes;

-- ========================================
-- 8. Row Level Security (RLS)
-- ========================================
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE hints ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;

-- Characters: الكل يقدر يقرأها
CREATE POLICY "Anyone can view characters" ON characters
  FOR SELECT USING (true);

-- Rooms: الكل يقدر يقرأها
CREATE POLICY "Anyone can view rooms" ON rooms
  FOR SELECT USING (true);

-- Rooms: أي حد يقدر يعمل روم
CREATE POLICY "Anyone can create room" ON rooms
  FOR INSERT WITH CHECK (true);

-- Rooms: الـ HOST بس يقدر يعدل
CREATE POLICY "Only host can update room" ON rooms
  FOR UPDATE USING (host_id = (SELECT auth.uid()));

-- Players: الكل يقدر يقرأهم
CREATE POLICY "Anyone can view players" ON players
  FOR SELECT USING (true);

-- Players: أي حد يقدر ينضم
CREATE POLICY "Anyone can join as player" ON players
  FOR INSERT WITH CHECK (true);

-- Players: كل لاعب يعدل بياناته بس
CREATE POLICY "Players can update themselves" ON players
  FOR UPDATE USING (user_id = (SELECT auth.uid()));

-- Rounds: الكل يقدر يقرأها
CREATE POLICY "Anyone can view rounds" ON rounds
  FOR SELECT USING (true);

-- Rounds: الـ HOST بس يقدر يديرها (INSERT, UPDATE, DELETE)
CREATE POLICY "Only host can manage rounds" ON rounds
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

CREATE POLICY "Only host can modify rounds" ON rounds
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

CREATE POLICY "Only host can delete rounds" ON rounds
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN players p ON p.room_id = r.id
      WHERE r.id = rounds.room_id 
      AND p.user_id = (SELECT auth.uid())
      AND p.is_host = true
    )
  );

-- Hints: الكل يقدر يقرأها
CREATE POLICY "Anyone can view hints" ON hints
  FOR SELECT USING (true);

-- Hints: اللاعيبة يقدروا يضيفوا hints
CREATE POLICY "Players can add hints" ON hints
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM players p
      WHERE p.id = hints.player_id
      AND p.user_id = (SELECT auth.uid())
    )
  );

-- Votes: الكل يقدر يقرأها
CREATE POLICY "Anyone can view votes" ON votes
  FOR SELECT USING (true);

-- Votes: اللاعيبة يقدروا يصوتوا
CREATE POLICY "Players can vote" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM players p
      WHERE p.id = votes.voter_player_id
      AND p.user_id = (SELECT auth.uid())
    )
  );

-- ========================================
-- 9. Insert Sample Characters
-- ========================================
INSERT INTO characters (name, category, difficulty) VALUES
-- لاعيبة كورة
('محمد صلاح', 'football_players', 'easy'),
('كريستيانو رونالدو', 'football_players', 'easy'),
('ليونيل ميسي', 'football_players', 'easy'),
('نيمار', 'football_players', 'medium'),
('كيليان مبابي', 'football_players', 'medium'),
('محمد النني', 'football_players', 'medium'),
('زين الدين زيدان', 'football_players', 'medium'),
('رونالدينيو', 'football_players', 'medium'),
('كريم بنزيما', 'football_players', 'medium'),
('لوكا مودريتش', 'football_players', 'hard'),
('روبرت ليفاندوفسكي', 'football_players', 'hard'),
('عمر مرموش', 'football_players', 'medium'),
('محمد أبو تريكة', 'football_players', 'easy'),
('محمود الخطيب', 'football_players', 'medium'),
('حسام حسن', 'football_players', 'medium'),

-- شخصيات إسلامية
('عمر بن الخطاب', 'islamic_figures', 'easy'),
('خالد بن الوليد', 'islamic_figures', 'easy'),
('صلاح الدين الأيوبي', 'islamic_figures', 'easy'),
('عمرو بن العاص', 'islamic_figures', 'medium'),
('أبو بكر الصديق', 'islamic_figures', 'easy'),
('عثمان بن عفان', 'islamic_figures', 'medium'),
('علي بن أبي طالب', 'islamic_figures', 'easy'),
('بلال بن رباح', 'islamic_figures', 'medium'),
('سعد بن أبي وقاص', 'islamic_figures', 'medium'),
('طارق بن زياد', 'islamic_figures', 'medium'),
('الإمام البخاري', 'islamic_figures', 'hard'),

-- منتجات يومية
('معجون أسنان', 'daily_products', 'easy'),
('شامبو', 'daily_products', 'easy'),
('صابون', 'daily_products', 'easy'),
('فرشاة أسنان', 'daily_products', 'easy'),
('مناديل', 'daily_products', 'easy'),
('مزيل عرق', 'daily_products', 'medium'),
('كريم حلاقة', 'daily_products', 'medium'),
('غسول وجه', 'daily_products', 'medium'),
('سائل غسيل أطباق', 'daily_products', 'easy'),
('مسحوق غسيل', 'daily_products', 'easy'),
('إسفنجة', 'daily_products', 'easy'),
('منشفة', 'daily_products', 'easy'),
('ورق تواليت', 'daily_products', 'easy'),
('صابون سائل لليد', 'daily_products', 'easy'),
('كريم مرطب', 'daily_products', 'medium')
ON CONFLICT (name) DO NOTHING;
-- ========================================
-- Time Synchronization Function
-- ========================================
-- Returns current server time for client synchronization
CREATE OR REPLACE FUNCTION get_server_time()
RETURNS TABLE(server_time TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
  RETURN QUERY SELECT NOW();
END;
$$ LANGUAGE plpgsql;