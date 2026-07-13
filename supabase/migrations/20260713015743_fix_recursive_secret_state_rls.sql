-- Break RLS policy recursion while preserving the secure RPC visibility model.
-- These predicates are intentionally boolean-only and expose no secret values.

create function private.can_view_completed_round(
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

create function private.can_view_vote_row(
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

drop policy if exists "Round participants can view completed rounds" on public.rounds;
create policy "Round participants can view completed rounds"
on public.rounds for select to authenticated
using (private.can_view_completed_round(id, phase));

drop policy if exists "Participants can view authorized votes" on public.votes;
create policy "Participants can view authorized votes"
on public.votes for select to authenticated
using (private.can_view_vote_row(round_id, voter_player_id));
