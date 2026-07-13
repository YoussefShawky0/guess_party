# Guess Party

Guess Party is a Flutter multiplayer social-deduction game with Online Mode
and connected Shared-Device Mode, both powered by Supabase. Shared-Device Mode
uses pass-and-play role reveal and voting on one device and requires an internet
connection and an authenticated session.

Architecture and implementation are governed by
`.specify/memory/constitution.md`. Planning and code changes must preserve the
core game flow, keep Online and Shared-Device modes separate, treat Supabase as the
authoritative source for online state, and protect hidden role information.
