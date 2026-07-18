begin;

select plan(17);

select has_function(
  'public', 'delete_current_account',
  'authenticated account deletion RPC exists'
);
select ok(
  has_function_privilege(
    'authenticated', 'public.delete_current_account()', 'EXECUTE'
  ),
  'authenticated can execute account deletion RPC'
);
select ok(
  not has_function_privilege(
    'anon', 'public.delete_current_account()', 'EXECUTE'
  ),
  'anonymous callers cannot execute account deletion RPC'
);
select ok(
  not has_function_privilege(
    'public', 'public.delete_current_account()', 'EXECUTE'
  ),
  'PUBLIC cannot execute account deletion RPC'
);

-- Prove a caller with no auth.uid() is rejected before any write.
set local role authenticated;
select set_config('request.jwt.claims', '{}', true);
select throws_ok(
  $$select public.delete_current_account()$$,
  '28000', 'AUTH_REQUIRED',
  'missing auth.uid is rejected'
);
reset role;

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, created_at, updated_at
)
values (
  '60000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'delete-me@example.test', '', now(), now()
);

insert into public.rooms (
  id, host_id, category, max_rounds, max_players, round_duration,
  current_round, room_code, status, game_mode
)
values
  (
    '70000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'animals', 3, 4, 60, 0, '960001', 'waiting', 'online'
  ),
  (
    '70000000-0000-4000-8000-000000000002',
    '80000000-0000-4000-8000-000000000003',
    'animals', 3, 4, 60, 0, '960002', 'waiting', 'online'
  );

insert into public.players (
  id, room_id, user_id, username, score, is_host, is_online, created_at
)
values
  (
    '80000000-0000-4000-8000-000000000001',
    '70000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000001',
    'Delete Me', 0, true, true, '2026-01-01'
  ),
  (
    '80000000-0000-4000-8000-000000000002',
    '70000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000002',
    'Remaining Host', 0, false, true, '2026-01-02'
  ),
  (
    '80000000-0000-4000-8000-000000000003',
    '70000000-0000-4000-8000-000000000002',
    '60000000-0000-4000-8000-000000000001',
    'Delete Me Again', 0, true, true, '2026-01-01'
  );

insert into public.rounds (
  id, room_id, imposter_player_id, character_id, round_number,
  phase, phase_end_time, imposter_revealed
)
values (
  '90000000-0000-4000-8000-000000000001',
  '70000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000001',
  (select id from public.characters limit 1),
  1, 'results', now(), true
);

insert into public.hints (id, round_id, player_id, content)
values (
  '91000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000001',
  'A valid hint'
);

insert into public.messages (id, room_id, player_id, content, round_id)
values (
  '92000000-0000-4000-8000-000000000001',
  '70000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000001',
  'A valid message',
  '90000000-0000-4000-8000-000000000001'
);

insert into public.votes (id, round_id, voter_player_id, voted_player_id)
values (
  '93000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000002',
  '80000000-0000-4000-8000-000000000001'
);

insert into public.player_mutes (room_id, muter_player_id, muted_player_id)
values (
  '70000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000002',
  '80000000-0000-4000-8000-000000000001'
);

insert into public.message_reports (
  id, message_id, reporter_player_id, reason, status
)
values (
  '94000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000002',
  'A valid report', 'open'
), (
  '94000000-0000-4000-8000-000000000002',
  '92000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000001',
  'A second valid report', 'open'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"60000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub', '60000000-0000-4000-8000-000000000001', true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.delete_current_account()$$,
  'authenticated caller can delete the current UID, including an imposter'
);

reset role;

select is(
  (select count(*) from auth.users
   where id = '60000000-0000-4000-8000-000000000001'),
  0::bigint,
  'current Auth UID is deleted'
);
select is(
  (select count(*) from public.players
   where user_id = '60000000-0000-4000-8000-000000000001'),
  0::bigint,
  'all current UID player memberships are deleted'
);
select is(
  (select host_id from public.rooms
   where id = '70000000-0000-4000-8000-000000000001'),
  '60000000-0000-4000-8000-000000000002'::uuid,
  'remaining online player becomes the room host'
);
select is(
  (select status from public.rooms
   where id = '70000000-0000-4000-8000-000000000002'),
  'finished',
  'room with no remaining online players is finished'
);
select is(
  (select imposter_player_id from public.rounds
   where id = '90000000-0000-4000-8000-000000000001'),
  null::uuid,
  'historical round retains its row with an anonymized imposter reference'
);
select is(
  (select count(*) from public.hints where player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'player hints are deleted by cascade'
);
select is(
  (select count(*) from public.messages where player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'player messages are deleted by cascade'
);
select is(
  (select count(*) from public.message_reports
   where message_id = '92000000-0000-4000-8000-000000000001'
      or reporter_player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'reports linked to deleted player data are deleted by cascade'
);
select is(
  (select count(*) from public.votes
   where voter_player_id = '80000000-0000-4000-8000-000000000001'
      or voted_player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'player votes are deleted by cascade'
);
select is(
  (select count(*) from public.round_participants
   where player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'round memberships are deleted by cascade'
);
select is(
  (select count(*) from public.player_mutes
   where muter_player_id = '80000000-0000-4000-8000-000000000001'
      or muted_player_id = '80000000-0000-4000-8000-000000000001'),
  0::bigint,
  'player mutes are deleted by cascade'
);

select * from finish();
rollback;
