begin;

select plan(12);

-- 1. No timestamp-without-time-zone columns remain in public tables.
select is(
  (select count(*)
   from information_schema.columns c
   join information_schema.tables t
     on t.table_schema = c.table_schema and t.table_name = c.table_name
    and t.table_type = 'BASE TABLE'
   where c.table_schema = 'public'
     and c.data_type = 'timestamp without time zone'),
  0::bigint,
  'no public table column is timestamp without time zone'
);

select col_type_is('public', 'rounds', 'phase_end_time', 'timestamp with time zone', 'rounds.phase_end_time is timestamptz');
select col_type_is('public', 'rounds', 'created_at', 'timestamp with time zone', 'rounds.created_at is timestamptz');
select col_type_is('public', 'players', 'created_at', 'timestamp with time zone', 'players.created_at is timestamptz');
select col_type_is('public', 'hints', 'timestamp', 'timestamp with time zone', 'hints.timestamp is timestamptz');

-- 2. Fixtures.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('f5100000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tz-host@example.test', '', now(), now()),
  ('f5100000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tz-two@example.test', '', now(), now()),
  ('f5100000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tz-three@example.test', '', now(), now()),
  ('f5100000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'tz-four@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, room_code, status, game_mode)
values
  ('f5200000-0000-4000-8000-000000000001', 'f5100000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, '953001', 'waiting', 'online'),
  ('f5200000-0000-4000-8000-000000000002', 'f5100000-0000-4000-8000-000000000001', 'animals', 3, 4, 120, '953002', 'waiting', 'local');

insert into public.players (id, room_id, user_id, username, is_host, is_online)
values
  ('f5300000-0000-4000-8000-000000000001', 'f5200000-0000-4000-8000-000000000001', 'f5100000-0000-4000-8000-000000000001', 'Tz Host', true, true),
  ('f5300000-0000-4000-8000-000000000002', 'f5200000-0000-4000-8000-000000000001', 'f5100000-0000-4000-8000-000000000002', 'Tz Two', false, true),
  ('f5300000-0000-4000-8000-000000000003', 'f5200000-0000-4000-8000-000000000001', 'f5100000-0000-4000-8000-000000000003', 'Tz Three', false, true),
  ('f5300000-0000-4000-8000-000000000004', 'f5200000-0000-4000-8000-000000000001', 'f5100000-0000-4000-8000-000000000004', 'Tz Four', false, true),
  ('f5400000-0000-4000-8000-000000000001', 'f5200000-0000-4000-8000-000000000002', 'f5100000-0000-4000-8000-000000000001', 'Loc Host', true, true),
  ('f5400000-0000-4000-8000-000000000002', 'f5200000-0000-4000-8000-000000000002', 'f5100000-0000-4000-8000-000000000002', 'Loc Two', false, true),
  ('f5400000-0000-4000-8000-000000000003', 'f5200000-0000-4000-8000-000000000002', 'f5100000-0000-4000-8000-000000000003', 'Loc Three', false, true),
  ('f5400000-0000-4000-8000-000000000004', 'f5200000-0000-4000-8000-000000000002', 'f5100000-0000-4000-8000-000000000004', 'Loc Four', false, true);

-- Run the whole check in a non-UTC session to prove results do not depend on
-- the session TimeZone.
set local timezone = 'Asia/Tokyo';

-- 3. Starting the game creates round 1 through the trigger; its timer must be
--    now() + round_duration as an absolute instant.
update public.rooms set status = 'active' where id = 'f5200000-0000-4000-8000-000000000001';
update public.rooms set status = 'active' where id = 'f5200000-0000-4000-8000-000000000002';

select ok(
  (select r.phase_end_time > now() + interval '55 seconds'
      and r.phase_end_time <= now() + interval '61 seconds'
   from public.rounds r where r.room_id = 'f5200000-0000-4000-8000-000000000001' and r.round_number = 1),
  'first round hints timer ends ~60s in the future (non-UTC session)'
);

select ok(
  (select r.created_at <= now() and r.created_at > now() - interval '1 minute'
   from public.rounds r where r.room_id = 'f5200000-0000-4000-8000-000000000001' and r.round_number = 1),
  'rounds.created_at is the current instant (non-UTC session)'
);

-- 4. Host advances to voting: timer reset to ~300s ahead.
create temporary table tz_ctx on commit drop as
select
  (select id from public.rounds where room_id = 'f5200000-0000-4000-8000-000000000001' and round_number = 1) as online_round,
  (select id from public.rounds where room_id = 'f5200000-0000-4000-8000-000000000002' and round_number = 1) as local_round;
grant select on tz_ctx to authenticated;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"f5100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f5100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- Local-mode reveal extension: ~120s round + 30s.
select lives_ok(
  $$select public.extend_local_role_reveal((select local_round from tz_ctx), 30)$$,
  'host can extend the shared-device reveal timer'
);
select lives_ok(
  $$select public.advance_to_voting((select online_round from tz_ctx))$$,
  'host advances online round to voting'
);

-- Snapshot RPC as the host (rounds rows are RLS-hidden while in progress).
create temporary table tz_snapshot on commit drop as
select s.phase_end_time from public.get_round_for_player_v2((select online_round from tz_ctx)) s;

reset role;

select ok(
  (select r.phase_end_time > now() + interval '145 seconds' and r.phase_end_time <= now() + interval '151 seconds'
   from public.rounds r where r.id = (select local_round from tz_ctx)),
  'extended reveal timer = max(phase_end_time, now()) + 30s'
);
select ok(
  (select r.phase = 'voting'
      and r.phase_end_time > now() + interval '295 seconds'
      and r.phase_end_time <= now() + interval '301 seconds'
   from public.rounds r where r.id = (select online_round from tz_ctx)),
  'voting timer ends ~300s in the future'
);
select is(
  (select phase_end_time from tz_snapshot),
  (select r.phase_end_time from public.rounds r where r.id = (select online_round from tz_ctx)),
  'get_round_for_player_v2 returns the stored phase_end_time unchanged'
);

select * from finish();
rollback;
