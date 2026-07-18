-- Account deletion must not be blocked by historical rounds that reference
-- the deleted player as the imposter. Preserve the round row while removing
-- the deleted player's identity from that historical reference.

alter table public.rounds
  alter column imposter_player_id drop not null;

alter table public.rounds
  drop constraint rounds_imposter_player_id_fkey;

alter table public.rounds
  add constraint rounds_imposter_player_id_fkey
  foreign key (imposter_player_id)
  references public.players(id)
  on delete set null;
