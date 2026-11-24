-- "Play again": the host of a finished room opens a new room (same or changed
-- settings) and, in Online Mode, invites everyone from the finished room.
-- Invitees accept (joins the new room through join_room, so capacity, status
-- and username rules stay in one place) or decline. A new room is created
-- instead of resetting the old one so finished-game history is never deleted.

alter table public.rooms
  add column if not exists rematch_of uuid references public.rooms(id) on delete set null;

create table if not exists public.room_invites (
  room_id uuid not null references public.rooms(id) on delete cascade,
  previous_room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null,
  username text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  primary key (room_id, user_id)
);

create index if not exists room_invites_invitee_idx
  on public.room_invites (user_id, previous_room_id);

alter table public.room_invites enable row level security;

-- Reads only: an invitee sees their own invites, members of the new room see
-- who was invited. All writes go through the RPCs below.
drop policy if exists "Invitees and room members can view invites" on public.room_invites;
create policy "Invitees and room members can view invites"
  on public.room_invites for select to authenticated
  using (
    user_id = (select auth.uid())
    or private.is_room_member(room_id, (select auth.uid()))
  );

revoke all on table public.room_invites from anon, authenticated;
grant select on table public.room_invites to authenticated;

alter publication supabase_realtime add table public.room_invites;

create or replace function public.create_rematch(
  p_previous_room_id uuid,
  p_request_id uuid,
  p_category text,
  p_max_rounds integer,
  p_max_players integer,
  p_round_duration integer,
  p_host_username text,
  p_local_names text[] default array[]::text[]
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid := (select auth.uid());
  v_previous public.rooms%rowtype;
  v_result jsonb;
  v_room_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select r.* into v_previous
  from public.rooms r
  where r.id = p_previous_room_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'ROOM_NOT_FOUND';
  end if;

  if v_previous.status <> 'finished' then
    raise exception using errcode = 'P0001', message = 'ROOM_NOT_FINISHED';
  end if;

  -- The host may have been marked offline by stale cleanup while sitting on
  -- the Game Over screen, so host status, not presence, is what counts here.
  if not exists (
    select 1
    from public.players p
    where p.room_id = p_previous_room_id
      and p.user_id = v_user_id
      and p.is_host is true
  ) then
    raise exception using errcode = '42501', message = 'HOST_REQUIRED';
  end if;

  -- Same validation, idempotency (p_request_id) and player rows as a normal room.
  v_result := public.create_room(
    p_request_id,
    p_category,
    p_max_rounds,
    p_max_players,
    p_round_duration,
    v_previous.game_mode,
    p_host_username,
    case when v_previous.game_mode = 'local'
      then coalesce(p_local_names, array[]::text[])
      else array[]::text[]
    end
  );
  v_room_id := (v_result -> 'room' ->> 'id')::uuid;

  update public.rooms r
  set rematch_of = p_previous_room_id
  where r.id = v_room_id
    and r.rematch_of is null;

  if v_previous.game_mode = 'online' then
    insert into public.room_invites (room_id, previous_room_id, user_id, username)
    select distinct on (p.user_id) v_room_id, p_previous_room_id, p.user_id, p.username
    from public.players p
    where p.room_id = p_previous_room_id
      and p.user_id <> v_user_id
    order by p.user_id, p.created_at desc
    on conflict (room_id, user_id) do nothing;
  end if;

  return v_result;
end;
$function$;

create or replace function public.respond_rematch_invite(
  p_room_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid := (select auth.uid());
  v_invite public.room_invites%rowtype;
  v_room_code text;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select i.* into v_invite
  from public.room_invites i
  where i.room_id = p_room_id
    and i.user_id = v_user_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'INVITE_NOT_FOUND';
  end if;

  if not coalesce(p_accept, false) then
    update public.room_invites i
    set status = 'declined', responded_at = now()
    where i.room_id = p_room_id and i.user_id = v_user_id;
    return null;
  end if;

  select r.room_code into v_room_code
  from public.rooms r
  where r.id = p_room_id;

  -- join_room enforces waiting status, capacity and unique usernames; if it
  -- raises, the invite stays as it was.
  v_result := public.join_room(v_room_code, v_invite.username);

  update public.room_invites i
  set status = 'accepted', responded_at = now()
  where i.room_id = p_room_id and i.user_id = v_user_id;

  return v_result;
end;
$function$;

revoke all on function public.create_rematch(uuid, uuid, text, integer, integer, integer, text, text[]) from public, anon;
grant execute on function public.create_rematch(uuid, uuid, text, integer, integer, integer, text, text[]) to authenticated;

revoke all on function public.respond_rematch_invite(uuid, boolean) from public, anon;
grant execute on function public.respond_rematch_invite(uuid, boolean) to authenticated;
