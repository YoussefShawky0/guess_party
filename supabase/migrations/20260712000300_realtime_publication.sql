-- Exact authoritative supabase_realtime membership. round_participants is
-- intentionally excluded: clients receive participant_ids from the secure
-- get_round_for_player_v2 RPC and subscribe only to round_revisions.

alter publication supabase_realtime set table
  public.characters,
  public.hints,
  public.messages,
  public.players,
  public.rooms,
  public.round_revisions,
  public.rounds,
  public.votes;
