-- Production-compatible delta for the live project that predates the
-- canonical migration reconstruction.
--
-- The clean canonical chain already contains the target state in:
-- - 20260713015743_fix_recursive_secret_state_rls.sql
-- - 20260713185018_chat_security_and_reliability.sql
--
-- The live production migration ledger contains older incremental migrations,
-- so this file is intentionally idempotent and explicitly removes legacy broad
-- raw-table policies before adding the secure RPC-compatible model.

create or replace function private.can_view_completed_round(
  p_round_id uuid,
  p_phase text
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_phase = 'results'
    and (select auth.uid()) is not null
    and exists (
      select 1
      from public.round_participants rp
      join public.players p on p.id = rp.player_id
      where rp.round_id = p_round_id
        and p.user_id = (select auth.uid())
    );
$$;

create or replace function private.can_view_vote_row(
  p_round_id uuid,
  p_voter_player_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.rounds r
    join public.rooms rm on rm.id = r.room_id
    join public.round_participants caller_rp on caller_rp.round_id = r.id
    join public.players caller on caller.id = caller_rp.player_id
    where r.id = p_round_id
      and caller.user_id = (select auth.uid())
      and (
        caller.id = p_voter_player_id
        or r.phase = 'results'
        or (
          rm.game_mode = 'local'
          and caller.is_host is true
          and caller.user_id = rm.host_id
        )
      )
  );
$$;

revoke execute on function private.can_view_completed_round(uuid, text) from public, anon, authenticated, service_role;
revoke execute on function private.can_view_vote_row(uuid, uuid) from public, anon, authenticated, service_role;
grant usage on schema private to authenticated;
grant execute on function private.can_view_completed_round(uuid, text) to authenticated, postgres, service_role;
grant execute on function private.can_view_vote_row(uuid, uuid) to authenticated, postgres, service_role;

drop policy if exists "Room members can view rounds legacy" on public.rounds;
drop policy if exists "Round participants can view completed rounds" on public.rounds;
create policy "Round participants can view completed rounds"
on public.rounds for select to authenticated
using (private.can_view_completed_round(id, phase));

drop policy if exists "Anyone can view votes" on public.votes;
drop policy if exists "Participants can view authorized votes" on public.votes;
create policy "Participants can view authorized votes"
on public.votes for select to authenticated
using (private.can_view_vote_row(round_id, voter_player_id));

create table if not exists public.player_mutes (
  room_id uuid not null references public.rooms(id) on delete cascade,
  muter_player_id uuid not null references public.players(id) on delete cascade,
  muted_player_id uuid not null references public.players(id) on delete cascade,
  created_at timestamp with time zone not null default now(),
  primary key (room_id, muter_player_id, muted_player_id),
  constraint player_mutes_no_self check (muter_player_id <> muted_player_id)
);

alter table only public.player_mutes replica identity full;

create table if not exists public.message_reports (
  id uuid primary key default extensions.uuid_generate_v4(),
  message_id uuid not null references public.messages(id) on delete cascade,
  reporter_player_id uuid not null references public.players(id) on delete cascade,
  reason text not null check (char_length(btrim(reason)) between 1 and 500),
  status text not null default 'open'
    check (status in ('open', 'reviewed', 'dismissed', 'actioned')),
  created_at timestamp with time zone not null default now(),
  reviewed_at timestamp with time zone,
  unique (message_id, reporter_player_id)
);

alter table only public.message_reports replica identity full;

create index if not exists idx_messages_room_round_created_id
on public.messages using btree (room_id, round_id, created_at desc, id desc);

create index if not exists idx_player_mutes_muter
on public.player_mutes using btree (room_id, muter_player_id);

create index if not exists idx_message_reports_message
on public.message_reports using btree (message_id);

alter table public.player_mutes enable row level security;
alter table public.message_reports enable row level security;

drop policy if exists "Room players can send messages" on public.messages;
drop policy if exists "Room players can view messages" on public.messages;

create or replace function private.can_view_chat_message(
  p_room_id uuid,
  p_sender_player_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.players caller
    where caller.room_id = p_room_id
      and caller.user_id = (select auth.uid())
      and not exists (
        select 1
        from public.player_mutes pm
        where pm.room_id = p_room_id
          and pm.muter_player_id = caller.id
          and pm.muted_player_id = p_sender_player_id
      )
  );
$function$;

create policy "Room players can view messages"
on public.messages for select to authenticated
using (
  round_id is not null
  and private.can_view_chat_message(messages.room_id, messages.player_id)
);

drop policy if exists "Players can view own mutes" on public.player_mutes;
create policy "Players can view own mutes"
on public.player_mutes for select to authenticated
using (
  exists (
    select 1
    from public.players caller
    where caller.id = player_mutes.muter_player_id
      and caller.room_id = player_mutes.room_id
      and caller.user_id = (select auth.uid())
  )
);

drop policy if exists "Players can create own mutes" on public.player_mutes;
create policy "Players can create own mutes"
on public.player_mutes for insert to authenticated
with check (
  exists (
    select 1
    from public.players muter
    join public.players muted on muted.id = player_mutes.muted_player_id
    where muter.id = player_mutes.muter_player_id
      and muter.room_id = player_mutes.room_id
      and muted.room_id = player_mutes.room_id
      and muter.user_id = (select auth.uid())
  )
);

drop policy if exists "Players can delete own mutes" on public.player_mutes;
create policy "Players can delete own mutes"
on public.player_mutes for delete to authenticated
using (
  exists (
    select 1
    from public.players caller
    where caller.id = player_mutes.muter_player_id
      and caller.room_id = player_mutes.room_id
      and caller.user_id = (select auth.uid())
  )
);

create or replace function public.send_chat_message(
  p_room_id uuid,
  p_round_id uuid,
  p_content text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_content text := btrim(coalesce(p_content, ''));
  v_player_id uuid;
  v_username text;
  v_message_id uuid;
  v_created_at timestamp with time zone;
begin
  if v_uid is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if char_length(v_content) < 1 or char_length(v_content) > 500 then
    raise exception using errcode = '22023', message = 'INVALID_CHAT_CONTENT';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_uid::text, 0)
  );

  select p.id, p.username
    into v_player_id, v_username
  from public.players p
  where p.room_id = p_room_id
    and p.user_id = v_uid
    and p.is_online = true;

  if v_player_id is null then
    raise exception using errcode = '42501', message = 'ROOM_PARTICIPANT_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.rounds r
    join public.round_participants rp on rp.round_id = r.id
    where r.id = p_round_id
      and r.room_id = p_room_id
      and rp.player_id = v_player_id
  ) then
    raise exception using errcode = '42501', message = 'ROUND_PARTICIPANT_REQUIRED';
  end if;

  if (
    select count(*)
    from public.messages m
    where m.player_id = v_player_id
      and m.created_at >= now() - interval '10 seconds'
  ) >= 5 then
    raise exception using errcode = 'P0001', message = 'CHAT_RATE_LIMITED';
  end if;

  insert into public.messages (room_id, round_id, player_id, content)
  values (p_room_id, p_round_id, v_player_id, v_content)
  returning id, created_at into v_message_id, v_created_at;

  return jsonb_build_object(
    'id', v_message_id,
    'room_id', p_room_id,
    'round_id', p_round_id,
    'player_id', v_player_id,
    'username', v_username,
    'content', v_content,
    'created_at', v_created_at
  );
