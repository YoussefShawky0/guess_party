<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read
`specs/001-gameplay-stability-fixes/plan.md` and
`.specify/memory/constitution.md`.
<!-- SPECKIT END -->

Guess Party changes must preserve gameplay integrity first: keep Online Mode
and Shared-Device Mode separate, route authoritative online state through Supabase, and
avoid unsafe BuildContext or navigation usage after async gaps.
