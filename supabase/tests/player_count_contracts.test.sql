begin;

select plan(10);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, created_at, updated_at
)
values (
  'a0000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'player-count@example.test',
  '',
  now(),
  now()
);

select ok(
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'rooms'
      and c.conname = 'rooms_max_players_check'
      and pg_get_constraintdef(c.oid, true) =
        'CHECK (max_players >= 4 AND max_players <= 10)'
  ),
  'rooms max_players constraint enforces the inclusive 4-10 range'
);

select throws_ok(
  $$insert into public.rooms (
    id, host_id, category, max_rounds, max_players, round_duration, room_code
  ) values (
    'a1000000-0000-4000-8000-000000000003',
    'a0000000-0000-4000-8000-000000000001',
    'animals', 3, 3, 60, '930003'
  )$$,
  '23514',
  null,
  'table constraint rejects max_players below 4'
);

select throws_ok(
  $$insert into public.rooms (
    id, host_id, category, max_rounds, max_players, round_duration, room_code
  ) values (
    'a1000000-0000-4000-8000-000000000011',
    'a0000000-0000-4000-8000-000000000001',
    'animals', 3, 11, 60, '930011'
  )$$,
  '23514',
  null,
  'table constraint rejects max_players above 10'
);

select lives_ok(
  $$insert into public.rooms (
    id, host_id, category, max_rounds, max_players, round_duration, room_code
  ) values (
    'a1000000-0000-4000-8000-000000000004',
    'a0000000-0000-4000-8000-000000000001',
    'animals', 3, 4, 60, '930004'
  )$$,
  'table constraint accepts lower boundary 4'
);

select lives_ok(
  $$insert into public.rooms (
    id, host_id, category, max_rounds, max_players, round_duration, room_code
  ) values (
    'a1000000-0000-4000-8000-000000000010',
    'a0000000-0000-4000-8000-000000000001',
    'animals', 3, 10, 60, '930010'
  )$$,
  'table constraint accepts upper boundary 10'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"a0000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  'a0000000-0000-4000-8000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.create_room(
    'a2000000-0000-4000-8000-000000000003',
    'animals', 3, 3, 60, 'online', 'Count Host', array[]::text[]
  )$$,
  '22023',
  'INVALID_ROOM_SETTINGS',
  'create_room rejects max_players below 4'
);

select throws_ok(
  $$select public.create_room(
    'a2000000-0000-4000-8000-000000000011',
    'animals', 3, 11, 60, 'online', 'Count Host', array[]::text[]
  )$$,
  '22023',
  'INVALID_ROOM_SETTINGS',
  'create_room rejects max_players above 10'
);

select lives_ok(
  $$select public.create_room(
    'a2000000-0000-4000-8000-000000000004',
    'animals', 3, 4, 60, 'online', 'Count Four', array[]::text[]
  )$$,
  'create_room accepts lower boundary 4'
);

select lives_ok(
  $$select public.create_room(
    'a2000000-0000-4000-8000-000000000010',
    'animals', 3, 10, 60, 'online', 'Count Ten', array[]::text[]
  )$$,
  'create_room accepts upper boundary 10'
);

select lives_ok(
  $$select public.create_room(
    'a2000000-0000-4000-8000-000000000007',
    'animals', 3, 7, 60, 'online', 'Count Seven', array[]::text[]
  )$$,
  'create_room accepts intermediate custom value 7'
);

select * from finish();
rollback;
