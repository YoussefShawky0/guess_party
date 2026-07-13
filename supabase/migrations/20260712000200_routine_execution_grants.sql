-- Authoritative routine ACLs exported from production.
-- Revoke PostgreSQL's default PUBLIC execution before applying the exact list.

revoke execute on all functions in schema public from public, anon, authenticated, service_role;
revoke execute on all functions in schema private from public, anon, authenticated, service_role;

-- Authenticated command/read RPCs; postgres and service_role retain execution.
grant execute on function public.advance_to_voting(uuid) to authenticated, postgres, service_role;
grant execute on function public.create_next_round(uuid, integer) to authenticated, postgres, service_role;
grant execute on function public.create_room(uuid, text, integer, integer, integer, text, text, text[]) to authenticated, postgres, service_role;
grant execute on function public.extend_local_role_reveal(uuid, integer) to authenticated, postgres, service_role;
grant execute on function public.finalize_voting(uuid, text) to authenticated, postgres, service_role;
grant execute on function public.find_joinable_room(text) to authenticated, postgres, service_role;
grant execute on function public.finish_game(uuid) to authenticated, postgres, service_role;
grant execute on function public.get_current_round_id(uuid) to authenticated, postgres, service_role;
grant execute on function public.get_local_role_reveal_bundle(uuid) to authenticated, postgres, service_role;
grant execute on function public.get_round_for_player(uuid) to authenticated, postgres, service_role;
grant execute on function public.get_round_for_player_v2(uuid) to authenticated, postgres, service_role;
grant execute on function public.get_vote_state(uuid) to authenticated, postgres, service_role;
grant execute on function public.join_room(text, text) to authenticated, postgres, service_role;
grant execute on function public.mark_stale_players_offline(integer) to authenticated, postgres, service_role;
grant execute on function public.mark_stale_players_offline(uuid, integer) to authenticated, postgres, service_role;
grant execute on function public.start_game(uuid) to authenticated, postgres, service_role;

-- Intentionally public server clock endpoint, matching production exactly.
grant execute on function public.get_server_time() to public, anon, authenticated, postgres, service_role;

-- Trigger/maintenance functions are not callable by client roles.
grant execute on function public.create_first_round() to postgres, service_role;
grant execute on function public.enforce_room_capacity() to postgres, service_role;
grant execute on function public.handle_player_presence_change() to postgres, service_role;
grant execute on function public.reconcile_room_after_presence_change(uuid) to postgres, service_role;

-- Private helpers are postgres-only.
grant execute on function private.bump_revision_from_child() to postgres;
grant execute on function private.bump_round_revision(uuid) to postgres;
grant execute on function private.capture_round_state() to postgres;
grant execute on function private.create_round_for_room(uuid, integer) to postgres;
grant execute on function private.is_current_host(uuid, uuid) to postgres;
grant execute on function private.is_room_member(uuid, uuid) to postgres;
grant execute on function private.lock_room(uuid) to postgres;
grant execute on function private.prevent_room_mode_change() to postgres;
