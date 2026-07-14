begin;

select plan(14);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('11000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-host@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-two@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-three@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-four@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-five@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-six@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-seven@example.test', '', now(), now()),
  ('11000000-0000-4000-8000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p3-eight@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, room_code, status, game_mode)
values
  ('21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, '930001', 'waiting', 'online'),
  ('21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000005', 'animals', 3, 4, 60, '930002', 'waiting', 'online');

insert into public.players (id, room_id, user_id, username, is_host, is_online, created_at, last_seen_at)
values
  ('31000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'Host One', true, true, '2026-01-01 00:00:00', now()),
  ('31000000-0000-4000-8000-000000000002', '21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000002', 'Oldest Two', false, true, '2026-01-02 00:00:00', now()),
  ('31000000-0000-4000-8000-000000000003', '21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000003', 'Third', false, true, '2026-01-03 00:00:00', now()),
  ('31000000-0000-4000-8000-000000000004', '21000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000004', 'Fourth', false, true, '2026-01-04 00:00:00', now()),
  ('32000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000005', 'Host Five', true, true, '2026-02-01 00:00:00', now()),
  ('32000000-0000-4000-8000-000000000002', '21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000006', 'Six', false, true, '2026-02-02 00:00:00', now()),
  ('32000000-0000-4000-8000-000000000003', '21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000007', 'Seven', false, true, '2026-02-03 00:00:00', now()),
  ('32000000-0000-4000-8000-000000000004', '21000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000008', 'Eight', false, true, '2026-02-04 00:00:00', now());

update public.rooms set status = 'active' where id in ('21000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000002');

-- Heartbeat changes freshness without changing authority.
update public.players set last_seen_at = now() + interval '1 second' where id = '31000000-0000-4000-8000-000000000002';
select is((select is_online from public.players where id = '31000000-0000-4000-8000-000000000002'), true, 'heartbeat keeps player online');

-- Formal host departure migrates to the oldest online player.
update public.players set is_online = false where id = '31000000-0000-4000-8000-000000000001';
select is((select count(*) from public.players where room_id = '21000000-0000-4000-8000-000000000001' and is_online and is_host), 1::bigint, 'host departure leaves exactly one online host');
select is((select id from public.players where room_id = '21000000-0000-4000-8000-000000000001' and is_online and is_host), '31000000-0000-4000-8000-000000000002'::uuid, 'oldest online player becomes host');
select is((select host_id from public.rooms where id = '21000000-0000-4000-8000-000000000001'), '11000000-0000-4000-8000-000000000002'::uuid, 'room authority follows migrated host user');

-- Highest-risk scenario: former host reconnects but cannot reclaim authority.
update public.players set is_online = true, last_seen_at = now() where id = '31000000-0000-4000-8000-000000000001';
select is((select is_host from public.players where id = '31000000-0000-4000-8000-000000000001'), false, 'reconnecting former host does not reclaim host flag');
select is((select count(*) from public.players where room_id = '21000000-0000-4000-8000-000000000001' and is_online and is_host), 1::bigint, 'former-host reconnect still has exactly one online host');

-- Near-simultaneous presence changes are serialized by the room advisory lock.
-- The current host and next-oldest player go offline in one statement.
update public.players
set is_online = false
where id in ('31000000-0000-4000-8000-000000000002', '31000000-0000-4000-8000-000000000003');
select is((select id from public.players where room_id = '21000000-0000-4000-8000-000000000001' and is_online and is_host), '31000000-0000-4000-8000-000000000001'::uuid, 'simultaneous changes deterministically select oldest remaining online player');
select is((select count(*) from public.players where room_id = '21000000-0000-4000-8000-000000000001' and is_online and is_host), 1::bigint, 'simultaneous changes leave exactly one host');

-- Stale cleanup is host-authorized and isolated to its target room.
update public.players set last_seen_at = now() - interval '120 seconds' where id = '31000000-0000-4000-8000-000000000004';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '11000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is(public.mark_stale_players_offline('21000000-0000-4000-8000-000000000001', 60), 1, 'room-scoped cleanup marks one stale player offline');
reset role;
select is((select is_online from public.players where id = '31000000-0000-4000-8000-000000000004'), false, 'stale player is offline after cleanup');
select is((select count(*) from public.players where room_id = '21000000-0000-4000-8000-000000000002' and is_online), 4::bigint, 'targeted cleanup does not affect another room');

-- Abrupt loss of every remaining player finishes only the empty room.
update public.players set is_online = false where room_id = '21000000-0000-4000-8000-000000000001';
select is((select status from public.rooms where id = '21000000-0000-4000-8000-000000000001'), 'finished', 'empty active room finishes deterministically');
select is((select status from public.rooms where id = '21000000-0000-4000-8000-000000000002'), 'active', 'unrelated active room remains active');

-- Reconciliation remains stable when explicitly invoked again.
select lives_ok($$select public.reconcile_room_after_presence_change('21000000-0000-4000-8000-000000000001')$$, 'reconciling an already-finished room is idempotent');

select * from finish();
rollback;
