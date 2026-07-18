begin;

select plan(8);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, created_at, updated_at
) values
  ('71000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'vote-host@example.test', '', now(), now()),
  ('71000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'vote-player@example.test', '', now(), now()),
  ('71000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'vote-third@example.test', '', now(), now());

insert into public.rooms (
  id, host_id, category, max_rounds, max_players, round_duration,
  current_round, room_code, status, game_mode
) values
  ('72000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, 1, '970001', 'waiting', 'online'),
  ('72000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, 1, '970002', 'waiting', 'local');

insert into public.players (
  id, room_id, user_id, username, score, is_host, is_online, created_at
) values
  ('73000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', 'Online Host', 0, true, true, '2026-01-01'),
  ('73000000-0000-4000-8000-000000000002', '72000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000002', 'Online Two', 0, false, true, '2026-01-02'),
  ('73000000-0000-4000-8000-000000000003', '72000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000003', 'Online Three', 0, false, true, '2026-01-03'),
  ('74000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000001', 'Shared Host', 0, true, true, '2026-01-01'),
  ('74000000-0000-4000-8000-000000000002', '72000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000002', 'Shared Two', 0, false, true, '2026-01-02'),
  ('74000000-0000-4000-8000-000000000003', '72000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000003', 'Shared Three', 0, false, true, '2026-01-03');

update public.rooms
set status = 'active'
where id in (
  '72000000-0000-4000-8000-000000000001',
  '72000000-0000-4000-8000-000000000002'
);

insert into public.rounds (
  id, room_id, imposter_player_id, character_id, round_number, phase,
  phase_end_time
) values
  ('75000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000003', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'voting', '2099-01-01'),
  ('75000000-0000-4000-8000-000000000002', '72000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000003', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'voting', '2099-01-01');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"71000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '71000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000002')$$,
  'online participant can insert a vote while active round rows stay redacted'
);
select is(
  (select count(*) from public.rounds where id = '75000000-0000-4000-8000-000000000001'),
  0::bigint,
  'online active round remains hidden from raw SELECT'
);
select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000003')
    on conflict (round_id, voter_player_id) do update
    set voted_player_id = excluded.voted_player_id$$,
  'online participant can upsert their own vote'
);
select throws_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000003')$$,
  '42501', null,
  'online participant cannot submit another player vote'
);

select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000003')$$,
  'shared-device host can insert a participant vote'
);
select lives_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000001')
    on conflict (round_id, voter_player_id) do update
    set voted_player_id = excluded.voted_player_id$$,
  'shared-device host can upsert a participant vote'
);
insert into public.votes (round_id, voter_player_id, voted_player_id)
values (
  '75000000-0000-4000-8000-000000000002',
  '74000000-0000-4000-8000-000000000003',
  '74000000-0000-4000-8000-000000000001'
);

select set_config('request.jwt.claims', '{"sub":"71000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '71000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select throws_ok(
  $$insert into public.votes (round_id, voter_player_id, voted_player_id)
    values ('75000000-0000-4000-8000-000000000002', '74000000-0000-4000-8000-000000000003', '74000000-0000-4000-8000-000000000001')$$,
  '42501', null,
  'shared-device non-host cannot submit participant votes'
);
select is(
  (select count(*) from public.votes where round_id = '75000000-0000-4000-8000-000000000002'),
  1::bigint,
  'shared-device non-host sees only their own raw vote'
);

select * from finish();
rollback;