end;
$function$;

create or replace function public.list_chat_messages(
  p_room_id uuid,
  p_round_id uuid,
  p_before_created_at timestamp with time zone default null,
  p_before_id uuid default null,
  p_limit integer default 30
) returns table (
  id uuid,
  room_id uuid,
  round_id uuid,
  player_id uuid,
  username text,
  content text,
  created_at timestamp with time zone
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_player_id uuid;
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 50);
begin
  if v_uid is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if (p_before_created_at is null) <> (p_before_id is null) then
    raise exception using errcode = '22023', message = 'INVALID_CHAT_CURSOR';
  end if;

  select p.id into v_player_id
  from public.players p
  where p.room_id = p_room_id
    and p.user_id = v_uid;

  if v_player_id is null then
    raise exception using errcode = '42501', message = 'ROOM_PARTICIPANT_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.rounds r
    where r.id = p_round_id
      and r.room_id = p_room_id
  ) then
    raise exception using errcode = 'P0002', message = 'ROUND_NOT_FOUND';
  end if;

  return query
  select m.id, m.room_id, m.round_id, m.player_id, p.username, m.content, m.created_at
  from public.messages m
  join public.players p on p.id = m.player_id
  where m.room_id = p_room_id
    and m.round_id = p_round_id
    and (
      p_before_created_at is null
      or (m.created_at, m.id) < (p_before_created_at, p_before_id)
    )
    and not exists (
      select 1
      from public.player_mutes pm
      where pm.room_id = p_room_id
        and pm.muter_player_id = v_player_id
        and pm.muted_player_id = m.player_id
    )
  order by m.created_at desc, m.id desc
  limit v_limit;
