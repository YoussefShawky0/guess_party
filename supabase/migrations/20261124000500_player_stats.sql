-- Lifetime stats for the signed-in player, computed from finished Online
-- games. Shared-Device games are left out: one account plays every seat,
-- so wins and votes there do not belong to a person.
--
-- "Caught" mirrors finalize_voting: the impostor is caught when they hold
-- the single highest vote count (no tie at the top).

create index if not exists idx_players_user on public.players (user_id);

create or replace function public.get_my_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  with me as (
    select p.id as player_id, p.room_id, coalesce(p.score, 0) as score
    from public.players p
    join public.rooms r on r.id = p.room_id
    where p.user_id = v_user_id
      and r.status = 'finished'
      and r.game_mode = 'online'
  ),
  room_top as (
    select p.room_id, max(coalesce(p.score, 0)) as top_score
    from public.players p
    where p.room_id in (select room_id from me)
    group by p.room_id
  ),
  my_rounds as (
    select rd.id as round_id, rd.imposter_player_id, m.player_id
    from me m
    join public.round_participants rp on rp.player_id = m.player_id
    join public.rounds rd on rd.id = rp.round_id
    where rd.scores_finalized_at is not null
  ),
  vote_counts as (
    select v.round_id, v.voted_player_id, count(*)::integer as votes
    from public.votes v
    where v.round_id in (select round_id from my_rounds)
    group by v.round_id, v.voted_player_id
  ),
  my_imposter_rounds as (
    select
      mr.round_id,
      coalesce((
        select vc.votes from vote_counts vc
        where vc.round_id = mr.round_id
          and vc.voted_player_id = mr.imposter_player_id
      ), 0) as imposter_votes,
      coalesce((
        select max(vc.votes) from vote_counts vc
        where vc.round_id = mr.round_id
      ), 0) as top_votes
    from my_rounds mr
    where mr.imposter_player_id = mr.player_id
  ),
  imposter_outcomes as (
    select
      ir.round_id,
      ir.top_votes > 0
        and ir.imposter_votes = ir.top_votes
        and (
          select count(*) from vote_counts vc
          where vc.round_id = ir.round_id
            and vc.votes = ir.top_votes
        ) = 1 as caught
    from my_imposter_rounds ir
  )
  select jsonb_build_object(
    'games_played', (select count(*) from me),
    'games_won', (
      select count(*) from me m
      join room_top t on t.room_id = m.room_id
      where t.top_score > 0 and m.score = t.top_score
    ),
    'rounds_played', (select count(*) from my_rounds),
    'rounds_as_imposter', (select count(*) from imposter_outcomes),
    'imposter_escapes', (select count(*) from imposter_outcomes where not caught),
    'correct_votes', (
      select count(*) from public.votes v
      join my_rounds mr
        on mr.round_id = v.round_id
       and v.voter_player_id = mr.player_id
       and v.voted_player_id = mr.imposter_player_id
    )
  )
  into v_result;

  return v_result;
end;
$$;

revoke all on function public.get_my_stats() from public, anon;
grant execute on function public.get_my_stats() to authenticated;
