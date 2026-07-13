# Stabilization Plan Implementation Status

## Completed and Verified

- Phase 0 analyzer, async-context, color API, product metadata, and controlled
  configuration startup work.
- Supabase publishable-key initialization with a temporary legacy key fallback.
- App configuration and observability sampling tests.
- Authentication session reads removed from presentation behind an injected
  session service.
- Route room-status and create-room category queries removed from presentation
  behind an injected query service.
- Connected Shared-Device terminology and governance alignment while retaining
  the internal `local` database value.
- Android Play update UI is platform-gated.
- Sentry environment and configurable trace sampling.
- Android release builds no longer fall back to debug signing.
- Flutter CI and migration-asset CI definitions.
- Kotlin Gradle plugin upgraded to the currently required version.

## Candidate Backend Foundation

The legacy SQL was placed into an explicit candidate migration order with local
Supabase configuration, seed entrypoint, manifest, and pgTAP contract checks.
It is intentionally not marked deployable because the repository does not
contain definitions for multiple RPCs used by the client or the
`round_revisions` table.

## Blocked Gates

1. Obtain an authoritative schema export or remote `supabase db pull` from the
   currently working Supabase project.
2. Reconcile missing RPC/table definitions and run local reset, pgTAP tests,
   schema diff, and database advisors with the Supabase CLI and Docker.
3. Supply a company-owned Android application ID, iOS bundle ID/team, and
   signing credentials before release identity can be finalized.
4. Approve an account migration policy for existing synthetic-email accounts
   before replacing them with verified-email identities and password recovery.
5. Provide staging/production Supabase and Sentry project configuration before
   environment isolation can be end-to-end verified.

## Deferred Until Backend Contract Passes

- Realtime subscription consolidation and full gameplay-view decomposition.
- Host migration, cleanup, RLS, scoring, and multi-client integration tests.
- Chat policy/rate-limit/pagination migration.
- Full localization and accessibility conversion.

These changes touch authoritative gameplay/security behavior and must not be
implemented against an incomplete schema contract.
