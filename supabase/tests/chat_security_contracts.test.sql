begin;

select plan(33);

select has_table('public', 'player_mutes', 'player mute table exists');
select has_table('public', 'message_reports', 'message report table exists');
select has_function('public', 'send_chat_message', 'send chat RPC exists');
select has_function('public', 'list_chat_messages', 'paginated chat RPC exists');
select has_function('public', 'set_player_muted', 'mute RPC exists');
select has_function('public', 'report_chat_message', 'report RPC exists');
select ok(
  not has_table_privilege('authenticated', 'public.messages', 'INSERT'),
  'authenticated clients cannot insert messages directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.message_reports', 'INSERT'),
  'authenticated clients cannot insert message reports directly'
);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('12000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p8-host@example.test', '', now(), now()),
  ('12000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p8-two@example.test', '', now(), now()),
  ('12000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p8-three@example.test', '', now(), now()),
  ('12000000-0000-4000-8000-000000000099', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'p8-outsider@example.test', '', now(), now());

insert into public.rooms (id, host_id, category, max_rounds, max_players, round_duration, current_round, room_code, status, game_mode)
values ('22000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000001', 'animals', 3, 6, 60, 1, '980001', 'waiting', 'online');

insert into public.players (id, room_id, user_id, username, is_host, is_online, created_at)
values
  ('32000000-0000-4000-8000-000000000001', '22000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000001', 'Host', true, true, '2026-01-01'),
  ('32000000-0000-4000-8000-000000000002', '22000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000002', 'Player Two', false, true, '2026-01-02'),
  ('32000000-0000-4000-8000-000000000003', '22000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000003', 'Player Three', false, true, '2026-01-03');

insert into public.rounds (id, room_id, imposter_player_id, character_id, round_number, phase, phase_end_time)
values ('42000000-0000-4000-8000-000000000001', '22000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000002', 'a5e643a0-c555-43cd-b4b0-77c0825a6f91', 1, 'hints', '2099-01-01');

update public.rooms
set status = 'active'
where id = '22000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (public.send_chat_message(
    '22000000-0000-4000-8000-000000000001',
    '42000000-0000-4000-8000-000000000001',
    ' hello from host '
  )->>'player_id')::uuid,
  '32000000-0000-4000-8000-000000000001'::uuid,
  'send RPC derives sender from auth.uid membership'
);
select is((select count(*) from public.messages), 1::bigint, 'room member can select own visible chat message');

select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000099","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000099', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is((select count(*) from public.messages), 0::bigint, 'non-member cannot read raw room messages');
select throws_ok(
  $$select count(*) from public.list_chat_messages('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001')$$,
  '42501',
  'ROOM_PARTICIPANT_REQUIRED',
  'non-member cannot page chat history'
);
select throws_ok(
  $$select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'outsider')$$,
  '42501',
  'ROOM_PARTICIPANT_REQUIRED',
  'non-member cannot send chat'
);

