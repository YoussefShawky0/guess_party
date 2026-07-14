# Guess Party

Guess Party is a Flutter multiplayer social-deduction game with Online Mode
and connected Shared-Device Mode, both powered by Supabase. Shared-Device Mode
uses pass-and-play role reveal and voting on one device and requires an internet
connection and an authenticated session.

For backward compatibility, the database and RPC mode identifier remains
`local`; this storage value does not mean the mode operates offline.

Architecture and implementation are governed by
`.specify/memory/constitution.md`. Planning and code changes must preserve the
core game flow, keep Online and Shared-Device modes separate, treat Supabase as the
authoritative source for online state, and protect hidden role information.

## Local development configuration

Runtime configuration is supplied through compile-time Dart defines, not a
bundled `.env` asset. Copy `config/development.local.example.json` to an
untracked local file, replace the publishable local Supabase key, and run:

```powershell
dart run tool/validate_dart_defines.dart config/development.local.json
flutter run --flavor development --dart-define-from-file=config/development.local.json
```

Only publishable client configuration belongs in Dart define files. Never add a
Supabase service-role/secret key, database password, auth token, signing secret,
or SMTP credential to application configuration.
