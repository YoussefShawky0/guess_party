-- Phase 11 account deletion contract.
-- The caller's authenticated UID is the only deletion key. Usernames and
-- display names are intentionally not used for authorization.

create or replace function public.delete_current_account()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  -- Mark memberships offline first so the existing presence trigger can
  -- migrate host authority or finish empty rooms before rows are removed.
  update public.players
  set is_online = false,
      last_seen_at = now()
  where user_id = v_user_id
    and is_online is true;

  -- Child gameplay/chat/moderation rows are removed by their existing player
  -- foreign-key cascades. Room rows remain and are reconciled by presence.
  delete from public.players
  where user_id = v_user_id;

  -- This is the only Auth deletion operation and preserves no reusable UID.
  delete from auth.users
  where id = v_user_id;
end;
$$;

revoke execute on function public.delete_current_account() from public, anon;
grant execute on function public.delete_current_account() to authenticated;
