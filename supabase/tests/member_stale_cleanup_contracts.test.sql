begin;

select plan(11);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('f1000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-host@example.test', '', now(), now()),
  ('f1000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-two@example.test', '', now(), now()),
  ('f1000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-three@example.test', '', now(), now()),
  ('f1000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-outsider@example.test', '', now(), now()),
  ('f1000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-other-host@example.test', '', now(), now()),
  ('f1000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'msc-four@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, room_code, status, game_mode)
values
  ('f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, '951001', 'waiting', 'online'),
  ('f2000000-0000-4000-8000-000000000002', 'f1000000-0000-4000-8000-000000000005', 'animals', 3, 4, 60, '951002', 'waiting', 'online');

insert into public.players (id, room_id, user_id, username, is_host, is_online, created_at, last_seen_at)
values
  ('f3000000-0000-4000-8000-000000000001', 'f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'Host One', true, true, '2026-01-01 00:00:00', now()),
  ('f3000000-0000-4000-8000-000000000002', 'f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'Oldest Two', false, true, '2026-01-02 00:00:00', now()),
  ('f3000000-0000-4000-8000-000000000003', 'f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000003', 'Third', false, true, '2026-01-03 00:00:00', now()),
  ('f3000000-0000-4000-8000-000000000004', 'f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000006', 'Fourth', false, true, '2026-01-04 00:00:00', now()),
  ('f3100000-0000-4000-8000-000000000001', 'f2000000-0000-4000-8000-000000000002', 'f1000000-0000-4000-8000-000000000005', 'Other Host', true, true, '2026-02-01 00:00:00', now());

update public.rooms set status = 'active' where id = 'f2000000-0000-4000-8000-000000000001';

-- Host app is killed: still is_online = true but its heartbeat is long gone.
update public.players set last_seen_at = now() - interval '200 seconds' where id = 'f3000000-0000-4000-8000-000000000001';

-- A NON-host online member runs the cleanup.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"f1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f1000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is(public.mark_stale_players_offline('f2000000-0000-4000-8000-000000000001', 90), 1, 'non-host member cleanup marks the crashed host offline');
reset role;

select is((select is_online from public.players where id = 'f3000000-0000-4000-8000-000000000001'), false, 'crashed host is offline');
select is((select id from public.players where room_id = 'f2000000-0000-4000-8000-000000000001' and is_online and is_host), 'f3000000-0000-4000-8000-000000000002'::uuid, 'host migrates to the oldest connected player');
select is((select count(*) from public.players where room_id = 'f2000000-0000-4000-8000-000000000001' and is_online and is_host), 1::bigint, 'room has exactly one online host');
select is((select status from public.rooms where id = 'f2000000-0000-4000-8000-000000000001'), 'active', 'room stays active while members remain');
select is((select count(*) from public.players where room_id = 'f2000000-0000-4000-8000-000000000001' and is_online), 3::bigint, 'fresh players are not marked offline');

-- Non-members, members of other rooms and offline former members are refused.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"f1000000-0000-4000-8000-000000000004","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f1000000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select throws_ok($$select public.mark_stale_players_offline('f2000000-0000-4000-8000-000000000001', 90)$$, '42501', 'ROOM_MEMBER_REQUIRED', 'non-member cannot run stale cleanup');

select set_config('request.jwt.claims', '{"sub":"f1000000-0000-4000-8000-000000000005","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f1000000-0000-4000-8000-000000000005', true);
select throws_ok($$select public.mark_stale_players_offline('f2000000-0000-4000-8000-000000000001', 90)$$, '42501', 'ROOM_MEMBER_REQUIRED', 'member of another room cannot run stale cleanup');

select set_config('request.jwt.claims', '{"sub":"f1000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f1000000-0000-4000-8000-000000000001', true);
select throws_ok($$select public.mark_stale_players_offline('f2000000-0000-4000-8000-000000000001', 90)$$, '42501', 'ROOM_MEMBER_REQUIRED', 'offline former member cannot run stale cleanup');
reset role;

-- Last connected members go stale: the caller is still is_online, so it may
-- clean up; every stale row (including its own) goes offline and the existing
-- presence trigger finishes the empty room.
update public.players set is_online = false where id in ('f3000000-0000-4000-8000-000000000003', 'f3000000-0000-4000-8000-000000000004');
update public.players set last_seen_at = now() - interval '200 seconds' where id = 'f3000000-0000-4000-8000-000000000002';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"f1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'f1000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is(public.mark_stale_players_offline('f2000000-0000-4000-8000-000000000001', 90), 1, 'cleanup of the last stale member succeeds');
reset role;
select is((select status from public.rooms where id = 'f2000000-0000-4000-8000-000000000001'), 'finished', 'room is finished once the last online member is cleaned up');

select * from finish();
rollback;
