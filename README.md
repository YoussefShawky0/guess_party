# Guess Party

Guess Party is a Flutter multiplayer social deduction game with Online Mode
powered by Supabase and Local Mode for shared-device offline play.

Architecture and implementation are governed by
`.specify/memory/constitution.md`. Planning and code changes must preserve the
core game flow, keep Online and Local modes separate, treat Supabase as the
authoritative source for online state, and protect hidden role information.
