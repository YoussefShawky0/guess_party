-- P0 privilege hardening for the Data API roles.
--
-- Problems closed here (all verified against the canonical chain):
--   * 20260712195404_table_grants.sql granted ALL on the gameplay tables to
--     anon and authenticated, so RLS was the only barrier and several
--     policies were far too permissive.
--   * "Players can update themselves" let a player rewrite their own score,
--     is_host, room_id and username.
--   * "Anyone can create room" / "Anyone can join as player" allowed arbitrary
--     direct inserts (even as anon). The app only uses the create_room and
--     join_room SECURITY DEFINER RPCs.
--   * Host-only direct write policies on rounds and rooms let a host flip
--     rounds.phase to 'results' and then read imposter_player_id. Every state
--     transition is a SECURITY DEFINER RPC owned by postgres.
--   * USING (true) SELECT policies let anon enumerate every room, player
--     user_id and hint.
--   * The hints INSERT/UPDATE policies joined RLS-hidden active rounds, so
--     online hint writes were denied. Same issue votes had, fixed there in
--     20260716183110; fixed here with private.can_write_hint.
--
-- This migration is idempotent on purpose: production has policy/grant drift,
-- so every statement is safe to re-run (drop ... if exists, create or replace,
-- revoke/grant are absolute). Existing migrations are not modified.

-- ---------------------------------------------------------------------------
-- 1. Table privileges
-- ---------------------------------------------------------------------------

-- Remove every non-read privilege from the Data API roles. Revoking a table
-- level privilege also removes any column-level grant of the same kind, so the
-- re-grants below are authoritative.
revoke insert, update, delete, truncate, references, trigger
on table
  public.players,
  public.rooms,
  public.rounds,
  public.hints,
  public.votes,
  public.messages,
  public.categories,
  public.characters
from anon, authenticated;

-- Nothing in the game is reachable without a session: guests use Supabase
-- anonymous sign-in, which yields the `authenticated` role, never `anon`.
-- anon therefore needs no access to per-room data at all. It keeps SELECT on
-- the two static catalog tables only (non-sensitive, RLS still applies).
revoke select on table
  public.players,
  public.rooms,
  public.rounds,
  public.hints,
  public.votes,
  public.messages
from anon;

grant select on table public.categories, public.characters to anon;

-- Authenticated keeps SELECT everywhere (RLS decides the rows).
grant select on table
  public.players,
  public.rooms,
  public.rounds,
  public.hints,
  public.votes,
  public.messages,
  public.categories,
  public.characters
to authenticated;

-- The only direct writes the Flutter client performs:
--   * players heartbeat/leave: UPDATE is_online, last_seen_at on own rows;
--   * hints/votes upserts (onConflict round_id,player_id / round_id,voter_player_id),
--     still governed by the existing INSERT/UPDATE RLS policies.
-- Everything else is an RPC.
grant update (is_online, last_seen_at) on public.players to authenticated;
grant insert, update on public.hints, public.votes to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Drop over-permissive direct-write policies
-- ---------------------------------------------------------------------------

drop policy if exists "Anyone can create room" on public.rooms;
drop policy if exists "Anyone can join as player" on public.players;
drop policy if exists "Only host can manage rounds" on public.rounds;
drop policy if exists "Only host can modify rounds" on public.rounds;
drop policy if exists "Only host can delete rounds" on public.rounds;
drop policy if exists "Only host can update room" on public.rooms;

-- ---------------------------------------------------------------------------
-- 3. Presence stamping and defense-in-depth column guard
-- ---------------------------------------------------------------------------

-- "Players can update themselves" is intentionally kept; the column grant
-- above now limits it to is_online/last_seen_at.
--
-- Trigger security mode: SECURITY INVOKER. Inside a SECURITY DEFINER function
-- current_user is the function owner (postgres), so the trigger sees client
-- role names only for statements issued directly by PostgREST/Realtime
-- (SET LOCAL ROLE authenticated). All internal RPC paths (join_room,
-- mark_stale_players_offline, reconcile_room_after_presence_change,
-- delete_current_account, ...) and the postgres-run pgTAP fixtures therefore
-- skip the override, which presence_lifecycle_contracts.test.sql relies on
-- when it backdates last_seen_at. A SECURITY DEFINER trigger could not tell
-- the two apart without reading the request.jwt role GUC, and that GUC is
-- still 'authenticated' while a definer RPC runs, so it would wrongly
-- override/deny trusted writes.
--
-- Execute privilege is only checked when the trigger is created (by
-- postgres), not when it fires, so the postgres-only ACL below is enough and
-- mirrors private.prevent_room_mode_change().
create or replace function private.stamp_client_presence()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') then
    -- Grants already restrict clients to is_online/last_seen_at. If grants
    -- ever drift, still refuse any other column change.
    if (to_jsonb(new) - 'is_online' - 'last_seen_at')
       is distinct from (to_jsonb(old) - 'is_online' - 'last_seen_at') then
      raise exception using
        errcode = '42501',
        message = 'PLAYER_COLUMN_UPDATE_FORBIDDEN';
    end if;

    -- Never trust the device clock.
    new.last_seen_at := now();
  end if;

  return new;