end;
$function$;

create or replace function public.set_player_muted(
  p_room_id uuid,
  p_muted_player_id uuid,
  p_muted boolean
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_muter_player_id uuid;
begin
  if v_uid is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select p.id into v_muter_player_id
  from public.players p
  where p.room_id = p_room_id
    and p.user_id = v_uid;

  if v_muter_player_id is null then
    raise exception using errcode = '42501', message = 'ROOM_PARTICIPANT_REQUIRED';
  end if;

  if not exists (
    select 1 from public.players p
    where p.id = p_muted_player_id
      and p.room_id = p_room_id
  ) then
    raise exception using errcode = 'P0002', message = 'PLAYER_NOT_FOUND';
  end if;

  if p_muted then
    insert into public.player_mutes (room_id, muter_player_id, muted_player_id)
    values (p_room_id, v_muter_player_id, p_muted_player_id)
    on conflict do nothing;
  else
    delete from public.player_mutes pm
    where pm.room_id = p_room_id
      and pm.muter_player_id = v_muter_player_id
      and pm.muted_player_id = p_muted_player_id;
  end if;
end;
$function$;

create or replace function public.report_chat_message(
  p_message_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_reason text := btrim(coalesce(p_reason, ''));
  v_reporter_player_id uuid;
  v_report_id uuid;
begin
  if v_uid is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  if char_length(v_reason) < 1 or char_length(v_reason) > 500 then
    raise exception using errcode = '22023', message = 'INVALID_REPORT_REASON';
  end if;

  select reporter.id
    into v_reporter_player_id
  from public.messages m
  join public.players reporter on reporter.room_id = m.room_id
  where m.id = p_message_id
    and reporter.user_id = v_uid;

  if v_reporter_player_id is null then
    raise exception using errcode = '42501', message = 'ROOM_PARTICIPANT_REQUIRED';
  end if;

  select mr.id into v_report_id
  from public.message_reports mr
  where mr.message_id = p_message_id
    and mr.reporter_player_id = v_reporter_player_id;

  if v_report_id is not null then
    return v_report_id;
  end if;

  insert into public.message_reports (message_id, reporter_player_id, reason)
  values (p_message_id, v_reporter_player_id, v_reason)
  returning id into v_report_id;

  return v_report_id;
exception
  when unique_violation then
    select mr.id into v_report_id
    from public.message_reports mr
    where mr.message_id = p_message_id
      and mr.reporter_player_id = v_reporter_player_id;
    return v_report_id;
end;
$function$;

revoke insert on table public.messages from anon, authenticated;
revoke all privileges on table public.player_mutes from anon, authenticated;
revoke all privileges on table public.message_reports from anon, authenticated;

grant select, insert, delete on table public.player_mutes to authenticated;
grant all privileges on table public.player_mutes to service_role;
grant all privileges on table public.message_reports to service_role;

revoke execute on function public.send_chat_message(uuid, uuid, text) from public, anon;
revoke execute on function public.list_chat_messages(uuid, uuid, timestamp with time zone, uuid, integer) from public, anon;
revoke execute on function public.set_player_muted(uuid, uuid, boolean) from public, anon;
revoke execute on function public.report_chat_message(uuid, text) from public, anon;
revoke execute on function private.can_view_chat_message(uuid, uuid) from public, anon, authenticated, service_role;

grant execute on function public.send_chat_message(uuid, uuid, text) to authenticated, postgres, service_role;
grant execute on function public.list_chat_messages(uuid, uuid, timestamp with time zone, uuid, integer) to authenticated, postgres, service_role;
grant execute on function public.set_player_muted(uuid, uuid, boolean) to authenticated, postgres, service_role;
grant execute on function public.report_chat_message(uuid, text) to authenticated, postgres, service_role;
grant execute on function private.can_view_chat_message(uuid, uuid) to authenticated, postgres, service_role;
