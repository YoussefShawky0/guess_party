# Phase 10 Preflight — Staging Supabase Migration Promotion

## Purpose

Prepare a controlled staging-only path for promoting the committed canonical
Supabase migrations. This document is preparation, not authorization to modify
production.

## Current Local State

| Item | Status |
|---|---|
| Git working tree before preflight | Clean |
| Supabase CLI | `2.109.1` |
| Canonical migration files | 6 SQL files under `supabase/migrations/` |
| Seed file | `supabase/seed.sql`, idempotent categories/characters seed using `ON CONFLICT` |
| Local test command | `supabase test db` |
| Production Supabase | Not touched |

## Migration Chain to Promote

| Order | Migration |
|---:|---|
| 1 | `20260712000100_production_schema.sql` |
| 2 | `20260712000200_routine_execution_grants.sql` |
| 3 | `20260712000300_realtime_publication.sql` |
| 4 | `20260712195404_table_grants.sql` |
| 5 | `20260713015743_fix_recursive_secret_state_rls.sql` |
| 6 | `20260713185018_chat_security_and_reliability.sql` |

## Required Staging Inputs

Do not run a remote migration until the owner provides and confirms:

- staging Supabase project ref;
- staging database password or percent-encoded DB URL;
- staging publishable key for app smoke testing;
- confirmation that the target is staging, not production;
- permission to write to the staging database only.

## Safe Staging Promotion Sequence

Use a staging DB URL to avoid accidentally using a previously linked production
project.

```powershell
$env:STAGING_SUPABASE_DB_URL = "<percent-encoded-staging-db-url>"
```

Confirm the target without printing secrets:

```powershell
if (-not $env:STAGING_SUPABASE_DB_URL) {
  throw "STAGING_SUPABASE_DB_URL is not set."
}
```

Inspect migration history:

```powershell
supabase migration list --db-url $env:STAGING_SUPABASE_DB_URL
```

Preview the migration set without applying it:

```powershell
supabase db push `
  --db-url $env:STAGING_SUPABASE_DB_URL `
  --include-all `
  --include-seed `
  --dry-run
```

Only after reviewing the dry-run output, apply to staging:

```powershell
supabase db push `
  --db-url $env:STAGING_SUPABASE_DB_URL `
  --include-all `
  --include-seed
```

Then verify staging with read-only/schema-safe checks:

```powershell
supabase migration list --db-url $env:STAGING_SUPABASE_DB_URL
```

Run the app against staging using a Phase 9 staging define file stored outside
Git:

```powershell
dart run tool/validate_dart_defines.dart $env:STAGING_DEFINE_FILE
flutter run --flavor staging --dart-define-from-file=$env:STAGING_DEFINE_FILE
```

## Post-Promotion Staging Smoke Test

Verify the real API/Auth/PostgREST path against staging:

1. create a guest or test account;
2. create a room using a seeded category;
3. join from a second authenticated session;
4. start the game;
5. submit hints and votes;
6. finalize voting;
7. create the next round;
8. finish the game;
9. send/list/report/mute chat messages;
10. confirm no raw round/vote secrets are readable before results.

## Explicit Production Guard

- Do not run `supabase link` to a production project during this preflight.
- Do not run `supabase db push --linked` unless the linked project has been
  independently confirmed as staging.
- Do not use production DB URLs, production publishable keys, production Sentry
  DSNs, service-role keys, or dashboard SQL editor writes.
- Do not promote to production until staging passes and the user explicitly
  approves a production promotion step.

## Current Blockers Before Actual Staging Write

| Blocker | Owner |
|---|---|
| Staging Supabase project ref/DB URL | User/company owner |
| Staging app define file outside Git | User/company owner |
| Permission to write to staging | User/company owner |
| Staging smoke-test accounts | User/company owner |

