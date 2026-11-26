begin;

select plan(12);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('b1000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'st-one@example.test', '', now(), now()),
  ('b1000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'st-two@example.test', '', now(), now()),
  ('b1000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'st-three@example.test', '', now(), now()),
  ('b1000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'st-four@example.test', '', now(), now()),
  ('b1000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'st-new@example.test', '', now(), now());

-- R1: finished online game (counted). R2: finished shared-device game
-- (counts as played; its score, wins and impostor rounds do not).
-- R3: online game still running (ignored).
insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, room_code, status, game_mode)
values
  ('b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'animals', 4, 4, 60, '962001', 'waiting', 'online'),
  ('b2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'animals', 2, 4, 60, '962002', 'waiting', 'local'),
  ('b2000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000001', 'animals', 2, 4, 60, '962003', 'waiting', 'online');

insert into public.players (id, room_id, user_id, username, score, is_host, is_online)
values
  ('b3000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'One', 30, true, true),
  ('b3000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000002', 'Two', 10, false, true),
  ('b3000000-0000-4000-8000-000000000003', 'b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000003', 'Three', 20, false, true),
  ('b3000000-0000-4000-8000-000000000004', 'b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000004', 'Four', 10, false, true),
  ('b3100000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'One', 100, true, true),
  ('b3200000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000001', 'One', 50, true, true);

-- Players can only join a waiting room (enforce_room_capacity), so finish
-- the rooms afterwards. waiting -> finished skips trigger_create_first_round.
update public.rooms set status = 'finished'
where id in ('b2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000002');

-- Round 1: Two is the impostor and is caught (3 votes, alone at the top).
-- Round 2: One is the impostor and escapes (Three tops the vote).
-- Round 3: not finalized, so it is ignored.
-- Round 4: Two is the impostor and escapes on a tie at the top.
-- Round 5: shared-device round with One as impostor: played, nothing else.
insert into public.rounds (id, room_id, imposter_player_id, character_id, round_number, phase, phase_end_time, imposter_revealed, scores_finalized_at)
values
  ('b4000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000002', (select id from public.characters limit 1), 1, 'results', now(), true, now()),
  ('b4000000-0000-4000-8000-000000000005', 'b2000000-0000-4000-8000-000000000002', 'b3100000-0000-4000-8000-000000000001', (select id from public.characters limit 1), 1, 'results', now(), true, now()),
  ('b4000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001', (select id from public.characters limit 1), 2, 'results', now(), true, now()),
  ('b4000000-0000-4000-8000-000000000003', 'b2000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001', (select id from public.characters limit 1), 3, 'voting', now(), false, null),
  ('b4000000-0000-4000-8000-000000000004', 'b2000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000002', (select id from public.characters limit 1), 4, 'results', now(), true, now());

insert into public.round_participants (round_id, player_id)
select r.id, p.id
from public.rounds r
cross join public.players p
where r.room_id in ('b2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000002')
  and p.room_id = r.room_id
-- trigger_capture_round_state may already have added them.
on conflict do nothing;

insert into public.votes (round_id, voter_player_id, voted_player_id)
values
  ('b4000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000002'),
  ('b4000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000003', 'b3000000-0000-4000-8000-000000000002'),
  ('b4000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000004', 'b3000000-0000-4000-8000-000000000002'),
  ('b4000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000001'),
  ('b4000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000003'),
  ('b4000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000003', 'b3000000-0000-4000-8000-000000000004'),
  ('b4000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000004', 'b3000000-0000-4000-8000-000000000003'),
  ('b4000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000003'),
  ('b4000000-0000-4000-8000-000000000003', 'b3000000-0000-4000-8000-000000000002', 'b3000000-0000-4000-8000-000000000001'),
  ('b4000000-0000-4000-8000-000000000004', 'b3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000002'),
  ('b4000000-0000-4000-8000-000000000004', 'b3000000-0000-4000-8000-000000000003', 'b3000000-0000-4000-8000-000000000004');

select ok(
  not has_function_privilege('anon', 'public.get_my_stats()', 'execute'),
  'anon cannot read stats'
);

-- Player One: won the game, escaped once as impostor, voted right in
-- rounds 1 and 4.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000001', true);
select is((public.get_my_stats() ->> 'games_played')::int, 2, 'finished games count in both modes, running ones do not');
select is((public.get_my_stats() ->> 'games_won')::int, 1, 'top score wins; shared-device scores never win');
select is((public.get_my_stats() ->> 'rounds_played')::int, 4, 'shared-device rounds count, unfinalized rounds do not');
select is((public.get_my_stats() ->> 'rounds_as_imposter')::int, 1, 'only online impostor rounds are counted');
select is((public.get_my_stats() ->> 'imposter_escapes')::int, 1, 'escape when another player tops the vote');
select is((public.get_my_stats() ->> 'correct_votes')::int, 2, 'votes for the impostor are counted');
reset role;

-- Player Two: lost, caught in round 1, escaped on a tie in round 4.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000002', true);
select is((public.get_my_stats() ->> 'games_won')::int, 0, 'lower score does not win');
select is((public.get_my_stats() ->> 'rounds_as_imposter')::int, 2, 'both impostor rounds counted');
select is((public.get_my_stats() ->> 'imposter_escapes')::int, 1, 'a tie at the top lets the impostor escape');
reset role;

-- A player with no games gets zeros, not nulls.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"b1000000-0000-4000-8000-000000000005","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000005', true);
select is(public.get_my_stats(), '{"games_played":0,"games_won":0,"rounds_played":0,"rounds_as_imposter":0,"imposter_escapes":0,"correct_votes":0}'::jsonb, 'new player gets zeros');
reset role;

-- No session at all.
select set_config('request.jwt.claims', '', true);
select set_config('request.jwt.claim.sub', '', true);
select throws_ok($$select public.get_my_stats()$$, '28000', 'AUTH_REQUIRED', 'stats need a signed-in player');

select * from finish();
rollback;
