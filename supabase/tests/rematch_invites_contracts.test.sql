begin;

select plan(16);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('a1000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-host@example.test', '', now(), now()),
  ('a1000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-two@example.test', '', now(), now()),
  ('a1000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-three@example.test', '', now(), now()),
  ('a1000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-four@example.test', '', now(), now()),
  ('a1000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-outsider@example.test', '', now(), now()),
  ('a1000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rm-local-host@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, room_code, status, game_mode)
values
  ('a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, '961001', 'waiting', 'online'),
  ('a2000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000006', 'animals', 2, 4, 60, '961002', 'waiting', 'local');

insert into public.players (id, room_id, user_id, username, is_host, is_online, created_at, last_seen_at)
values
  ('a3000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'Host', true, true, '2026-01-01 00:00:00', now()),
  ('a3000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'Two', false, true, '2026-01-02 00:00:00', now()),
  ('a3000000-0000-4000-8000-000000000003', 'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'Three', false, true, '2026-01-03 00:00:00', now()),
  ('a3000000-0000-4000-8000-000000000004', 'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004', 'Four', false, true, '2026-01-04 00:00:00', now()),
  ('a3100000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000006', 'Ali', true, true, '2026-01-01 00:00:00', now());

-- Only the online room goes through 'active': trigger_create_first_round
-- needs 4 players, and the local fixture only has to end up 'finished'.
update public.rooms set status = 'active' where id = 'a2000000-0000-4000-8000-000000000001';

-- As the host, while the game is still running.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select throws_ok(
  $$select public.create_rematch('a2000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000001', 'foods', 2, 4, 90, 'Host')$$,
  'P0001', 'ROOM_NOT_FINISHED', 'cannot rematch a room that is still playing'
);
reset role;

update public.rooms set status = 'finished' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002');
-- Stale cleanup may have marked the host offline on the Game Over screen.
update public.players set is_online = false where id = 'a3000000-0000-4000-8000-000000000001';

-- A non-host member cannot start the rematch.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
select throws_ok(
  $$select public.create_rematch('a2000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000002', 'foods', 2, 4, 90, 'Two')$$,
  '42501', 'HOST_REQUIRED', 'non-host cannot start a rematch'
);

-- The host starts the rematch with changed settings.
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select is(
  (public.create_rematch('a2000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000001', 'foods', 2, 4, 90, 'Host') -> 'room' ->> 'id')::uuid,
  'a4000000-0000-4000-8000-000000000001'::uuid,
  'host gets the new room'
);
-- Retrying the same request is idempotent.
select is(
  (public.create_rematch('a2000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000001', 'foods', 2, 4, 90, 'Host') -> 'room' ->> 'id')::uuid,
  'a4000000-0000-4000-8000-000000000001'::uuid,
  'retrying returns the same room'
);
reset role;

select is(
  (select row(status, category, max_rounds, round_duration, game_mode, rematch_of)::text from public.rooms where id = 'a4000000-0000-4000-8000-000000000001'),
  row('waiting', 'foods', 2, 90, 'online', 'a2000000-0000-4000-8000-000000000001'::uuid)::text,
  'new room uses the chosen settings and points at the finished room'
);
select is(
  (select array_agg(username order by username) from public.room_invites where room_id = 'a4000000-0000-4000-8000-000000000001' and status = 'pending'),
  array['Four', 'Three', 'Two'],
  'every other player is invited exactly once'
);

-- Invitee sees their invite; an outsider sees nothing and cannot respond.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
select is(
  (select count(*) from public.room_invites where previous_room_id = 'a2000000-0000-4000-8000-000000000001'),
  1::bigint,
  'invitee sees only their own invite'
);
select throws_ok(
  $$insert into public.room_invites (room_id, previous_room_id, user_id, username) values ('a4000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005', 'Sneak')$$,
  '42501', null, 'clients cannot write invites directly'
);

select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000005","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000005', true);
select is((select count(*) from public.room_invites), 0::bigint, 'outsider sees no invites');
select throws_ok(
  $$select public.respond_rematch_invite('a4000000-0000-4000-8000-000000000001', true)$$,
  'P0002', 'INVITE_NOT_FOUND', 'outsider cannot accept an invite'
);

-- Two accepts and joins under the same name; Three declines.
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
select is(
  public.respond_rematch_invite('a4000000-0000-4000-8000-000000000001', true) -> 'player' ->> 'username',
  'Two',
  'accepting joins the new room with the same name'
);

select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000003', true);
select ok(public.respond_rematch_invite('a4000000-0000-4000-8000-000000000001', false) is null, 'declining returns nothing');
reset role;

select is(
  (select array_agg(username || ':' || status order by username) from public.room_invites where room_id = 'a4000000-0000-4000-8000-000000000001'),
  array['Four:pending', 'Three:declined', 'Two:accepted'],
  'invite statuses reflect the answers'
);
select is(
  (select array_agg(username order by username) from public.players where room_id = 'a4000000-0000-4000-8000-000000000001'),
  array['Host', 'Two'],
  'only the host and the accepted player are in the new room'
);

-- Shared-Device rematch keeps the names and sends no invites.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1000000-0000-4000-8000-000000000006","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000006', true);
select is(
  jsonb_array_length(public.create_rematch('a2000000-0000-4000-8000-000000000002', 'a4000000-0000-4000-8000-000000000002', 'animals', 2, 4, 60, 'Ali', array['Badr', 'Cala', 'Dina']) -> 'players'),
  4,
  'shared-device rematch recreates all four local players'
);
reset role;
select is(
  (select count(*) from public.room_invites where room_id = 'a4000000-0000-4000-8000-000000000002'),
  0::bigint,
  'shared-device rematch sends no invites'
);

select * from finish();
rollback;