end;
$$;

revoke execute on function private.stamp_client_presence()
from public, anon, authenticated, service_role;
grant execute on function private.stamp_client_presence() to postgres;

drop trigger if exists trigger_stamp_client_presence on public.players;
create trigger trigger_stamp_client_presence
before update on public.players
for each row
execute function private.stamp_client_presence();

-- ---------------------------------------------------------------------------
-- 4. Membership-scoped SELECT policies
-- ---------------------------------------------------------------------------

-- The players/rooms policies use the existing SECURITY DEFINER helper, which
-- avoids recursive RLS on public.players. Membership is a row in players and
-- survives is_online = false, so resume/refresh reads keep working.
create or replace function private.can_view_round_hints(p_round_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.rounds r
      join public.players p on p.room_id = r.room_id
      where r.id = p_round_id
        and p.user_id = (select auth.uid())
    );
$$;

revoke execute on function private.is_room_member(uuid, uuid)
from public, anon, authenticated, service_role;
revoke execute on function private.can_view_round_hints(uuid)
from public, anon, authenticated, service_role;

grant usage on schema private to authenticated;
grant execute on function private.is_room_member(uuid, uuid)
to authenticated, postgres, service_role;
grant execute on function private.can_view_round_hints(uuid)
to authenticated, postgres, service_role;

drop policy if exists "Anyone can view players" on public.players;
drop policy if exists "Room members can view players" on public.players;
create policy "Room members can view players"
on public.players for select to authenticated
using (private.is_room_member(room_id, (select auth.uid())));

-- The host check keeps a room visible to its creator even if a membership row
-- is ever missing; it exposes nothing the host does not already own.
drop policy if exists "Anyone can view rooms" on public.rooms;
drop policy if exists "Room members can view rooms" on public.rooms;
create policy "Room members can view rooms"
on public.rooms for select to authenticated
using (
  host_id = (select auth.uid())
  or private.is_room_member(id, (select auth.uid()))
);

drop policy if exists "Anyone can view hints" on public.hints;
drop policy if exists "Room members can view hints" on public.hints;
create policy "Room members can view hints"
on public.hints for select to authenticated
using (private.can_view_round_hints(round_id));

-- ---------------------------------------------------------------------------
-- 5. Hint write policies (same bug votes had, fixed in 20260716183110)
-- ---------------------------------------------------------------------------
-- The original hints INSERT/UPDATE policies joined public.rounds as the
-- caller. Active rounds are hidden from raw SELECT by RLS, so the join found
-- nothing and every online hint write was denied. The boolean check moves to a
-- definer helper with the exact same semantics.
create or replace function private.can_write_hint(
  p_round_id uuid,
  p_player_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.rounds r
      join public.rooms rm on rm.id = r.room_id
      join public.round_participants rp
        on rp.round_id = r.id
       and rp.player_id = p_player_id
      join public.players p on p.id = rp.player_id
      where r.id = p_round_id
        and r.phase = 'hints'
        and rm.game_mode = 'online'
        and p.user_id = (select auth.uid())
    );
$$;

revoke execute on function private.can_write_hint(uuid, uuid)
from public, anon, authenticated, service_role;
grant execute on function private.can_write_hint(uuid, uuid)
to authenticated, postgres, service_role;

drop policy if exists "Online participants can add their hint" on public.hints;
create policy "Online participants can add their hint"
on public.hints for insert to authenticated
with check (private.can_write_hint(round_id, player_id));

drop policy if exists "Online participants can update their hint" on public.hints;
create policy "Online participants can update their hint"
on public.hints for update to authenticated
using (private.can_write_hint(round_id, player_id))
with check (private.can_write_hint(round_id, player_id));

-- ---------------------------------------------------------------------------
-- 6. Intentionally unchanged
-- ---------------------------------------------------------------------------
-- votes INSERT/UPDATE policies, rounds/votes SELECT policies,
-- round_participants/round_revisions policies and the chat policies keep their
-- existing definitions.
