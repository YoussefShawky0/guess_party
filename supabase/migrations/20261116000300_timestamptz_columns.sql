-- Convert every remaining `timestamp without time zone` column in public to
-- `timestamptz`.
--
-- The stored values are UTC wall-clock times: they were written by column
-- defaults / `now()` in Supabase's UTC sessions and by RPCs using
-- `timezone('utc', now())`. `AT TIME ZONE 'UTC'` therefore reinterprets them
-- exactly, independent of the session TimeZone running this migration.
--
-- Affected (verified against the full chain):
--   characters.created_at, hints."timestamp", players.created_at,
--   rooms.created_at, rounds.phase_end_time, rounds.created_at,
--   votes.created_at
--
-- No views, policies or trigger column lists reference these columns; the one
-- dependent index (idx_hints_round) is rebuilt by Postgres automatically.
-- Functions that wrote `timezone('utc', now())` (a `timestamp`) or projected
-- `col AT TIME ZONE 'UTC'` are redefined below with the new semantics.
-- Idempotent: columns already timestamptz are skipped.

do $$
declare
  r record;
begin
  -- Fail fast instead of queueing behind long transactions on live tables.
  set local lock_timeout = '15s';

  for r in
    select c.table_name,
           string_agg(
             format('alter column %I type timestamptz using %I at time zone ''UTC''',
                    c.column_name, c.column_name),
             ', ' order by c.ordinal_position
           ) as alterations
    from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema
     and t.table_name = c.table_name
     and t.table_type = 'BASE TABLE'
    where c.table_schema = 'public'
      and c.data_type = 'timestamp without time zone'
    group by c.table_name
    order by c.table_name
  loop
    execute format('alter table public.%I %s', r.table_name, r.alterations);
  end loop;
end
$$;

-- Redefine timer functions. CREATE OR REPLACE keeps existing ACLs/owners.
CREATE OR REPLACE FUNCTION private.create_round_for_room(p_room_id uuid, p_round_number integer) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_room public.rooms%rowtype;
  v_existing_round_id uuid;
  v_player_count integer;
  v_imposter_id uuid;
  v_character_id uuid;
  v_previous_character_id uuid;
  v_round_id uuid;
  v_reset_used boolean := false;
begin
  perform private.lock_room(p_room_id);

  select r.* into v_room
  from public.rooms r
  where r.id = p_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  select rd.id into v_existing_round_id
  from public.rounds rd
  where rd.room_id = p_room_id
    and rd.round_number = p_round_number;

  if v_existing_round_id is not null then
    return v_existing_round_id;
  end if;

  if v_room.status <> 'active' then
    raise exception using errcode = 'P0001', message = 'ROOM_NOT_ACTIVE';
  end if;

  if p_round_number <> coalesce(v_room.current_round, 0) + 1 then
    raise exception using
      errcode = 'P0001',
      message = 'UNEXPECTED_ROUND_NUMBER',
      detail = format('Expected %s, received %s.', coalesce(v_room.current_round, 0) + 1, p_round_number);
  end if;

  if p_round_number < 1 or p_round_number > v_room.max_rounds then
    raise exception using errcode = '22023', message = 'ROUND_NUMBER_OUT_OF_RANGE';
  end if;

  select count(*)
    into v_player_count
  from public.players p
  where p.room_id = p_room_id
    and (v_room.game_mode = 'local' or p.is_online is true);

  if v_player_count < 4 then
    raise exception using
      errcode = 'P0001',
      message = 'NOT_ENOUGH_PLAYERS',
      detail = 'At least 4 eligible players are required.';
  end if;

  select p.id
    into v_imposter_id
  from public.players p
  where p.room_id = p_room_id
    and (v_room.game_mode = 'local' or p.is_online is true)
  order by random()
  limit 1;

  select rd.character_id
    into v_previous_character_id
  from public.rounds rd
  where rd.room_id = p_room_id
  order by rd.round_number desc
  limit 1;

  select c.id
    into v_character_id
  from public.characters c
  where c.category = v_room.category
    and c.is_active is true
    and not exists (
      select 1
      from jsonb_array_elements_text(coalesce(v_room.used_character_ids, '[]'::jsonb)) used(value)
      where used.value::uuid = c.id
    )
  order by random()
  limit 1;

  if v_character_id is null then
    v_reset_used := true;

    select c.id
      into v_character_id
    from public.characters c
    where c.category = v_room.category
      and c.is_active is true
      and (v_previous_character_id is null or c.id <> v_previous_character_id)
    order by random()
    limit 1;

    if v_character_id is null then
      select c.id
        into v_character_id
      from public.characters c
      where c.category = v_room.category
        and c.is_active is true
      order by random()
      limit 1;
    end if;
  end if;

  if v_character_id is null then
    raise exception using errcode = 'P0001', message = 'NO_CHARACTER_AVAILABLE';
  end if;

  insert into public.rounds(
    room_id,
    imposter_player_id,
    character_id,
    round_number,
    phase,
    phase_end_time,
    imposter_revealed
  )
  values (
    p_room_id,
    v_imposter_id,
    v_character_id,
    p_round_number,
    'hints',
    now() + make_interval(secs => v_room.round_duration),
    false
  )
  on conflict (room_id, round_number) do nothing
  returning id into v_round_id;

  if v_round_id is null then
    select rd.id into v_round_id
    from public.rounds rd
    where rd.room_id = p_room_id
      and rd.round_number = p_round_number;
    return v_round_id;
  end if;

  update public.rooms r
  set current_round = p_round_number,
      used_character_ids = case
        when v_reset_used then jsonb_build_array(v_character_id)
        else coalesce(r.used_character_ids, '[]'::jsonb) || jsonb_build_array(v_character_id)
      end
  where r.id = p_room_id;

  return v_round_id;
