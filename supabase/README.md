# Local Supabase Development

Prerequisites: a Docker-compatible container runtime and the Supabase CLI.

```powershell
supabase start
supabase db reset
supabase db diff --local
supabase db advisors
supabase test db
```

Use the local API URL and publishable key printed by `supabase status` in the
Flutter development configuration. Never put a secret/service-role key in a
Flutter asset or client build.

The migration chain was rebuilt from the complete authoritative production
schema, routine ACL, and Realtime publication exports. Before pushing to a
remote environment, require a clean reset, passing database contracts, an empty
schema diff, and clean database/security advisors.
