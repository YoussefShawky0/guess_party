begin;

select plan(19);

-- Deterministic identities and production-seeded character/category values.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'phase2-host@example.test', '', now(), now()),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'phase2-player@example.test', '', now(), now()),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'phase2-third@example.test', '', now(), now()),
  ('10000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'phase2-fourth@example.test', '', now(), now()),
  ('10000000-0000-4000-8000-000000000099', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'phase2-outsider@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, current_round, room_code, status, game_mode)
values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, 1, '920001', 'waiting', 'online'),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'animals', 3, 4, 60, 1, '920002', 'waiting', 'local');

insert into public.players (id, room_id, user_id, username, score, is_host, is_online, created_at)
values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Host', 0, true, true, '2026-01-01'),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Player Two', 0, false, true, '2026-01-02'),
  ('30000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'Player Three', 0, false, true, '2026-01-03'),
  ('30000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004', 'Player Four', 0, false, true, '2026-01-04'),
  ('31000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Local Host', 0, true, true, '2026-01-01'),
  ('31000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Local Two', 0, false, true, '2026-01-02'),
  ('31000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000003', 'Local Three', 0, false, true, '2026-01-03'),
  ('31000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', 'Local Four', 0, false, true, '2026-01-04');

insert into public.rounds (id, room_id, imposter_player_id, character_id, round_number, phase, phase_end_time)
values
  ('40000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000002', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'hints', '2099-01-01'),
  ('40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', '31000000-0000-4000-8000-000000000002', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'hints', '2099-01-01');

-- Outsider: neither raw RLS rows nor secure RPC snapshots are visible.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000099","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000099', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is((select count(*) from public.rounds where id = '40000000-0000-4000-8000-000000000001'), 0::bigint, 'non-participant cannot read raw protected round');
select is((select count(*) from public.votes where round_id = '40000000-0000-4000-8000-000000000001'), 0::bigint, 'non-participant cannot read raw votes');
select is((select count(*) from public.get_round_for_player_v2('40000000-0000-4000-8000-000000000001')), 0::bigint, 'non-participant gets no secure round snapshot');

-- Non-host participant cannot call any host-only lifecycle RPC.
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select throws_ok($$select public.advance_to_voting('40000000-0000-4000-8000-000000000001')$$, '42501', 'HOST_REQUIRED', 'non-host cannot advance to voting');
select throws_ok($$select public.finalize_voting('40000000-0000-4000-8000-000000000001', 'timer')$$, '42501', 'HOST_REQUIRED', 'non-host cannot finalize voting');
select throws_ok($$select public.create_next_round('20000000-0000-4000-8000-000000000001', 2)$$, '42501', 'HOST_REQUIRED', 'non-host cannot create next round');
select throws_ok($$select public.finish_game('20000000-0000-4000-8000-000000000001')$$, '42501', 'HOST_REQUIRED', 'non-host cannot finish game');

-- Identity-aware redaction during hints.
select is((select character_id is not null and imposter_player_id is null from public.get_round_for_player_v2('40000000-0000-4000-8000-000000000001')), true, 'regular player sees character but not imposter identity');
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is((select character_id is null and imposter_player_id = '30000000-0000-4000-8000-000000000002' from public.get_round_for_player_v2('40000000-0000-4000-8000-000000000001')), true, 'imposter sees own role but not character');

-- Shared-device secret bundle is host-only.
select is((select count(*) from public.get_local_role_reveal_bundle('40000000-0000-4000-8000-000000000002')), 0::bigint, 'non-host cannot read shared-device reveal bundle');
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is((select count(*) from public.get_local_role_reveal_bundle('40000000-0000-4000-8000-000000000002')), 1::bigint, 'shared-device host can read reveal bundle');

reset role;

-- Database constraints, independent of client upsert behavior.
insert into public.hints (round_id, player_id, content) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'first hint');
select throws_ok($$insert into public.hints (round_id, player_id, content) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'second hint')$$, '23505', null, 'database enforces one hint per player per round');
insert into public.votes (round_id, voter_player_id, voted_player_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000002');
select throws_ok($$insert into public.votes (round_id, voter_player_id, voted_player_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000003')$$, '23505', null, 'database enforces one vote per player per round');
select throws_ok($$insert into public.votes (round_id, voter_player_id, voted_player_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003')$$, '23514', null, 'database rejects self-voting');
select throws_ok($$insert into public.players (room_id, user_id, username) values ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000099', 'Overflow')$$, 'P0001', 'ROOM_FULL', 'database enforces room capacity');

-- Complete voting and prove finalization applies scores exactly once.
insert into public.votes (round_id, voter_player_id, voted_player_id) values
 ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001'),
 ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000002'),
 ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000002');
update public.rounds set phase = 'voting' where id = '40000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok($$select public.finalize_voting('40000000-0000-4000-8000-000000000001', 'all_votes')$$, 'first finalization succeeds');
reset role;
create temp table score_snapshot as select id, score from public.players where room_id = '20000000-0000-4000-8000-000000000001';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok($$select public.finalize_voting('40000000-0000-4000-8000-000000000001', 'all_votes')$$, 'second finalization is accepted idempotently');
reset role;
select is((select count(*) from public.players p join score_snapshot s using (id) where p.score <> s.score), 0::bigint, 'double finalization does not apply scores twice');
select is((select scores_finalized_at is not null and phase = 'results' from public.rounds where id = '40000000-0000-4000-8000-000000000001'), true, 'finalization persists authoritative results state');

select * from finish();
rollback;
