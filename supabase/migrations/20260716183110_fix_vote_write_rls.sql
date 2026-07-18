-- Active rounds are intentionally hidden from raw SELECT access. The original
-- vote write policies queried those RLS-protected rows as the caller, so valid
-- inserts/updates could not see the active voting round and were rejected.
-- Keep the boolean authorization lookup in the private schema and retain the
-- existing raw vote redaction policy unchanged.

create or replace function private.can_write_vote(
  p_round_id uuid,
  p_voter_player_id uuid,
  p_voted_player_id uuid
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
      join public.round_participants voter_rp
        on voter_rp.round_id = r.id
       and voter_rp.player_id = p_voter_player_id
      join public.round_participants target_rp
        on target_rp.round_id = r.id
       and target_rp.player_id = p_voted_player_id
      join public.players voter on voter.id = voter_rp.player_id
      where r.id = p_round_id
        and r.phase = 'voting'
        and (
          (
            rm.game_mode = 'online'
            and voter.user_id = (select auth.uid())
          )
          or (
            rm.game_mode = 'local'
            and exists (
              select 1
              from public.players host
              where host.room_id = r.room_id
                and host.user_id = (select auth.uid())
                and host.is_host is true
                and rm.host_id = host.user_id
            )
          )
        )
    );
$$;

revoke execute on function private.can_write_vote(uuid, uuid, uuid)
from public, anon, authenticated, service_role;
grant usage on schema private to authenticated;
grant execute on function private.can_write_vote(uuid, uuid, uuid)
to authenticated, postgres, service_role;

drop policy if exists "Participants can submit valid votes" on public.votes;
create policy "Participants can submit valid votes"
on public.votes for insert to authenticated
with check (
  private.can_write_vote(round_id, voter_player_id, voted_player_id)
);

drop policy if exists "Participants can update valid votes" on public.votes;
create policy "Participants can update valid votes"
on public.votes for update to authenticated
using (
  private.can_write_vote(round_id, voter_player_id, voted_player_id)
)
with check (
  private.can_write_vote(round_id, voter_player_id, voted_player_id)
);