select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select throws_ok(
  $$insert into public.messages (room_id, round_id, player_id, content)
    values ('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'direct')$$,
  '42501',
  null,
  'direct message insert is blocked even for room members'
);

select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok($$select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two one')$$, 'second player can send');
select is(
  (select count(*) from public.messages where player_id = '32000000-0000-4000-8000-000000000001' and content = 'player two one'),
  0::bigint,
  'caller cannot impersonate another player through send RPC'
);

select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two two');
select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two three');
select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two four');
select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two five');
select throws_ok(
  $$select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two six')$$,
  'P0001',
  'CHAT_RATE_LIMITED',
  'sixth accepted message inside ten seconds is rejected'
);
reset role;
update public.messages
set created_at = now() - interval '11 seconds'
where player_id = '32000000-0000-4000-8000-000000000002';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok(
  $$select public.send_chat_message('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', 'player two later')$$,
  'later message outside the rate window is accepted'
);
reset role;

insert into public.messages (id, room_id, round_id, player_id, content, created_at)
values
  ('52000000-0000-4000-8000-000000000001', '22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'tie one', '2026-02-01 00:00:00+00'),
  ('52000000-0000-4000-8000-000000000002', '22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'tie two', '2026-02-01 00:00:00+00'),
  ('52000000-0000-4000-8000-000000000003', '22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'tie three', '2026-02-01 00:00:00+00'),
  ('52000000-0000-4000-8000-000000000004', '22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'tie four', '2026-02-01 00:00:00+00');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
create temp table p8_first_page as
  select * from public.list_chat_messages(
    '22000000-0000-4000-8000-000000000001',
    '42000000-0000-4000-8000-000000000001',
    null,
    null,
    2
  );
create temp table p8_second_page as
  select * from public.list_chat_messages(
    '22000000-0000-4000-8000-000000000001',
    '42000000-0000-4000-8000-000000000001',
    (select created_at from p8_first_page order by created_at asc, id asc limit 1),
    (select id from p8_first_page order by created_at asc, id asc limit 1),
    2
  );
select is((select count(*) from p8_first_page), 2::bigint, 'first cursor page is bounded');
select is((select count(*) from p8_second_page), 2::bigint, 'second cursor page continues after the cursor');
select is(
  (select count(*) from p8_first_page f join p8_second_page s using (id)),
  0::bigint,
  'cursor pagination does not duplicate equal-timestamp rows'
);

select lives_ok($$select public.set_player_muted('22000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000002', true)$$, 'mute operation succeeds');
select lives_ok($$select public.set_player_muted('22000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000002', true)$$, 'duplicate mute operation is deterministic');
select is(
  (select count(*) from public.player_mutes where muter_player_id = '32000000-0000-4000-8000-000000000001' and muted_player_id = '32000000-0000-4000-8000-000000000002'),
  1::bigint,
  'duplicate mute stores one row'
);
select is(
  (select count(*) from public.list_chat_messages('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001') where player_id = '32000000-0000-4000-8000-000000000002'),
  0::bigint,
  'muted player messages are hidden for the muting viewer'
);
select throws_ok(
  $$select public.set_player_muted('22000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', true)$$,
  '23514',
  null,
  'self mute is rejected by database constraint'
);

select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select isnt(
  (select count(*) from public.list_chat_messages('22000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001') where player_id = '32000000-0000-4000-8000-000000000001'),
  0::bigint,
  'mute is viewer-specific and does not hide the muting player from others'
);

select set_config('request.jwt.claims', '{"sub":"12000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '12000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
create temp table p8_report_ids as
select
  public.report_chat_message('52000000-0000-4000-8000-000000000001', 'not nice') as first_id,
  public.report_chat_message('52000000-0000-4000-8000-000000000001', 'not nice again') as second_id;
select is((select first_id = second_id from p8_report_ids), true, 'duplicate report returns the existing report id');
select throws_ok(
  $$insert into public.message_reports (message_id, reporter_player_id, reason)
    values ('52000000-0000-4000-8000-000000000002', '32000000-0000-4000-8000-000000000001', 'impersonated')$$,
  '42501',
  null,
  'direct report insert cannot impersonate another reporter'
);
select throws_ok($$select count(*) from public.message_reports$$, '42501', null, 'authenticated clients cannot read moderation reports directly');
select throws_ok($$update public.message_reports set status = 'reviewed'$$, '42501', null, 'authenticated clients cannot moderate report status');
select throws_ok($$select public.report_chat_message('52000000-0000-4000-8000-000000000001', '')$$, '22023', 'INVALID_REPORT_REASON', 'blank report reason is rejected');
select throws_ok(
  $$select count(*) from public.list_chat_messages(
    '22000000-0000-4000-8000-000000000001',
    '42000000-0000-4000-8000-000000000001',
    now(),
    null,
    30
  )$$,
  '22023',
  'INVALID_CHAT_CURSOR',
  'pagination cursor requires both fields together'
);

select * from finish();
rollback;
