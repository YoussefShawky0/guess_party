-- Member-driven stale-player cleanup.
--
-- Previously only the (online) host could run mark_stale_players_offline, so a
-- crashed host stayed is_online = true forever: nobody could mark it stale and
-- the handle_player_presence_change trigger (host migration / empty-room
-- cleanup) never fired. Any ONLINE member of the room may now run the cleanup.
-- A caller that is heartbeating has a fresh last_seen_at and therefore cannot
-- mark itself stale. Signatures, SECURITY DEFINER, search_path and the existing
-- execute grants (ACLs survive CREATE OR REPLACE) are unchanged. Idempotent.

-- Room-scoped overload.
create or replace function public.mark_stale_players_offline(p_room_id uuid, p_stale_seconds integer default 60)
returns integer
language plpgsql
security definer
set search_path to ''
as $$
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

  if not exists (
    select 1
    from public.players m
    where m.room_id = p_room_id
      and m.user_id = v_user_id
      and m.is_online is true
  ) then
    raise exception using errcode = '42501', message = 'ROOM_MEMBER_REQUIRED';
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

-- Legacy single-argument overload: scoped to rooms where the caller is an
-- online member (previously: online host).
create or replace function public.mark_stale_players_offline(p_stale_seconds integer default 60)
returns integer
language plpgsql
security definer
set search_path to ''
as $$
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
          from public.players m
          where m.room_id = r.id
            and m.user_id = v_user_id
            and m.is_online is true
        )
    );

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$$;
