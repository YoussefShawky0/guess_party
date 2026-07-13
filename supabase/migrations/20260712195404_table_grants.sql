-- Exact table ACLs captured read-only from the production Supabase project.
-- RLS remains enabled and authoritative for Data API row access.

grant all privileges on table
  public.categories,
  public.characters,
  public.hints,
  public.messages,
  public.players,
  public.rooms,
  public.rounds,
  public.votes
to anon, authenticated, service_role;

grant select on table
  public.round_participants,
  public.round_revisions
to authenticated;

grant all privileges on table
  public.round_participants,
  public.round_revisions
to service_role;
