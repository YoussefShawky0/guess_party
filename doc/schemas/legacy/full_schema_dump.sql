--
-- PostgreSQL database dump
--

\restrict gkLm8rrpwAAujFp7P0JynmzYV6ZjHcgs2DxnCnYD93SKRzpSbAThnK0q8T60WXV

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA private;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: bump_revision_from_child(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.bump_revision_from_child() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform private.bump_round_revision(coalesce(new.round_id, old.round_id));
  return coalesce(new, old);
end;
$$;


--
-- Name: bump_round_revision(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.bump_round_revision(p_round_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_room_id uuid;
begin
  select r.room_id
    into v_room_id
  from public.rounds r
  where r.id = p_round_id;

  if v_room_id is null then
    return;
  end if;

  insert into public.round_revisions(round_id, room_id, revision, updated_at)
  values (p_round_id, v_room_id, 1, now())
  on conflict (round_id) do update
    set revision = public.round_revisions.revision + 1,
        room_id = excluded.room_id,
        updated_at = excluded.updated_at;
end;
$$;


--
-- Name: capture_round_state(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.capture_round_state() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_mode text;
begin
  if tg_op = 'INSERT' then
    select r.game_mode into v_mode
    from public.rooms r
    where r.id = new.room_id;

    insert into public.round_participants(round_id, player_id)
    select new.id, p.id
    from public.players p
    where p.room_id = new.room_id
      and (v_mode = 'local' or p.is_online is true)
    on conflict (round_id, player_id) do nothing;
  end if;

  perform private.bump_round_revision(new.id);
  return new;
end;
$$;


--
-- Name: create_round_for_room(uuid, integer); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.create_round_for_room(p_room_id uuid, p_round_number integer) RETURNS uuid
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
    timezone('utc', now()) + make_interval(secs => v_room.round_duration),
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


--
-- Name: is_current_host(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.is_current_host(p_room_id uuid, p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select p_user_id is not null
     and exists (
       select 1
       from public.players p
       join public.rooms r on r.id = p.room_id
       where p.room_id = p_room_id
         and p.user_id = p_user_id
         and p.is_host is true
         and (r.game_mode = 'local' or p.is_online is true)
     );
$$;


--
-- Name: is_room_member(uuid, uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.is_room_member(p_room_id uuid, p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select p_user_id is not null
     and exists (
       select 1
       from public.players p
       where p.room_id = p_room_id
         and p.user_id = p_user_id
     );
$$;


--
-- Name: lock_room(uuid); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.lock_room(p_room_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if p_room_id is null then
    raise exception using errcode = '22004', message = 'ROOM_ID_REQUIRED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_room_id::text, 0)
  );

  perform 1
  from public.rooms r
  where r.id = p_room_id
  for update;
end;
$$;


--
-- Name: prevent_room_mode_change(); Type: FUNCTION; Schema: private; Owner: -
--

CREATE FUNCTION private.prevent_room_mode_change() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  if new.game_mode is distinct from old.game_mode then
    raise exception using errcode = '23514', message = 'ROOM_MODE_IMMUTABLE';
  end if;
  return new;
end;
$$;


--
-- Name: advance_to_voting(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.advance_to_voting(p_round_id uuid) RETURNS void
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
      phase_end_time = timezone('utc', now()) + interval '300 seconds'
  where r.id = p_round_id;
end;
$$;


--
-- Name: create_first_round(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_first_round() RETURNS trigger
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
      timezone('utc', now()) + make_interval(secs => new.round_duration),
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


--
-- Name: create_next_round(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_next_round(p_room_id uuid, p_expected_round_number integer) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room public.rooms%rowtype;
  v_existing_round_id uuid;
  v_previous public.rounds%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform private.lock_room(p_room_id);

  select r.* into v_room
  from public.rooms r
  where r.id = p_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if not private.is_current_host(p_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  select rd.id into v_existing_round_id
  from public.rounds rd
  where rd.room_id = p_room_id
    and rd.round_number = p_expected_round_number;

  if v_existing_round_id is not null then
    return v_existing_round_id;
  end if;

  if p_expected_round_number <> coalesce(v_room.current_round, 0) + 1 then
    raise exception using errcode = 'P0001', message = 'UNEXPECTED_ROUND_NUMBER';
  end if;

  select rd.* into v_previous
  from public.rounds rd
  where rd.room_id = p_room_id
    and rd.round_number = v_room.current_round;

  if not found
     or v_previous.phase <> 'results'
     or v_previous.scores_finalized_at is null then
    raise exception using errcode = 'P0001', message = 'PREVIOUS_ROUND_NOT_FINALIZED';
  end if;

  return private.create_round_for_room(p_room_id, p_expected_round_number);
end;
$$;


--
-- Name: create_room(uuid, text, integer, integer, integer, text, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_room(p_request_id uuid, p_category text, p_max_rounds integer, p_max_players integer, p_round_duration integer, p_game_mode text, p_host_username text, p_local_names text[] DEFAULT ARRAY[]::text[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room public.rooms%rowtype;
  v_host_username text := btrim(p_host_username);
  v_local_names text[] := coalesce(p_local_names, array[]::text[]);
  v_total_names integer;
  v_room_code text;
  v_attempt integer;
  v_players jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if p_request_id is null then
    raise exception using errcode = '22004', message = 'REQUEST_ID_REQUIRED';
  end if;

  if p_game_mode not in ('online', 'local') then
    raise exception using errcode = '22023', message = 'INVALID_GAME_MODE';
  end if;

  if p_max_rounds < 1 or p_max_rounds > 10
     or p_max_players < 4 or p_max_players > 10
     or p_round_duration < 30 or p_round_duration > 900 then
    raise exception using errcode = '22023', message = 'INVALID_ROOM_SETTINGS';
  end if;

  if char_length(v_host_username) < 2 or char_length(v_host_username) > 20 then
    raise exception using errcode = '22023', message = 'INVALID_USERNAME';
  end if;

  if not exists (
    select 1
    from public.categories c
    where c.key = p_category
      and c.is_active is true
  ) then
    raise exception using errcode = '22023', message = 'INVALID_CATEGORY';
  end if;

  if p_game_mode = 'online' and cardinality(v_local_names) <> 0 then
    raise exception using errcode = '22023', message = 'LOCAL_NAMES_NOT_ALLOWED';
  end if;

  v_total_names := 1 + cardinality(v_local_names);

  if p_game_mode = 'local' then
    if v_total_names < 4 or v_total_names > p_max_players then
      raise exception using errcode = '22023', message = 'INVALID_LOCAL_PLAYER_COUNT';
    end if;

    if exists (
      select 1
      from unnest(v_local_names) n(name)
      where char_length(btrim(n.name)) < 2
         or char_length(btrim(n.name)) > 20
    ) then
      raise exception using errcode = '22023', message = 'INVALID_USERNAME';
    end if;

    if (
      select count(*) <> count(distinct lower(btrim(n.name)))
      from unnest(array_prepend(v_host_username, v_local_names)) n(name)
    ) then
      raise exception using errcode = '23505', message = 'DUPLICATE_LOCAL_USERNAME';
    end if;
  end if;

  perform private.lock_room(p_request_id);

  select r.* into v_room
  from public.rooms r
  where r.id = p_request_id;

  if found then
    if v_room.host_id <> v_user_id then
      raise exception using errcode = '42501', message = 'REQUEST_ID_ALREADY_USED';
    end if;

    select coalesce(jsonb_agg(to_jsonb(p) order by p.created_at asc, p.id asc), '[]'::jsonb)
      into v_players
    from public.players p
    where p.room_id = v_room.id;

    return jsonb_build_object('room', to_jsonb(v_room), 'players', v_players);
  end if;

  for v_attempt in 1..20 loop
    v_room_code := lpad(((floor(random() * 900000) + 100000)::integer)::text, 6, '0');

    insert into public.rooms(
      id,
      host_id,
      category,
      max_rounds,
      max_players,
      round_duration,
      current_round,
      room_code,
      status,
      used_character_ids,
      game_mode
    )
    values (
      p_request_id,
      v_user_id,
      p_category,
      p_max_rounds,
      p_max_players,
      p_round_duration,
      0,
      v_room_code,
      'waiting',
      '[]'::jsonb,
      p_game_mode
    )
    on conflict (room_code) do nothing
    returning * into v_room;

    exit when v_room.id is not null;
  end loop;

  if v_room.id is null then
    raise exception using errcode = 'P0001', message = 'ROOM_CODE_GENERATION_FAILED';
  end if;

  insert into public.players(
    room_id,
    user_id,
    username,
    score,
    is_host,
    is_online,
    last_seen_at
  )
  values (
    v_room.id,
    v_user_id,
    v_host_username,
    0,
    true,
    true,
    now()
  );

  if p_game_mode = 'local' and cardinality(v_local_names) > 0 then
    insert into public.players(
      room_id,
      user_id,
      username,
      score,
      is_host,
      is_online,
      last_seen_at
    )
    select
      v_room.id,
      gen_random_uuid(),
      btrim(n.name),
      0,
      false,
      true,
      now()
    from unnest(v_local_names) with ordinality n(name, ord)
    order by n.ord;
  end if;

  select coalesce(jsonb_agg(to_jsonb(p) order by p.created_at asc, p.id asc), '[]'::jsonb)
    into v_players
  from public.players p
  where p.room_id = v_room.id;

  return jsonb_build_object('room', to_jsonb(v_room), 'players', v_players);
end;
$$;


--
-- Name: enforce_room_capacity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_room_capacity() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_room_status text;
  v_max_players integer;
  v_online_count integer;
begin
  select r.status, r.max_players
    into v_room_status, v_max_players
  from public.rooms r
  where r.id = new.room_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if tg_op = 'INSERT' and v_room_status <> 'waiting' then
    raise exception using errcode = 'P0001', message = 'ROOM_ALREADY_STARTED';
  end if;

  if coalesce(new.is_online, true) then
    select count(*)
      into v_online_count
    from public.players p
    where p.room_id = new.room_id
      and p.is_online is true
      and p.id <> new.id;

    if v_online_count >= v_max_players then
      raise exception using errcode = 'P0001', message = 'ROOM_FULL';
    end if;
  end if;

  return new;
end;
$$;


--
-- Name: extend_local_role_reveal(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extend_local_role_reveal(p_round_id uuid, p_seconds integer) RETURNS void
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
    greatest(r.phase_end_time, timezone('utc', now())) + make_interval(secs => p_seconds),
    timezone('utc', now()) + interval '900 seconds'
  )
  where r.id = p_round_id;
end;
$$;


--
-- Name: finalize_voting(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finalize_voting(p_round_id uuid, p_reason text) RETURNS jsonb
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
      phase_end_time = timezone('utc', now()) + interval '30 seconds',
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


--
-- Name: find_joinable_room(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_joinable_room(p_room_code text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room public.rooms%rowtype;
  v_online_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select r.* into v_room
  from public.rooms r
  where r.room_code = btrim(p_room_code)
    and r.game_mode = 'online';

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  select count(*) into v_online_count
  from public.players p
  where p.room_id = v_room.id
    and p.is_online is true;

  if v_room.status <> 'waiting' then
    raise exception using errcode = 'P0001', message = 'ROOM_ALREADY_STARTED';
  end if;

  if v_online_count >= v_room.max_players then
    raise exception using errcode = 'P0001', message = 'ROOM_FULL';
  end if;

  return jsonb_build_object(
    'room', to_jsonb(v_room),
    'online_count', v_online_count,
    'available_slots', v_room.max_players - v_online_count
  );
end;
$$;


--
-- Name: finish_game(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_game(p_room_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_status text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform private.lock_room(p_room_id);

  select r.status into v_status
  from public.rooms r
  where r.id = p_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if not private.is_current_host(p_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  if v_status = 'finished' then
    return;
  end if;

  update public.rooms r
  set status = 'finished'
  where r.id = p_room_id;
end;
$$;


--
-- Name: get_current_round_id(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_current_round_id(p_room_id uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select rd.id
  from public.rooms rm
  join public.rounds rd
    on rd.room_id = rm.id
   and rd.round_number = rm.current_round
  where rm.id = p_room_id
    and (select auth.uid()) is not null
    and exists (
      select 1
      from public.round_participants rp
      join public.players p on p.id = rp.player_id
      where rp.round_id = rd.id
        and p.user_id = (select auth.uid())
    );
$$;


--
-- Name: get_local_role_reveal_bundle(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_local_role_reveal_bundle(p_round_id uuid) RETURNS TABLE(round_id uuid, character_id uuid, imposter_player_id uuid)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select r.id, r.character_id, r.imposter_player_id
  from public.rounds r
  join public.rooms rm on rm.id = r.room_id
  where r.id = p_round_id
    and (select auth.uid()) is not null
    and rm.game_mode = 'local'
    and private.is_current_host(r.room_id, (select auth.uid()))
    and exists (
      select 1
      from public.round_participants rp
      join public.players p on p.id = rp.player_id
      where rp.round_id = r.id
        and p.user_id = (select auth.uid())
        and p.is_host is true
    );
$$;


--
-- Name: get_round_for_player(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_round_for_player(p_round_id uuid) RETURNS TABLE(id uuid, room_id uuid, character_id uuid, round_number integer, phase text, phase_end_time timestamp with time zone, imposter_revealed boolean, imposter_player_id uuid, created_at timestamp with time zone)
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
    cr.phase_end_time at time zone 'UTC',
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
    cr.created_at at time zone 'UTC'
  from caller_round cr;
$$;


--
-- Name: get_round_for_player_v2(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_round_for_player_v2(p_round_id uuid) RETURNS TABLE(id uuid, room_id uuid, character_id uuid, round_number integer, phase text, phase_end_time timestamp with time zone, imposter_revealed boolean, imposter_player_id uuid, created_at timestamp with time zone, participant_ids uuid[])
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
    vr.phase_end_time at time zone 'UTC' as phase_end_time,
    (coalesce(vr.imposter_revealed, false) or vr.phase = 'results') as imposter_revealed,
    case
      when vr.phase = 'results' then vr.imposter_player_id
      when vr.game_mode = 'online'
       and vr.caller_player_id = vr.imposter_player_id then vr.imposter_player_id
      else null
    end as imposter_player_id,
    vr.created_at at time zone 'UTC' as created_at,
    coalesce(vr.participant_ids, array[]::uuid[]) as participant_ids
  from visible_round vr;
$$;


--
-- Name: get_server_time(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_server_time() RETURNS TABLE(server_time timestamp with time zone)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  RETURN QUERY SELECT NOW();
END;
$$;


--
-- Name: get_vote_state(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_vote_state(p_round_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room_id uuid;
  v_mode text;
  v_phase text;
  v_caller_player_id uuid;
  v_is_local_host boolean := false;
  v_required_count integer := 0;
  v_submitted_count integer := 0;
  v_votes jsonb := '{}'::jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select r.room_id, rm.game_mode, r.phase
    into v_room_id, v_mode, v_phase
  from public.rounds r
  join public.rooms rm on rm.id = r.room_id
  where r.id = p_round_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROUND_NOT_FOUND';
  end if;

  select p.id
    into v_caller_player_id
  from public.round_participants rp
  join public.players p on p.id = rp.player_id
  where rp.round_id = p_round_id
    and p.user_id = v_user_id
  order by p.created_at asc, p.id asc
  limit 1;

  if v_caller_player_id is null then
    raise exception using errcode = '42501', message = 'ROUND_PARTICIPANT_REQUIRED';
  end if;

  v_is_local_host :=
    v_mode = 'local'
    and private.is_current_host(v_room_id, v_user_id);

  if v_mode = 'online' then
    select count(*)
      into v_required_count
    from public.round_participants rp
    join public.players p on p.id = rp.player_id
    where rp.round_id = p_round_id
      and p.is_online is true;

    select count(*)
      into v_submitted_count
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
    select count(*)
      into v_required_count
    from public.round_participants rp
    where rp.round_id = p_round_id;

    select count(*)
      into v_submitted_count
    from public.votes v
    where v.round_id = p_round_id
      and exists (
        select 1
        from public.round_participants rp
        where rp.round_id = p_round_id
          and rp.player_id = v.voter_player_id
      );
  end if;

  select coalesce(
      jsonb_object_agg(
        v.voter_player_id::text,
        v.voted_player_id::text
        order by v.voter_player_id::text
      ),
      '{}'::jsonb
    )
    into v_votes
  from public.votes v
  where v.round_id = p_round_id
    and (
      v_phase = 'results'
      or v_is_local_host
      or (v_mode = 'online' and v.voter_player_id = v_caller_player_id)
    );

  return jsonb_build_object(
    'votes', v_votes,
    'submitted_count', v_submitted_count,
    'required_count', v_required_count,
    'all_required_submitted',
      (v_required_count > 0 and v_submitted_count >= v_required_count)
  );
end;
$$;


--
-- Name: handle_player_presence_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_player_presence_change() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.is_online is distinct from old.is_online then
    perform public.reconcile_room_after_presence_change(new.room_id);
  end if;
  return new;
end;
$$;


--
-- Name: join_room(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.join_room(p_room_code text, p_username text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_username text := btrim(p_username);
  v_room public.rooms%rowtype;
  v_player public.players%rowtype;
  v_online_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if char_length(v_username) < 2 or char_length(v_username) > 20 then
    raise exception using errcode = '22023', message = 'INVALID_USERNAME';
  end if;

  select r.* into v_room
  from public.rooms r
  where r.room_code = btrim(p_room_code)
    and r.game_mode = 'online';

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  perform private.lock_room(v_room.id);

  select r.* into v_room
  from public.rooms r
  where r.id = v_room.id;

  if v_room.status <> 'waiting' then
    raise exception using errcode = 'P0001', message = 'ROOM_ALREADY_STARTED';
  end if;

  select p.* into v_player
  from public.players p
  where p.room_id = v_room.id
    and p.user_id = v_user_id;

  if exists (
    select 1
    from public.players p
    where p.room_id = v_room.id
      and lower(p.username) = lower(v_username)
      and (v_player.id is null or p.id <> v_player.id)
  ) then
    raise exception using errcode = '23505', message = 'USERNAME_TAKEN';
  end if;

  select count(*) into v_online_count
  from public.players p
  where p.room_id = v_room.id
    and p.is_online is true
    and (v_player.id is null or p.id <> v_player.id);

  if v_online_count >= v_room.max_players then
    raise exception using errcode = 'P0001', message = 'ROOM_FULL';
  end if;

  if v_player.id is null then
    insert into public.players(
      room_id,
      user_id,
      username,
      score,
      is_host,
      is_online,
      last_seen_at
    )
    values (
      v_room.id,
      v_user_id,
      v_username,
      0,
      false,
      true,
      now()
    )
    returning * into v_player;
  else
    update public.players p
    set username = v_username,
        is_online = true,
        last_seen_at = now()
    where p.id = v_player.id
    returning * into v_player;
  end if;

  return jsonb_build_object(
    'room', to_jsonb(v_room),
    'player', to_jsonb(v_player)
  );
end;
$$;


--
-- Name: mark_stale_players_offline(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_stale_players_offline(p_stale_seconds integer DEFAULT 60) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_updated_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if p_stale_seconds < 15 or p_stale_seconds > 3600 then
    raise exception using errcode = '22023', message = 'INVALID_STALE_SECONDS';
  end if;

  update public.players p
  set is_online = false,
      last_seen_at = now()
  where p.is_online is true
    and p.last_seen_at < now() - make_interval(secs => p_stale_seconds)
    and exists (
      select 1
      from public.rooms r
      where r.id = p.room_id
        and r.game_mode = 'online'
        and r.status in ('waiting', 'active')
        and exists (
          select 1
          from public.players host
          where host.room_id = r.id
            and host.user_id = v_user_id
            and host.is_host is true
            and host.is_online is true
        )
    );

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$$;


--
-- Name: mark_stale_players_offline(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_stale_players_offline(p_room_id uuid, p_stale_seconds integer DEFAULT 60) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_updated_count integer;
  v_mode text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if p_stale_seconds < 15 or p_stale_seconds > 3600 then
    raise exception using errcode = '22023', message = 'INVALID_STALE_SECONDS';
  end if;

  perform private.lock_room(p_room_id);

  select r.game_mode into v_mode
  from public.rooms r
  where r.id = p_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if v_mode <> 'online' then
    raise exception using errcode = '42501', message = 'ONLINE_ROOM_REQUIRED';
  end if;

  if not private.is_current_host(p_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  update public.players p
  set is_online = false,
      last_seen_at = now()
  where p.room_id = p_room_id
    and p.is_online is true
    and p.last_seen_at < now() - make_interval(secs => p_stale_seconds);

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$$;


--
-- Name: reconcile_room_after_presence_change(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_room_after_presence_change(p_room_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_mode text;
  v_status text;
  v_online_count integer;
  v_has_online_host boolean;
  v_new_host_player_id uuid;
  v_new_host_user_id uuid;
begin
  if p_room_id is null then
    return;
  end if;

  perform private.lock_room(p_room_id);

  select r.game_mode, r.status
    into v_mode, v_status
  from public.rooms r
  where r.id = p_room_id;

  if not found or v_mode <> 'online' or v_status = 'finished' then
    return;
  end if;

  select count(*)
    into v_online_count
  from public.players p
  where p.room_id = p_room_id
    and p.is_online is true;

  if v_online_count = 0 then
    update public.rooms
    set status = 'finished'
    where id = p_room_id
      and status <> 'finished';
    return;
  end if;

  select exists (
    select 1
    from public.players p
    where p.room_id = p_room_id
      and p.is_online is true
      and p.is_host is true
  ) into v_has_online_host;

  if v_has_online_host then
    return;
  end if;

  select p.id, p.user_id
    into v_new_host_player_id, v_new_host_user_id
  from public.players p
  where p.room_id = p_room_id
    and p.is_online is true
  order by p.created_at asc, p.id asc
  limit 1;

  update public.players p
  set is_host = (p.id = v_new_host_player_id)
  where p.room_id = p_room_id
    and p.is_host is distinct from (p.id = v_new_host_player_id);

  update public.rooms r
  set host_id = v_new_host_user_id
  where r.id = p_room_id;
end;
$$;


--
-- Name: start_game(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.start_game(p_room_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_user_id uuid := (select auth.uid());
  v_room public.rooms%rowtype;
  v_round_id uuid;
  v_player_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform private.lock_room(p_room_id);

  select r.* into v_room
  from public.rooms r
  where r.id = p_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if not private.is_current_host(p_room_id, v_user_id) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  if v_room.status = 'finished' then
    raise exception using errcode = 'P0001', message = 'ROOM_FINISHED';
  end if;

  select rd.id into v_round_id
  from public.rounds rd
  where rd.room_id = p_room_id
    and rd.round_number = 1;

  if v_room.status = 'active' and v_round_id is not null then
    return v_round_id;
  end if;

  select count(*) into v_player_count
  from public.players p
  where p.room_id = p_room_id
    and (v_room.game_mode = 'local' or p.is_online is true);

  if v_player_count < 4 then
    raise exception using errcode = 'P0001', message = 'NOT_ENOUGH_PLAYERS';
  end if;

  if v_room.status = 'waiting' then
    update public.rooms r
    set status = 'active'
    where r.id = p_room_id;
  end if;

  select rd.id into v_round_id
  from public.rounds rd
  where rd.room_id = p_room_id
    and rd.round_number = 1;

  if v_round_id is null then
    v_round_id := private.create_round_for_room(p_room_id, 1);
  end if;

  return v_round_id;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 100 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.characters (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    category text NOT NULL,
    difficulty text DEFAULT 'medium'::text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    emoji text DEFAULT '❓'::text,
    CONSTRAINT characters_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text])))
);

ALTER TABLE ONLY public.characters REPLICA IDENTITY FULL;


--
-- Name: hints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hints (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    round_id uuid NOT NULL,
    player_id uuid NOT NULL,
    content text NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now(),
    CONSTRAINT hints_content_check CHECK (((length(content) >= 2) AND (length(content) <= 200)))
);

ALTER TABLE ONLY public.hints REPLICA IDENTITY FULL;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    room_id uuid NOT NULL,
    player_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    round_id uuid,
    CONSTRAINT messages_content_check CHECK (((length(content) >= 1) AND (length(content) <= 500)))
);

ALTER TABLE ONLY public.messages REPLICA IDENTITY FULL;


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    room_id uuid NOT NULL,
    user_id uuid NOT NULL,
    username text NOT NULL,
    score integer DEFAULT 0,
    is_host boolean DEFAULT false,
    is_online boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    last_seen_at timestamp with time zone DEFAULT now(),
    CONSTRAINT players_score_check CHECK ((score >= 0)),
    CONSTRAINT players_username_check CHECK (((length(username) >= 2) AND (length(username) <= 20)))
);

ALTER TABLE ONLY public.players REPLICA IDENTITY FULL;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    host_id uuid NOT NULL,
    category text NOT NULL,
    max_rounds integer DEFAULT 5 NOT NULL,
    max_players integer DEFAULT 6 NOT NULL,
    round_duration integer DEFAULT 60 NOT NULL,
    current_round integer DEFAULT 0,
    room_code text NOT NULL,
    status text DEFAULT 'waiting'::text,
    used_character_ids jsonb DEFAULT '[]'::jsonb,
    created_at timestamp without time zone DEFAULT now(),
    game_mode text DEFAULT 'online'::text,
    CONSTRAINT rooms_game_mode_check CHECK ((game_mode = ANY (ARRAY['online'::text, 'local'::text]))),
    CONSTRAINT rooms_max_players_check CHECK (((max_players >= 4) AND (max_players <= 10))),
    CONSTRAINT rooms_max_rounds_check CHECK (((max_rounds >= 1) AND (max_rounds <= 10))),
    CONSTRAINT rooms_round_duration_check CHECK (((round_duration >= 30) AND (round_duration <= 900))),
    CONSTRAINT rooms_status_check CHECK ((status = ANY (ARRAY['waiting'::text, 'active'::text, 'finished'::text])))
);

ALTER TABLE ONLY public.rooms REPLICA IDENTITY FULL;


--
-- Name: COLUMN rooms.game_mode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rooms.game_mode IS 'online: players join via room code from different devices. local: pass-and-play on single device';


--
-- Name: round_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.round_participants (
    round_id uuid NOT NULL,
    player_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: round_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.round_revisions (
    round_id uuid NOT NULL,
    room_id uuid NOT NULL,
    revision bigint DEFAULT 1 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT round_revisions_revision_check CHECK ((revision > 0))
);


--
-- Name: rounds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rounds (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    room_id uuid NOT NULL,
    imposter_player_id uuid NOT NULL,
    character_id uuid NOT NULL,
    round_number integer NOT NULL,
    phase text DEFAULT 'hints'::text,
    phase_end_time timestamp without time zone NOT NULL,
    imposter_revealed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    scores_finalized_at timestamp with time zone,
    CONSTRAINT rounds_phase_check CHECK ((phase = ANY (ARRAY['hints'::text, 'voting'::text, 'results'::text]))),
    CONSTRAINT rounds_round_number_check CHECK ((round_number > 0))
);

ALTER TABLE ONLY public.rounds REPLICA IDENTITY FULL;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    round_id uuid NOT NULL,
    voter_player_id uuid NOT NULL,
    voted_player_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT votes_check CHECK ((voter_player_id <> voted_player_id))
);

ALTER TABLE ONLY public.votes REPLICA IDENTITY FULL;


--
-- Name: categories categories_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_key_key UNIQUE (key);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: characters characters_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_name_key UNIQUE (name);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: hints hints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hints
    ADD CONSTRAINT hints_pkey PRIMARY KEY (id);


--
-- Name: hints hints_round_player_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hints
    ADD CONSTRAINT hints_round_player_unique UNIQUE (round_id, player_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: players players_room_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_room_id_user_id_key UNIQUE (room_id, user_id);


--
-- Name: players players_room_username_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_room_username_unique UNIQUE (room_id, username);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_room_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_room_code_key UNIQUE (room_code);


--
-- Name: round_participants round_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_participants
    ADD CONSTRAINT round_participants_pkey PRIMARY KEY (round_id, player_id);


--
-- Name: round_revisions round_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_revisions
    ADD CONSTRAINT round_revisions_pkey PRIMARY KEY (round_id);


--
-- Name: rounds rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_pkey PRIMARY KEY (id);


--
-- Name: rounds rounds_room_id_round_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_room_id_round_number_key UNIQUE (room_id, round_number);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: votes votes_round_id_voter_player_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_round_id_voter_player_id_key UNIQUE (round_id, voter_player_id);


--
-- Name: idx_categories_active_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_active_sort ON public.categories USING btree (is_active, sort_order, name);


--
-- Name: idx_characters_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_characters_active ON public.characters USING btree (is_active);


--
-- Name: idx_characters_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_characters_category ON public.characters USING btree (category) WHERE (is_active = true);


--
-- Name: idx_hints_player; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hints_player ON public.hints USING btree (round_id, player_id);


--
-- Name: idx_hints_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hints_player_id ON public.hints USING btree (player_id);


--
-- Name: idx_hints_round; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hints_round ON public.hints USING btree (round_id, "timestamp");


--
-- Name: idx_messages_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at DESC);


--
-- Name: idx_messages_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_player_id ON public.messages USING btree (player_id);


--
-- Name: idx_messages_room_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_room_created_at ON public.messages USING btree (room_id, created_at);


--
-- Name: idx_messages_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_room_id ON public.messages USING btree (room_id);


--
-- Name: idx_messages_room_round_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_room_round_created_at ON public.messages USING btree (room_id, round_id, created_at);


--
-- Name: idx_messages_round_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_round_created_at ON public.messages USING btree (round_id, created_at);


--
-- Name: idx_players_host; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_players_host ON public.players USING btree (room_id, is_host);


--
-- Name: idx_players_online; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_players_online ON public.players USING btree (room_id, is_online);


--
-- Name: idx_players_presence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_players_presence ON public.players USING btree (room_id, is_online, last_seen_at DESC);


--
-- Name: idx_players_room; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_players_room ON public.players USING btree (room_id);


--
-- Name: idx_rooms_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rooms_category ON public.rooms USING btree (category);


--
-- Name: idx_rooms_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rooms_code ON public.rooms USING btree (room_code);


--
-- Name: idx_rooms_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rooms_status ON public.rooms USING btree (status);


--
-- Name: idx_round_participants_player; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_round_participants_player ON public.round_participants USING btree (player_id, round_id);


--
-- Name: idx_round_revisions_room; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_round_revisions_room ON public.round_revisions USING btree (room_id, round_id);


--
-- Name: idx_rounds_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rounds_character_id ON public.rounds USING btree (character_id);


--
-- Name: idx_rounds_imposter_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rounds_imposter_player_id ON public.rounds USING btree (imposter_player_id);


--
-- Name: idx_rounds_phase; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rounds_phase ON public.rounds USING btree (phase);


--
-- Name: idx_rounds_room; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rounds_room ON public.rounds USING btree (room_id, round_number);


--
-- Name: idx_votes_round; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_round ON public.votes USING btree (round_id);


--
-- Name: idx_votes_voted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_voted ON public.votes USING btree (round_id, voted_player_id);


--
-- Name: idx_votes_voted_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_voted_player_id ON public.votes USING btree (voted_player_id);


--
-- Name: idx_votes_voter_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_voter_player_id ON public.votes USING btree (voter_player_id);


--
-- Name: hints trigger_bump_revision_hints; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_bump_revision_hints AFTER INSERT OR DELETE OR UPDATE ON public.hints FOR EACH ROW EXECUTE FUNCTION private.bump_revision_from_child();


--
-- Name: votes trigger_bump_revision_votes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_bump_revision_votes AFTER INSERT OR DELETE OR UPDATE ON public.votes FOR EACH ROW EXECUTE FUNCTION private.bump_revision_from_child();


--
-- Name: rounds trigger_capture_round_state; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_capture_round_state AFTER INSERT OR UPDATE ON public.rounds FOR EACH ROW EXECUTE FUNCTION private.capture_round_state();


--
-- Name: rooms trigger_create_first_round; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_create_first_round AFTER UPDATE ON public.rooms FOR EACH ROW EXECUTE FUNCTION public.create_first_round();


--
-- Name: players trigger_enforce_room_capacity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_enforce_room_capacity BEFORE INSERT OR UPDATE OF room_id, is_online ON public.players FOR EACH ROW EXECUTE FUNCTION public.enforce_room_capacity();


--
-- Name: players trigger_handle_player_presence_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_handle_player_presence_change AFTER UPDATE OF is_online ON public.players FOR EACH ROW EXECUTE FUNCTION public.handle_player_presence_change();


--
-- Name: rooms trigger_prevent_room_mode_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_prevent_room_mode_change BEFORE UPDATE OF game_mode ON public.rooms FOR EACH ROW EXECUTE FUNCTION private.prevent_room_mode_change();


--
-- Name: hints hints_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hints
    ADD CONSTRAINT hints_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: hints hints_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hints
    ADD CONSTRAINT hints_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;


--
-- Name: messages messages_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: messages messages_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: messages messages_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;


--
-- Name: players players_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: rooms rooms_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_category_fkey FOREIGN KEY (category) REFERENCES public.categories(key);


--
-- Name: round_participants round_participants_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_participants
    ADD CONSTRAINT round_participants_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: round_participants round_participants_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_participants
    ADD CONSTRAINT round_participants_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;


--
-- Name: round_revisions round_revisions_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_revisions
    ADD CONSTRAINT round_revisions_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: round_revisions round_revisions_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_revisions
    ADD CONSTRAINT round_revisions_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;


--
-- Name: rounds rounds_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: rounds rounds_imposter_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_imposter_player_id_fkey FOREIGN KEY (imposter_player_id) REFERENCES public.players(id);


--
-- Name: rounds rounds_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: votes votes_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id) ON DELETE CASCADE;


--
-- Name: votes votes_voted_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_voted_player_id_fkey FOREIGN KEY (voted_player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: votes votes_voter_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_voter_player_id_fkey FOREIGN KEY (voter_player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: rooms Anyone can create room; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can create room" ON public.rooms FOR INSERT WITH CHECK (true);


--
-- Name: players Anyone can join as player; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can join as player" ON public.players FOR INSERT WITH CHECK (true);


--
-- Name: categories Anyone can view categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view categories" ON public.categories FOR SELECT USING (true);


--
-- Name: characters Anyone can view characters; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view characters" ON public.characters FOR SELECT USING (true);


--
-- Name: hints Anyone can view hints; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view hints" ON public.hints FOR SELECT USING (true);


--
-- Name: players Anyone can view players; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view players" ON public.players FOR SELECT USING (true);


--
-- Name: rooms Anyone can view rooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view rooms" ON public.rooms FOR SELECT USING (true);


--
-- Name: votes Anyone can view votes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view votes" ON public.votes FOR SELECT USING (true);


--
-- Name: hints Online participants can add their hint; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Online participants can add their hint" ON public.hints FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM (((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants rp ON (((rp.round_id = r.id) AND (rp.player_id = hints.player_id))))
     JOIN public.players p ON ((p.id = rp.player_id)))
  WHERE ((r.id = hints.round_id) AND (r.phase = 'hints'::text) AND (rm.game_mode = 'online'::text) AND (p.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: hints Online participants can update their hint; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Online participants can update their hint" ON public.hints FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM (((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants rp ON (((rp.round_id = r.id) AND (rp.player_id = hints.player_id))))
     JOIN public.players p ON ((p.id = rp.player_id)))
  WHERE ((r.id = hints.round_id) AND (r.phase = 'hints'::text) AND (rm.game_mode = 'online'::text) AND (p.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants rp ON (((rp.round_id = r.id) AND (rp.player_id = hints.player_id))))
     JOIN public.players p ON ((p.id = rp.player_id)))
  WHERE ((r.id = hints.round_id) AND (r.phase = 'hints'::text) AND (rm.game_mode = 'online'::text) AND (p.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: rounds Only host can delete rounds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only host can delete rounds" ON public.rounds FOR DELETE USING ((EXISTS ( SELECT 1
   FROM (public.rooms r
     JOIN public.players p ON ((p.room_id = r.id)))
  WHERE ((r.id = rounds.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid)) AND (p.is_host = true)))));


--
-- Name: rounds Only host can manage rounds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only host can manage rounds" ON public.rounds FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.rooms r
     JOIN public.players p ON ((p.room_id = r.id)))
  WHERE ((r.id = rounds.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid)) AND (p.is_host = true)))));


--
-- Name: rounds Only host can modify rounds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only host can modify rounds" ON public.rounds FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM (public.rooms r
     JOIN public.players p ON ((p.room_id = r.id)))
  WHERE ((r.id = rounds.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid)) AND (p.is_host = true)))));


--
-- Name: rooms Only host can update room; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only host can update room" ON public.rooms FOR UPDATE USING ((host_id = ( SELECT auth.uid() AS uid)));


--
-- Name: votes Participants can submit valid votes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Participants can submit valid votes" ON public.votes FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM ((((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants voter_rp ON (((voter_rp.round_id = r.id) AND (voter_rp.player_id = votes.voter_player_id))))
     JOIN public.round_participants target_rp ON (((target_rp.round_id = r.id) AND (target_rp.player_id = votes.voted_player_id))))
     JOIN public.players voter ON ((voter.id = voter_rp.player_id)))
  WHERE ((r.id = votes.round_id) AND (r.phase = 'voting'::text) AND (((rm.game_mode = 'online'::text) AND (voter.user_id = ( SELECT auth.uid() AS uid))) OR ((rm.game_mode = 'local'::text) AND (EXISTS ( SELECT 1
           FROM public.players host
          WHERE ((host.room_id = r.room_id) AND (host.user_id = ( SELECT auth.uid() AS uid)) AND (host.is_host IS TRUE))))))))));


--
-- Name: votes Participants can update valid votes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Participants can update valid votes" ON public.votes FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM (((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants voter_rp ON (((voter_rp.round_id = r.id) AND (voter_rp.player_id = votes.voter_player_id))))
     JOIN public.players voter ON ((voter.id = voter_rp.player_id)))
  WHERE ((r.id = votes.round_id) AND (r.phase = 'voting'::text) AND (((rm.game_mode = 'online'::text) AND (voter.user_id = ( SELECT auth.uid() AS uid))) OR ((rm.game_mode = 'local'::text) AND (EXISTS ( SELECT 1
           FROM public.players host
          WHERE ((host.room_id = r.room_id) AND (host.user_id = ( SELECT auth.uid() AS uid)) AND (host.is_host IS TRUE)))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ((((public.rounds r
     JOIN public.rooms rm ON ((rm.id = r.room_id)))
     JOIN public.round_participants voter_rp ON (((voter_rp.round_id = r.id) AND (voter_rp.player_id = votes.voter_player_id))))
     JOIN public.round_participants target_rp ON (((target_rp.round_id = r.id) AND (target_rp.player_id = votes.voted_player_id))))
     JOIN public.players voter ON ((voter.id = voter_rp.player_id)))
  WHERE ((r.id = votes.round_id) AND (r.phase = 'voting'::text) AND (((rm.game_mode = 'online'::text) AND (voter.user_id = ( SELECT auth.uid() AS uid))) OR ((rm.game_mode = 'local'::text) AND (EXISTS ( SELECT 1
           FROM public.players host
          WHERE ((host.room_id = r.room_id) AND (host.user_id = ( SELECT auth.uid() AS uid)) AND (host.is_host IS TRUE))))))))));


--
-- Name: players Players can update themselves; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Players can update themselves" ON public.players FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: round_participants Room members can view round participants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Room members can view round participants" ON public.round_participants FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.rounds r
     JOIN public.players caller ON (((caller.room_id = r.room_id) AND (caller.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (r.id = round_participants.round_id))));


--
-- Name: round_revisions Room members can view round revisions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Room members can view round revisions" ON public.round_revisions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.players caller
  WHERE ((caller.room_id = round_revisions.room_id) AND (caller.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: rounds Room members can view rounds legacy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Room members can view rounds legacy" ON public.rounds FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.players p
  WHERE ((p.room_id = rounds.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: messages Room players can send messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Room players can send messages" ON public.messages FOR INSERT WITH CHECK (((round_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.players p
     JOIN public.rounds r ON ((r.id = messages.round_id)))
  WHERE ((p.id = messages.player_id) AND (r.room_id = messages.room_id) AND (p.room_id = r.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: messages Room players can view messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Room players can view messages" ON public.messages FOR SELECT USING (((round_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.players p
     JOIN public.rounds r ON ((r.id = messages.round_id)))
  WHERE ((r.room_id = messages.room_id) AND (p.room_id = r.room_id) AND (p.user_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

--
-- Name: characters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;

--
-- Name: hints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hints ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: players; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

--
-- Name: rooms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

--
-- Name: round_participants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.round_participants ENABLE ROW LEVEL SECURITY;

--
-- Name: round_revisions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.round_revisions ENABLE ROW LEVEL SECURITY;

--
-- Name: rounds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rounds ENABLE ROW LEVEL SECURITY;

--
-- Name: votes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict gkLm8rrpwAAujFp7P0JynmzYV6ZjHcgs2DxnCnYD93SKRzpSbAThnK0q8T60WXV

