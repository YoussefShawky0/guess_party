# Supabase Migration Manifest

## Authority

The canonical migration chain is deployable from a clean Supabase database and
is derived exclusively from the authoritative production exports supplied on
12 July 2026:

1. `full_schema_dump.sql` — schemas, functions, tables, defaults, constraints,
   indexes, triggers, RLS enablement, and policies.
2. Production routine-grant export — exact execution ACLs for `public` and
   `private`, including both `mark_stale_players_offline` overloads.
3. Production `supabase_realtime` publication export.
4. Read-only production table-ACL inventory captured after the initial clean
   reset exposed that the schema-only dump omitted table privileges.

The two confirmed information leaks in the production export are intentionally
corrected in the canonical schema:

- `Room members can view rounds legacy` is replaced by
  `Round participants can view completed rounds`.
- `Anyone can view votes` is replaced by
  `Participants can view authorized votes`.

## Canonical Order

| Migration | Responsibility |
|---|---|
| `20260712000100_production_schema.sql` | Complete production schema with corrected round/vote SELECT policies. |
| `20260712000200_routine_execution_grants.sql` | Exact production routine grants, with client access revoked by default. |
| `20260712000300_realtime_publication.sql` | Exact Realtime table membership; deliberately excludes `round_participants`. |
| `20260712195404_table_grants.sql` | Exact production table privileges for `anon`, `authenticated`, and `service_role`. |
| `20260713015743_fix_recursive_secret_state_rls.sql` | Replaces recursive round/vote SELECT policy joins with boolean-only private predicates while preserving the approved visibility rules. |

## Legacy SQL Mapping

Files under `doc/schemas/` are historical references only and must never be
applied after the canonical chain.

| Legacy file | Canonical disposition |
|---|---|
| `supabase_schema.sql` | Superseded by the authoritative production schema migration. |
| `enable_realtime.sql` | Superseded by the exact Realtime publication migration. |
| `add_time_sync_function.sql` | `get_server_time` definition is in production schema; exact grants are separate. |
| `fix_timezone_trigger.sql` | Superseded by authoritative functions/triggers. |
| `fix_round_duration_constraint.sql` | Superseded by authoritative room constraints. |
| `fix_round_and_hints.sql` | Superseded by authoritative schema, triggers, and policies. |
| `fix_votes_duplicates.sql` | Superseded by authoritative vote constraints/indexes. |
| `fix_votes_constraints.sql` | Superseded by authoritative vote constraints/indexes. |
| `fix_hints_duplicates.sql` | Superseded by authoritative hint constraints/indexes. |
| `fix_messages_chat.sql` | Superseded by authoritative message schema and policies. |
| `add_round_scoped_messages.sql` | Superseded by authoritative message `round_id`, constraints, and indexes. |
| `add_dynamic_categories.sql` | Superseded by authoritative categories table and room category constraint. |
| `remove_mix_category.sql` | Superseded by authoritative category/room constraints; data cleanup is not schema. |
| `enforce_room_capacity.sql` | Superseded by authoritative capacity function, trigger, and constraints. |
| `fix_player_presence_cleanup.sql` | Superseded by both authoritative stale-player RPC overloads. |
| `fix_host_migration_and_room_cleanup.sql` | Superseded by authoritative reconciliation functions and trigger. |
| `fix_rls_performance.sql` | Superseded by authoritative production policies plus the two security corrections. |
| `fix_votes_rls_policy.sql` | Superseded; its broad vote SELECT policy is intentionally not preserved. |
| `debug_queries.sql` | Excluded: diagnostics, not deployable schema. |

## Verification Contract

- `supabase/tests/database_contracts.test.sql` checks required tables/RPCs and
  rejects restoration of either broad SELECT policy.
- `supabase/tests/gameplay_security_contracts.test.sql` exercises authenticated
  RLS, host authorization, redaction, shared-device reveal access, capacity,
  uniqueness, self-voting, and score-finalization idempotency transactionally.
- `supabase/tests/presence_lifecycle_contracts.test.sql` exercises heartbeat
  freshness, deterministic host migration, former-host reconnect behavior,
  near-simultaneous presence changes, stale cleanup isolation, and empty-room
  completion transactionally.
- Production table ACLs grant the Data API roles access to the exposed tables;
  RLS policies remain the row-authorization boundary. `round_participants` and
  `round_revisions` deliberately expose only `SELECT` to `authenticated` and no
  privileges to `anon`.
- `round_participants` is not in Realtime because the Flutter client does not
  subscribe to it; `get_round_for_player_v2` returns `participant_ids`.
- Existing migration files are immutable after deployment. Future changes must
  be added as new migrations created through the Supabase CLI.
