begin;

select plan(48);

-- Fixture identities (fresh e1/e2/e3/e4 prefixes, unused by other test files).
--   a1 host of room A, a2 player in room A, a3 imposter in room A
--   b1 host of room B (an outsider to room A)
--   c1 creates a room through the RPC, d1 joins room A through the RPC
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('e1000000-0000-4000-8000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-a1@example.test', '', now(), now()),
  ('e1000000-0000-4000-8000-0000000000a2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-a2@example.test', '', now(), now()),
  ('e1000000-0000-4000-8000-0000000000a3', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-a3@example.test', '', now(), now()),
  ('e1000000-0000-4000-8000-0000000000b1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-b1@example.test', '', now(), now()),
  ('e1000000-0000-4000-8000-0000000000c1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-c1@example.test', '', now(), now()),
  ('e1000000-0000-4000-8000-0000000000d1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p0-d1@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, current_round, room_code, status, game_mode)
values
  ('e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-0000000000a1', 'animals', 3, 5, 60, 1, '990001', 'waiting', 'online'),
  ('e2000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-0000000000b1', 'animals', 3, 4, 60, 1, '990002', 'waiting', 'online');

insert into public.players (id, room_id, user_id, username, score, is_host, is_online, created_at, last_seen_at)
values
  ('e3000000-0000-4000-8000-000000000001', 'e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-0000000000a1', 'P0 Host', 0, true, true, '2026-01-01', '2020-01-01'),
  ('e3000000-0000-4000-8000-000000000002', 'e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-0000000000a2', 'P0 Two', 0, false, true, '2026-01-02', '2020-01-01'),
  ('e3000000-0000-4000-8000-000000000003', 'e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-0000000000a3', 'P0 Three', 0, false, true, '2026-01-03', '2020-01-01'),
  ('e3000000-0000-4000-8000-000000000011', 'e2000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-0000000000b1', 'P0 Other Host', 0, true, true, '2026-01-01', '2020-01-01');

insert into public.rounds (id, room_id, imposter_player_id, character_id, round_number, phase, phase_end_time)
values
  ('e4000000-0000-4000-8000-000000000001', 'e2000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000003', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'hints', '2099-01-01');

-- Fixture hint written by the host (postgres bypasses the client privileges).
insert into public.hints (round_id, player_id, content)
values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001', 'host hint');

-- ---------------------------------------------------------------------------
-- Catalog contracts (run as postgres)
-- ---------------------------------------------------------------------------
select is(
  (select count(*)::bigint from pg_policies
   where schemaname = 'public'
     and policyname in (
       'Anyone can create room', 'Anyone can join as player',
       'Only host can manage rounds', 'Only host can modify rounds',
       'Only host can delete rounds', 'Only host can update room'
     )),
  0::bigint,
  'direct-write policies for room creation, joining, rounds and room updates are absent'
);
select is(
  (select count(*)::bigint from pg_policies
   where schemaname = 'public'
     and tablename in ('players', 'rooms', 'hints')
     and cmd = 'SELECT'
     and qual = 'true'),
  0::bigint,
  'players, rooms and hints have no unconditional SELECT policy'
);
select ok(
  not (
    has_table_privilege('anon', 'public.players', 'SELECT')
    or has_table_privilege('anon', 'public.rooms', 'SELECT')
    or has_table_privilege('anon', 'public.rounds', 'SELECT')
    or has_table_privilege('anon', 'public.hints', 'SELECT')
    or has_table_privilege('anon', 'public.votes', 'SELECT')
    or has_table_privilege('anon', 'public.messages', 'SELECT')
  ),
  'anon cannot SELECT per-room tables'
);
select ok(
  not (
    has_table_privilege('authenticated', 'public.players', 'INSERT')
    or has_table_privilege('authenticated', 'public.players', 'DELETE')
    or has_table_privilege('authenticated', 'public.rooms', 'INSERT')
    or has_table_privilege('authenticated', 'public.rooms', 'UPDATE')
    or has_table_privilege('authenticated', 'public.rooms', 'DELETE')
    or has_table_privilege('authenticated', 'public.rounds', 'INSERT')
    or has_table_privilege('authenticated', 'public.rounds', 'UPDATE')
    or has_table_privilege('authenticated', 'public.rounds', 'DELETE')
  ),
  'authenticated has no direct write privilege on players, rooms or rounds'
);
select ok(
  has_column_privilege('authenticated', 'public.players', 'is_online', 'UPDATE')
  and has_column_privilege('authenticated', 'public.players', 'last_seen_at', 'UPDATE'),
  'authenticated can update the presence columns'
);
select ok(
  not (
    has_column_privilege('authenticated', 'public.players', 'score', 'UPDATE')
    or has_column_privilege('authenticated', 'public.players', 'is_host', 'UPDATE')
    or has_column_privilege('authenticated', 'public.players', 'room_id', 'UPDATE')
    or has_column_privilege('authenticated', 'public.players', 'username', 'UPDATE')
    or has_column_privilege('authenticated', 'public.players', 'user_id', 'UPDATE')
  ),
  'authenticated cannot update any non-presence player column'
);

-- ---------------------------------------------------------------------------
-- Room member (a2): sees own room, not another room
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a2', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is((select count(*) from public.players where room_id = 'e2000000-0000-4000-8000-000000000001'), 3::bigint, 'member sees every player in their room');
select is((select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000001'), 1::bigint, 'member sees their room');
select is((select count(*) from public.hints where round_id = 'e4000000-0000-4000-8000-000000000001'), 1::bigint, 'member sees hints for their room round');
select is((select count(*) from public.players where room_id = 'e2000000-0000-4000-8000-000000000002'), 0::bigint, 'member does not see players of another room');
select is((select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000002'), 0::bigint, 'member does not see another room');

-- ---------------------------------------------------------------------------
-- Non-member (b1) sees nothing of room A
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000b1","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000b1', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is((select count(*) from public.players where room_id = 'e2000000-0000-4000-8000-000000000001'), 0::bigint, 'non-member sees no players of another room');
select is((select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000001'), 0::bigint, 'non-member sees no rooms of others');
select is((select count(*) from public.hints where round_id = 'e4000000-0000-4000-8000-000000000001'), 0::bigint, 'non-member sees no hints of another room');
select is((select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000002'), 1::bigint, 'non-member still sees their own room');

-- ---------------------------------------------------------------------------
-- anon has no access to per-room tables
-- ---------------------------------------------------------------------------
reset role;
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

select throws_ok($$select count(*) from public.players$$, '42501', null, 'anon cannot SELECT players');
select throws_ok($$select count(*) from public.rooms$$, '42501', null, 'anon cannot SELECT rooms');
select throws_ok($$select count(*) from public.hints$$, '42501', null, 'anon cannot SELECT hints');

-- ---------------------------------------------------------------------------
-- Player a2: no self-service privilege escalation
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a2', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok($$update public.players set score = 1000 where id = 'e3000000-0000-4000-8000-000000000002'$$, '42501', null, 'player cannot update own score');
select throws_ok($$update public.players set is_host = true where id = 'e3000000-0000-4000-8000-000000000002'$$, '42501', null, 'player cannot make themselves host');
select throws_ok($$update public.players set room_id = 'e2000000-0000-4000-8000-000000000002' where id = 'e3000000-0000-4000-8000-000000000002'$$, '42501', null, 'player cannot move themselves to another room');
select throws_ok($$update public.players set username = 'Renamed' where id = 'e3000000-0000-4000-8000-000000000002'$$, '42501', null, 'player cannot change their username directly');
select lives_ok($$update public.players set is_online = false where id = 'e3000000-0000-4000-8000-000000000001'$$, 'updating another player runs but is filtered by RLS');

-- Presence: the server clock wins over an arbitrary client timestamp.
select lives_ok(
  $$update public.players set is_online = false, last_seen_at = '2000-01-01T00:00:00Z' where id = 'e3000000-0000-4000-8000-000000000002'$$,
  'player can mark themselves offline with a backdated client clock'
);
select is(
  (select is_online = false and abs(extract(epoch from (last_seen_at - now()))) < 5
   from public.players where id = 'e3000000-0000-4000-8000-000000000002'),
  true,
  'backdated client last_seen_at is replaced with the server time'
);
select is(
  (select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000001'),
  1::bigint,
  'offline member keeps read access to their room'
);
select lives_ok(
  $$update public.players set is_online = true, last_seen_at = now() + interval '1 day' where id = 'e3000000-0000-4000-8000-000000000002'$$,
  'player can come back online with a future client clock'
);
select is(
  (select is_online = true and abs(extract(epoch from (last_seen_at - now()))) < 5
   from public.players where id = 'e3000000-0000-4000-8000-000000000002'),
  true,
  'future client last_seen_at is replaced with the server time'
);

-- Defense in depth: even if a grant drifts, the trigger refuses other columns.
reset role;
grant update (score) on public.players to authenticated;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a2', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select throws_ok(
  $$update public.players set score = 1000 where id = 'e3000000-0000-4000-8000-000000000002'$$,
  '42501', 'PLAYER_COLUMN_UPDATE_FORBIDDEN',
  'trigger blocks non-presence column changes even if a grant drifts'
);
reset role;
revoke update (score) on public.players from authenticated;

-- ---------------------------------------------------------------------------
-- No direct inserts into players/rooms
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a2', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$insert into public.players (room_id, user_id, username) values ('e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-0000000000a2', 'Forged')$$,
  '42501', null, 'authenticated cannot insert players directly'
);
select throws_ok(
  $$insert into public.rooms (host_id, category, max_rounds, max_players, round_duration, room_code)
    values ('e1000000-0000-4000-8000-0000000000a2', 'animals', 3, 4, 60, '990003')$$,
  '42501', null, 'authenticated cannot insert rooms directly'
);

-- ---------------------------------------------------------------------------
-- Host (a1): no direct round or room writes
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a1","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a1', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$insert into public.rounds (room_id, imposter_player_id, character_id, round_number, phase, phase_end_time)
    values ('e2000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000003', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 2, 'hints', '2099-01-01')$$,
  '42501', null, 'host cannot insert rounds directly'
);
select throws_ok(
  $$update public.rounds set phase = 'results' where id = 'e4000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'host cannot force a round into results'
);
select throws_ok(
  $$delete from public.rounds where id = 'e4000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'host cannot delete rounds directly'
);
select throws_ok(
  $$update public.rooms set status = 'finished' where id = 'e2000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'host cannot update the room directly'
);

-- ---------------------------------------------------------------------------
-- Regression: hint and vote upserts still work for members
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a2', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$insert into public.hints (round_id, player_id, content)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000002', 'first hint')
    on conflict (round_id, player_id) do update set content = excluded.content$$,
  'member can insert their hint in the hints phase'
);
select lives_ok(
  $$insert into public.hints (round_id, player_id, content)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000002', 'second hint')
    on conflict (round_id, player_id) do update set content = excluded.content$$,
  'member can upsert their hint again'
);
select is(
  (select content from public.hints where player_id = 'e3000000-0000-4000-8000-000000000002'),
  'second hint',
  'member reads back their updated hint'
);
select throws_ok(
  $$insert into public.hints (round_id, player_id, content)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000003', 'forged hint')$$,
  '42501', null,
  'member cannot write a hint for another player'
);

reset role;
update public.rounds set phase = 'voting' where id = 'e4000000-0000-4000-8000-000000000001';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000a1","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000a1', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$insert into public.hints (round_id, player_id, content)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001', 'late hint')$$,
  '42501', null,
  'hint writes are rejected outside the hints phase'
);
select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000002')
    on conflict (round_id, voter_player_id) do update set voted_player_id = excluded.voted_player_id$$,
  'member can insert their vote in the voting phase'
);
select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('e4000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000003')
    on conflict (round_id, voter_player_id) do update set voted_player_id = excluded.voted_player_id$$,
  'member can change their vote with an upsert'
);

-- ---------------------------------------------------------------------------
-- Regression: create_room and join_room RPCs still work and grant visibility
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000c1","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000c1', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.create_room(
    'e5000000-0000-4000-8000-000000000001',
    'animals', 3, 4, 60, 'online', 'P0 Creator', array[]::text[]
  )$$,
  'create_room RPC still works for authenticated users'
);
select is(
  (select count(*) from public.rooms where host_id = 'e1000000-0000-4000-8000-0000000000c1'),
  1::bigint,
  'room creator can read the room created through the RPC'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"e1000000-0000-4000-8000-0000000000d1","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-0000000000d1', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000001'),
  0::bigint,
  'joining player cannot read the room before joining'
);
select lives_ok(
  $$select public.join_room('990001', 'P0 Joiner')$$,
  'join_room RPC still works for authenticated users'
);
select is(
  (select count(*) from public.rooms where id = 'e2000000-0000-4000-8000-000000000001'),
  1::bigint,
  'joined player can read the room after joining'
);

-- ---------------------------------------------------------------------------
-- Rejected cross-player update left no trace
-- ---------------------------------------------------------------------------
reset role;
select is(
  (select is_online from public.players where id = 'e3000000-0000-4000-8000-000000000001'),
  true,
  'a player cannot take another player offline through RLS-filtered updates'
);

select * from finish();
rollback;
