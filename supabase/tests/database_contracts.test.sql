begin;
select plan(36);

select has_table('public', 'rooms', 'rooms table exists');
select has_table('public', 'players', 'players table exists');
select has_table('public', 'rounds', 'rounds table exists');
select has_table('public', 'hints', 'hints table exists');
select has_table('public', 'votes', 'votes table exists');
select has_table('public', 'messages', 'messages table exists');
select has_table('public', 'characters', 'characters table exists');
select has_table('public', 'categories', 'categories table exists');
select has_table('public', 'round_revisions', 'safe round revision table exists');
select has_table('public', 'round_participants', 'round participant snapshot table exists');

select has_function('public', 'create_room', 'create_room RPC exists');
select has_function('public', 'find_joinable_room', 'find_joinable_room RPC exists');
select has_function('public', 'join_room', 'join_room RPC exists');
select has_function('public', 'start_game', 'start_game RPC exists');
select has_function('public', 'get_current_round_id', 'get_current_round_id RPC exists');
select has_function('public', 'get_round_for_player_v2', 'secure round snapshot RPC exists');
select has_function('public', 'get_local_role_reveal_bundle', 'shared-device reveal RPC exists');
select has_function('public', 'get_vote_state', 'vote state RPC exists');
select has_function('public', 'advance_to_voting', 'advance_to_voting RPC exists');
select has_function('public', 'finalize_voting', 'finalize_voting RPC exists');
select has_function('public', 'create_next_round', 'create_next_round RPC exists');
select has_function('public', 'finish_game', 'finish_game RPC exists');
select has_function('public', 'extend_local_role_reveal', 'shared-device timer RPC exists');
select has_function('public', 'mark_stale_players_offline', 'presence cleanup RPC exists');
select has_function('public', 'reconcile_room_after_presence_change', 'room reconciliation RPC exists');
select has_function('public', 'get_server_time', 'server time RPC exists');
select has_function(
  'public', 'mark_stale_players_offline', array['integer'],
  'global stale-player compatibility overload exists'
);
select has_function(
  'public', 'mark_stale_players_offline', array['uuid', 'integer'],
  'room-scoped stale-player overload exists'
);

select is(
  (select count(*)::bigint from pg_policies
   where schemaname = 'public' and tablename = 'rounds'
     and policyname = 'Room members can view rounds legacy'),
  0::bigint,
  'legacy broad round read policy is absent'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'rounds'
      and policyname = 'Round participants can view completed rounds'
      and cmd = 'SELECT'
      and qual like '%can_view_completed_round%'
  ),
  'raw round reads are restricted to completed rounds'
);
select is(
  (select count(*)::bigint from pg_policies
   where schemaname = 'public' and tablename = 'votes'
     and policyname = 'Anyone can view votes'),
  0::bigint,
  'broad vote read policy is absent'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'votes'
      and policyname = 'Participants can view authorized votes'
      and cmd = 'SELECT'
      and qual like '%can_view_vote_row%'
  ),
  'raw vote reads preserve own-vote and results visibility'
);

select ok(
  has_function_privilege('authenticated', 'public.create_room(uuid,text,integer,integer,integer,text,text,text[])', 'EXECUTE'),
  'authenticated can execute create_room'
);
select ok(
  has_function_privilege('anon', 'public.get_server_time()', 'EXECUTE'),
  'anon can execute get_server_time'
);
select ok(
  not has_function_privilege('anon', 'public.get_round_for_player_v2(uuid)', 'EXECUTE'),
  'anon cannot execute secure round snapshot RPC'
);
select is(
  (
    select array_agg(c.relname order by c.relname)
    from pg_publication_tables ppt
    join pg_class c on c.relname = ppt.tablename
    join pg_namespace n on n.oid = c.relnamespace
      and n.nspname = ppt.schemaname
    where ppt.pubname = 'supabase_realtime'
      and ppt.schemaname = 'public'
  ),
  array[
    'characters', 'hints', 'messages', 'players', 'rooms',
    'round_revisions', 'rounds', 'votes'
  ]::name[],
  'Realtime publication membership matches production exactly'
);

select * from finish();
rollback;