end;
$$;

CREATE OR REPLACE FUNCTION public.advance_to_voting(p_round_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room_id uuid;
  v_phase text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select r.room_id into v_room_id
  from public.rounds r
  where r.id = p_round_id;

  if v_room_id is null then
    raise exception using errcode = 'P0002', message = 'ROUND_NOT_FOUND';
  end if;

  perform private.lock_room(v_room_id);

  select r.phase into v_phase
  from public.rounds r
  where r.id = p_round_id
  for update;

  if not private.is_current_host(v_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  if v_phase in ('voting', 'results') then
    return;
  end if;

  if v_phase <> 'hints' then
    raise exception using errcode = 'P0001', message = 'WRONG_PHASE';
  end if;

  update public.rounds r
  set phase = 'voting',
      phase_end_time = now() + interval '300 seconds'
  where r.id = p_round_id;
end;
$$;

CREATE OR REPLACE FUNCTION public.create_first_round() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
declare
  v_player_count integer;
  v_imposter_id uuid;
  v_character_id uuid;
  v_previous_character_id uuid;
  v_round_id uuid;
  v_reset_used boolean := false;
begin
  if new.status = 'active'
     and coalesce(new.current_round, 0) = 0
     and old.status is distinct from 'active' then

    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(new.id::text, 0)
    );

    select count(*)
      into v_player_count
    from public.players p
    where p.room_id = new.id
      and (new.game_mode = 'local' or p.is_online is true);

    if v_player_count < 4 then
      raise exception using
        errcode = 'P0001',
        message = 'NOT_ENOUGH_PLAYERS',
        detail = 'At least 4 eligible players are required.';
    end if;

    select p.id
      into v_imposter_id
    from public.players p
    where p.room_id = new.id
      and (new.game_mode = 'local' or p.is_online is true)
    order by random()
    limit 1;

    select r.character_id
      into v_previous_character_id
    from public.rounds r
    where r.room_id = new.id
    order by r.round_number desc
    limit 1;

    select c.id
      into v_character_id
    from public.characters c
    where c.category = new.category
      and c.is_active is true
      and not exists (
        select 1
        from jsonb_array_elements_text(coalesce(new.used_character_ids, '[]'::jsonb)) used(value)
        where used.value::uuid = c.id
      )
    order by random()
    limit 1;

    if v_character_id is null then
      v_reset_used := true;
      select c.id
        into v_character_id
      from public.characters c
      where c.category = new.category
        and c.is_active is true
        and (v_previous_character_id is null or c.id <> v_previous_character_id)
      order by random()
      limit 1;

      if v_character_id is null then
        select c.id
          into v_character_id
        from public.characters c
        where c.category = new.category
          and c.is_active is true
        order by random()
        limit 1;
      end if;
    end if;

    if v_character_id is null then
      raise exception using
        errcode = 'P0001',
        message = 'NO_CHARACTER_AVAILABLE';
    end if;

    insert into public.rounds(
      room_id,
      imposter_player_id,
      character_id,
      round_number,
      phase,
      phase_end_time,
      imposter_revealed
    )
    values (
      new.id,
      v_imposter_id,
      v_character_id,
      1,
      'hints',
      now() + make_interval(secs => new.round_duration),
      false
    )
    on conflict (room_id, round_number) do nothing
    returning id into v_round_id;

    if v_round_id is not null then
      update public.rooms r
      set current_round = 1,
          used_character_ids = case
            when v_reset_used then jsonb_build_array(v_character_id)
            else coalesce(r.used_character_ids, '[]'::jsonb) || jsonb_build_array(v_character_id)
          end
      where r.id = new.id;
    end if;
  end if;

  return new;
end;
$$;

CREATE OR REPLACE FUNCTION public.extend_local_role_reveal(p_round_id uuid, p_seconds integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room_id uuid;
  v_mode text;
  v_phase text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if p_seconds < 5 or p_seconds > 300 then
    raise exception using errcode = '22023', message = 'INVALID_EXTENSION_SECONDS';
  end if;

  select r.room_id, rm.game_mode, r.phase
    into v_room_id, v_mode, v_phase
  from public.rounds r
  join public.rooms rm on rm.id = r.room_id
  where r.id = p_round_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROUND_NOT_FOUND';
  end if;

  perform private.lock_room(v_room_id);

  if v_mode <> 'local' then
    raise exception using errcode = '42501', message = 'LOCAL_ROOM_REQUIRED';
  end if;

  if not private.is_current_host(v_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  if v_phase <> 'hints' then
    raise exception using errcode = 'P0001', message = 'HINTS_PHASE_REQUIRED';
  end if;

  update public.rounds r
  set phase_end_time = least(
    greatest(r.phase_end_time, now()) + make_interval(secs => p_seconds),
    now() + interval '900 seconds'
  )
  where r.id = p_round_id;
end;
$$;

CREATE OR REPLACE FUNCTION public.finalize_voting(p_round_id uuid, p_reason text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_round public.rounds%rowtype;
  v_room public.rooms%rowtype;
  v_required_count integer;
  v_submitted_count integer;
  v_top_votes integer := 0;
  v_top_target_count integer := 0;
  v_imposter_votes integer := 0;
  v_imposter_caught boolean := false;
  v_scores jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if p_reason not in ('all_votes', 'timer', 'host_skip') then
    raise exception using errcode = '22023', message = 'INVALID_FINALIZE_REASON';
  end if;

  select r.* into v_round
  from public.rounds r
  where r.id = p_round_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROUND_NOT_FOUND';
  end if;

  perform private.lock_room(v_round.room_id);

  select r.* into v_round
  from public.rounds r
  where r.id = p_round_id
  for update;

  select rm.* into v_room
  from public.rooms rm
  where rm.id = v_round.room_id;

  if not private.is_current_host(v_room.id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  if v_round.scores_finalized_at is not null then
    select coalesce(jsonb_object_agg(p.id::text, coalesce(p.score, 0)), '{}'::jsonb)
      into v_scores
    from public.round_participants rp
    join public.players p on p.id = rp.player_id
    where rp.round_id = p_round_id;

    return jsonb_build_object(
      'round_id', p_round_id,
      'phase', v_round.phase,
      'scores', v_scores,
      'already_finalized', true
    );
  end if;

  if v_round.phase <> 'voting' then
    raise exception using errcode = 'P0001', message = 'VOTING_PHASE_REQUIRED';
  end if;

  if v_room.game_mode = 'online' then
    select count(*) into v_required_count
    from public.round_participants rp
    join public.players p on p.id = rp.player_id
    where rp.round_id = p_round_id
      and p.is_online is true;

    select count(*) into v_submitted_count
    from public.votes v
    join public.players p on p.id = v.voter_player_id
    where v.round_id = p_round_id
      and p.is_online is true
      and exists (
        select 1
        from public.round_participants rp
        where rp.round_id = p_round_id
          and rp.player_id = v.voter_player_id
      );
  else
    select count(*) into v_required_count
    from public.round_participants rp
    where rp.round_id = p_round_id;

    select count(*) into v_submitted_count
    from public.votes v
    where v.round_id = p_round_id
      and exists (
        select 1
        from public.round_participants rp
        where rp.round_id = p_round_id
          and rp.player_id = v.voter_player_id
      );
  end if;

  if p_reason = 'all_votes' and v_submitted_count < v_required_count then
    raise exception using errcode = 'P0001', message = 'VOTES_INCOMPLETE';
  end if;

  select coalesce(max(c.vote_count), 0)
    into v_top_votes
  from (
    select v.voted_player_id, count(*)::integer as vote_count
    from public.votes v
    where v.round_id = p_round_id
    group by v.voted_player_id
  ) c;

  select count(*)
    into v_top_target_count
  from (
    select v.voted_player_id, count(*)::integer as vote_count
    from public.votes v
    where v.round_id = p_round_id
    group by v.voted_player_id
  ) c
  where c.vote_count = v_top_votes
    and v_top_votes > 0;

  select count(*)::integer
    into v_imposter_votes
  from public.votes v
  where v.round_id = p_round_id
    and v.voted_player_id = v_round.imposter_player_id;

  v_imposter_caught :=
    v_top_votes > 0
    and v_top_target_count = 1
    and v_imposter_votes = v_top_votes;

  update public.players p
  set score = coalesce(p.score, 0)
    + case
        when exists (
          select 1
          from public.votes v
          where v.round_id = p_round_id
            and v.voter_player_id = p.id
            and v.voted_player_id = v_round.imposter_player_id
        ) then 10
        else 0
      end
    + case
        when p.id = v_round.imposter_player_id
         and not v_imposter_caught then 20
        else 0
      end
  where exists (
    select 1
    from public.round_participants rp
    where rp.round_id = p_round_id
      and rp.player_id = p.id
  );

  update public.rounds r
  set phase = 'results',
      phase_end_time = now() + interval '30 seconds',
      imposter_revealed = true,
      scores_finalized_at = now()
  where r.id = p_round_id
  returning * into v_round;

  select coalesce(jsonb_object_agg(p.id::text, coalesce(p.score, 0)), '{}'::jsonb)
    into v_scores
  from public.round_participants rp
  join public.players p on p.id = rp.player_id
  where rp.round_id = p_round_id;

  return jsonb_build_object(
    'round_id', p_round_id,
    'phase', 'results',
    'scores', v_scores,
    'already_finalized', false
  );
end;
$$;

CREATE OR REPLACE FUNCTION public.get_round_for_player(p_round_id uuid) RETURNS TABLE(id uuid, room_id uuid, character_id uuid, round_number integer, phase text, phase_end_time timestamp with time zone, imposter_revealed boolean, imposter_player_id uuid, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with caller_round as (
    select
      r.*,
      rm.game_mode,
      (
        select p.id
        from public.round_participants rp
        join public.players p on p.id = rp.player_id
        where rp.round_id = r.id
          and p.user_id = (select auth.uid())
        order by p.created_at asc, p.id asc
        limit 1
      ) as caller_player_id
    from public.rounds r
    join public.rooms rm on rm.id = r.room_id
    where r.id = p_round_id
      and (select auth.uid()) is not null
      and exists (
        select 1
        from public.round_participants rp
        join public.players p on p.id = rp.player_id
        where rp.round_id = r.id
          and p.user_id = (select auth.uid())
      )
  )
  select
    cr.id,
    cr.room_id,
    cr.character_id,
    cr.round_number,
    cr.phase,
    cr.phase_end_time,
    (coalesce(cr.imposter_revealed, false) or cr.phase = 'results'),
    case
      when cr.phase = 'results' then cr.imposter_player_id
      when cr.game_mode = 'local'
       and private.is_current_host(cr.room_id, (select auth.uid()))
        then cr.imposter_player_id
      when cr.game_mode = 'online'
       and cr.caller_player_id = cr.imposter_player_id
        then cr.imposter_player_id
      else null
    end,
    cr.created_at
  from caller_round cr;
$$;

CREATE OR REPLACE FUNCTION public.get_round_for_player_v2(p_round_id uuid) RETURNS TABLE(id uuid, room_id uuid, character_id uuid, round_number integer, phase text, phase_end_time timestamp with time zone, imposter_revealed boolean, imposter_player_id uuid, created_at timestamp with time zone, participant_ids uuid[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  with caller as (
    select auth.uid() as user_id
  ),
  visible_round as (
    select
      r.*,
      rm.game_mode,
      (
        select p.id
        from public.round_participants rp
        join public.players p on p.id = rp.player_id
        cross join caller c
        where rp.round_id = r.id
          and p.user_id = c.user_id
        order by p.created_at asc, p.id asc
        limit 1
      ) as caller_player_id,
      (
        select array_agg(rp.player_id order by rp.created_at asc, rp.player_id asc)
        from public.round_participants rp
        where rp.round_id = r.id
      ) as participant_ids
    from public.rounds r
    join public.rooms rm on rm.id = r.room_id
    cross join caller c
    where r.id = p_round_id
      and c.user_id is not null
      and exists (
        select 1
        from public.round_participants rp
        join public.players p on p.id = rp.player_id
        where rp.round_id = r.id
          and p.user_id = c.user_id
      )
  )
  select
    vr.id,
    vr.room_id,
    case
      when vr.phase = 'results' then vr.character_id
      when vr.game_mode = 'online'
       and vr.caller_player_id <> vr.imposter_player_id then vr.character_id
      else null
    end as character_id,
    vr.round_number,
    vr.phase,
    vr.phase_end_time as phase_end_time,
    (coalesce(vr.imposter_revealed, false) or vr.phase = 'results') as imposter_revealed,
    case
      when vr.phase = 'results' then vr.imposter_player_id
      when vr.game_mode = 'online'
       and vr.caller_player_id = vr.imposter_player_id then vr.imposter_player_id
      else null
    end as imposter_player_id,
    vr.created_at as created_at,
    coalesce(vr.participant_ids, array[]::uuid[]) as participant_ids
  from visible_round vr;
$$;

