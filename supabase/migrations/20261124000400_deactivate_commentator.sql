-- 'أندريس كانتور' is a football commentator, not a player, so he does not
-- belong in football_players. Deactivate rather than delete: past rounds
-- may still reference the row.
update public.characters
set is_active = false
where id = 'db46d948-3d4b-47d9-9aa4-f9bb30d403b7'::uuid;
