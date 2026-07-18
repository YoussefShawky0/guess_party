# Guess Party — Feature Inventory

## Table of Contents

- [Inventory Method and Status Definitions](#inventory-method-and-status-definitions)
- [1. Completed Features](#1-completed-features)
- [2. Existing but Needs Fixing](#2-existing-but-needs-fixing)
- [3. Potential and Recommended Additions](#3-potential-and-recommended-additions)

## Inventory Method and Status Definitions

This inventory was produced from the complete repository manifest and a trace of Flutter screens/widgets, Cubits, use cases, repositories, Supabase data sources, SQL scripts, platform configuration, dependencies, and tests. “Completed” means the feature has an end-to-end implementation path in the repository and no specific defect was found during static review; it does not imply exhaustive device or multi-client certification. Items with architectural, operational, edge-case, or validation gaps are listed under “Needs Fixing.”

Validation snapshot (11 July 2026): all 8 automated tests pass; static analysis reports 10 informational issues.

## 1. Completed Features

| Feature Name | Description | Status/Notes | File(s) Involved |
|---|---|---|---|
| Splash and session entry | Provides branded startup and routes users into auth/home flow. | Implemented. | `lib/shared/presentation/views/splash_screen.dart`, `lib/core/router/app_router.dart` |
| Anonymous guest authentication | Creates a Supabase anonymous session with username metadata. | Implemented; requires anonymous auth enabled in Supabase. | `lib/features/auth/**`, especially `data/datasources/auth_remote_data_source.dart` |
| Username/password accounts | Supports sign-up and sign-in using a username-derived synthetic email. | Implemented; account model limitations are listed below. | `lib/features/auth/presentation/views/login_view.dart`, `lib/features/auth/data/datasources/auth_remote_data_source.dart` |
| Sign-out and session-aware home | Reads the current Supabase user, displays a welcome state, and signs out. | Implemented. | `lib/features/home/**` |
| Room creation | Creates an idempotent server-side room session from category, rounds, duration, capacity, mode, host, and local names. | End-to-end RPC path implemented. | `lib/features/room/presentation/views/create_room_view.dart`, `lib/features/room/**/create_room.dart`, `room_remote_data_source.dart`, `doc/schemas/supabase_schema.sql` |
| Online room join | Finds a joinable room by code, validates it server-side, and creates player membership. | Implemented with friendly invalid-code handling. | `lib/features/room/presentation/views/join_room_view.dart`, `room_code_input.dart`, `join_room.dart`, `room_remote_data_source.dart` |
| Configurable game setup | Selects game mode, dynamic/fallback category, maximum rounds/players, and phase duration. | Implemented in create-room UI and RPC parameters. | `lib/features/room/presentation/views/widgets/game_mode_selector.dart`, `category_selector.dart`, `rounds_selector.dart`, `max_players_selector.dart`, `round_duration_selector.dart` |
| Shared-device player setup | Accepts multiple player names for shared-device sessions with input validation. | Implemented. | `lib/features/room/presentation/views/widgets/local_players_input.dart`, `create_room_view.dart` |
| Waiting room roster | Displays connected players, host marker, room code, and capacity. | Implemented with Realtime refresh. | `lib/features/room/presentation/views/waiting_room_view.dart`, `players_list.dart`, `waiting_room_body.dart` |
| Room-code sharing | Invokes the native share sheet with the room code. | Implemented via Share Plus. | `lib/features/room/presentation/views/widgets/share_room_button.dart` |
| Host-only game start | Host starts the room through a server RPC; non-host clients react to active room status. | Implemented; watcher/navigation regression tests pass. | `start_game_button.dart`, `room_status_listener.dart`, `room_cubit.dart`, `start_game.dart`, `waiting_room_view_test.dart` |
| Start countdown | Presents the transition from waiting room into the game. | Implemented. | `lib/features/room/presentation/views/countdown_view.dart`, `app_router.dart` |
| Online secure role delivery | Loads player-specific masked round snapshots so private character/Imposter data is not universally exposed. | Implemented; null-redaction tests pass. | `game_remote_data_source.dart`, `round_info_model.dart`, `round_info_model_redaction_test.dart`, secure SQL RPCs |
| Local pass-device role reveal | Sequentially reveals each shared-device player's role and clears sensitive reveal state before gameplay. | Implemented with a dedicated Cubit/view. | `local_role_reveal_view.dart`, `pass_device_screen.dart`, `local_role_reveal_cubit.dart`, `get_local_role_reveal_data.dart` |
| Character catalog and categories | Stores active characters with emoji/category/difficulty and supports dynamic category metadata. | Implemented in schema and character model/card. | `doc/schemas/supabase_schema.sql`, `add_dynamic_categories.sql`, `character*.dart`, `category_selector.dart` |
| Timed hints phase | Allows one hint per participant, persists via upsert, displays submitted hints, and advances on time/host action. | Implemented for online and shared-device gameplay. | `hints_phase_content.dart`, `submit_hint.dart`, `game_cubit.dart`, `game_remote_data_source.dart`, `hints` SQL policies/constraints |
| Profanity/input filtering | Screens relevant player-entered text using local validation/filtering. | Implemented as a client dependency/validation layer. | `pubspec.yaml`, `lib/core/utils/validators.dart`, auth/room/hint input widgets |
| Voting phase | Collects one vote per player, blocks self-voting, shows progress, and supports local target selection. | Implemented. | `voting_phase_content.dart`, `local_mode_game_screen.dart`, `submit_vote.dart`, `votes` SQL scripts |
| Atomic vote finalization and scoring | Server function finalizes once, reveals results, and returns updated integer scores. | Implemented with idempotency-aware result model. | `finalize_voting.dart`, `finalize_voting_result*.dart`, `game_remote_data_source.dart`, schema/fix SQL |
| Results and Imposter reveal | Shows vote counts, Imposter reveal, current scores, and round outcome. | Implemented. | `results_phase_content.dart`, `voting_results_card.dart`, `imposter_reveal_card.dart`, `current_scores_card.dart` |
| Multi-round progression | Creates the next round using expected round number protection and preserves scores. | Implemented. | `create_next_round.dart`, `game_cubit.dart`, `game_view.dart`, `local_mode_game_screen.dart` |
| Final leaderboard and podium | Sorts final scores and presents game-over rankings. | Implemented. | `game_over_view.dart`, `podium_widget.dart`, `leaderboard_list_widget.dart` |
| Host phase skip controls | Allows the authoritative host to move hints to voting and voting to results with confirmation. | Implemented through RPC-backed Cubit actions. | `game_view.dart`, `local_mode_game_screen.dart`, `advance_to_voting.dart`, `finalize_voting.dart` |
| Presence heartbeat | Updates online status and last-seen timestamps during room/game lifecycle. | Implemented. | `room_lifecycle_manager.dart`, `game_view.dart`, `update_player_status.dart`, `mark_stale_players_offline.dart` |
| Host migration and empty-room cleanup | Database reconciliation selects the oldest online player as host and finishes rooms with no active players. | Implemented in SQL and called by lifecycle paths; needs deeper integration testing. | `doc/schemas/fix_host_migration_and_room_cleanup.sql`, `fix_player_presence_cleanup.sql`, room/game lifecycle code |
| Reconnect state refresh | Re-establishes game subscriptions, reloads authoritative state, and displays connection status feedback. | Implemented. | `game_view.dart`, `game_cubit.dart`, round/player watchers |
| Room chat | Sends and displays room messages through Supabase with later round-scoping support. | Implemented in shared widget/schema. | `lib/shared/widgets/chat_widget.dart`, `doc/schemas/fix_messages_chat.sql`, `add_round_scoped_messages.sql` |
| Theme selection | Supports dark, light, and system theme and persists the choice. | Implemented; light mode is labeled Demo. | `lib/core/theme/**`, `lib/features/home/presentation/views/settings_view.dart` |
| How-to-play guide | Explains roles, hints, voting, and score rules in Settings. | Implemented. | `settings_view.dart` |
| App metadata and external links | Displays version and opens developer, source, and privacy-policy pages. | Implemented. | `settings_view.dart`, `package_info_plus`, `url_launcher` |
| Android in-app updates | Checks Play update availability and supports immediate/flexible update flows. | Implemented for Android. | `lib/core/services/update_service.dart`, `settings_view.dart`, `in_app_update` |
| Crash reporting | Captures Flutter, platform, and zoned uncaught errors and records lifecycle breadcrumbs. | Implemented when DSN is configured. | `lib/main.dart`, `lib/core/utils/error_handler.dart`, lifecycle/GameCubit files |
| Responsive layouts | Adapts numerous screens/widgets at tablet width breakpoints. | Implemented across room/game/settings views. | Presentation files under `lib/features/**/presentation` |

## 2. Existing but Needs Fixing

| Feature Name | Description | Status/Notes | File(s) Involved |
|---|---|---|---|
| Shared-Device connectivity messaging | The pass-and-play experience is intentionally Supabase-backed and requires auth/connectivity. | **Resolved direction.** User-facing and governance language must consistently call it connected Shared-Device Mode; internal `local` wire values remain for compatibility. | `game_mode_selector.dart`, `README.md`, constitution, Shared-Device game screens |
| Release-ready Android build | Permanent identity `com.youssefshawky.guessparty`, fail-closed signing, CI artifact verification, and an owner-backed upload keystore are configured. | Store publication still requires an approved Play Console owner and CI secret enrollment. | `android/app/build.gradle.kts`, `.github/workflows/release.yml`, `tool/configure_android_signing.ps1` |
| Reproducible backend deployment | Baseline and corrective SQL files are manually applied and have no tracked Supabase migration history. | **Environment drift risk.** Convert the effective schema to ordered `supabase/migrations`, add seed data and staging/prod promotion checks. | `doc/schemas/*.sql` |
| Clean Architecture enforcement | Several routes and widgets call `Supabase.instance.client` directly. | **Boundary violation.** Move route validation, presence, player lists, chat, and status watchers behind data sources/repositories/use cases. | `app_router.dart`, `game_view.dart`, `local_mode_game_screen.dart`, `players_list.dart`, `room_status_listener.dart`, `chat_widget.dart` |
| Async Settings dialogs/navigation | Analyzer reports four `use_build_context_synchronously` warnings after update checks. | **Potential disposed-context fault.** Guard the actual passed context with `context.mounted` or cache a safe navigator before awaiting. | `lib/features/home/presentation/views/settings_view.dart` |
| Supabase client-key initialization | Uses deprecated `anonKey` parameter and legacy environment naming. | **Upgrade debt.** Migrate to the current publishable-key API/name and keep only a public client key in the app bundle. | `lib/main.dart`, `.env` convention |
| Flutter color API compatibility | Five `withOpacity` calls are deprecated. | Replace with `withValues(alpha: ...)` and keep analyzer clean. | `phase_timer_widget.dart`, `results_phase_content.dart`, `round_header_widget.dart` |
| Automated gameplay coverage | Only eight tests exist; no full round, scoring, Shared-Device Mode, reconnect, host migration, RLS, or multi-client tests. | **Insufficient confidence for “100% working.”** Add Cubit/repository contract tests, local/online widget flows, Supabase integration tests, and two-client realtime scenarios. | `test/features/**`, all room/game layers |
| Host migration/cleanup verification | SQL and client hooks exist, but the behavior is not covered by automated database or multi-device tests. | Add concurrent disconnect, stale heartbeat, multiple-host prevention, and last-player cleanup tests against a disposable Supabase environment. | `fix_host_migration_and_room_cleanup.sql`, `fix_player_presence_cleanup.sql`, lifecycle widgets |
| Authentication identity and recovery | Username is converted to a synthetic email; no verification, password reset, or username-collision UX is present. | Define an account strategy. Prefer real verified email/OAuth for persistent accounts, or clearly scope accounts as non-recoverable aliases. | `auth_remote_data_source.dart`, `login_view.dart` |
| Chat hardening and UX | Chat exists, but no push delivery, moderation workflow, unread state, pagination, or automated RLS tests were found. | Add server-enforced length/rate limits, moderation/reporting, pagination, unread indicators, and policy tests. | `chat_widget.dart`, `fix_messages_chat.sql`, `add_round_scoped_messages.sql` |
| Localization | English and Arabic strings are hard-coded directly in widgets. | Introduce Flutter `gen_l10n`/ARB resources, define supported locales, and audit RTL layouts. | Presentation files, notably `hints_phase_content.dart` and settings/room/game views |
| Accessibility | Responsive sizing exists, but no semantics, screen-reader, contrast, or large-text test suite is present. | Add semantic labels, focus order, scalable layouts, contrast audit, and accessibility widget tests. | All presentation widgets; `app_theme.dart`, `app_colors.dart` |
| Production observability configuration | Sentry trace sampling is hard-coded to 100% and lacks explicit release/environment tags. | Make sampling environment-specific, tag builds, scrub contextual data, and document alert ownership. | `lib/main.dart`, `error_handler.dart` |
| Environment separation | A single bundled `.env` and no flavors are present. | Add dev/staging/prod entry points, separate Supabase/Sentry projects, and CI-injected public configuration. | `lib/main.dart`, `pubspec.yaml`, platform build files |
| Platform update parity | In-app update workflow is Android Play-specific; iOS/web/Windows have no equivalent update experience. | Gate the UI by supported platform and define App Store/web/desktop update behavior. | `update_service.dart`, `settings_view.dart` |
| Oversized gameplay views | Online game (1,228 lines) and Shared-device game (956 lines) combine lifecycle, navigation, subscriptions, dialogs, and rendering. | Extract coordinators/controllers and small phase views while preserving strict online/shared-device secret boundaries. | `game_view.dart`, `local_mode_game_screen.dart`, `settings_view.dart` |
| Realtime subscription ownership | Realtime logic is distributed across Cubit, views, route/listener widgets, and shared chat. | Consolidate subscription lifecycle, name channels consistently, and add duplicate-subscription/resource-disposal tests. | `game_cubit.dart`, `game_view.dart`, `players_list.dart`, `room_status_listener.dart`, `room_remote_data_source.dart` |
| Store/release automation | No CI workflow, Fastlane, store metadata, signing secret integration, or release checklist exists. | Add pull-request analysis/tests, signed build pipeline, artifact provenance, staged rollout, and rollback documentation. | Repository root, Android/iOS project files |
| Product metadata | Package description remains “A new Flutter project.” | Replace placeholder metadata and add ownership/support/release information. | `pubspec.yaml`, `README.md` |

## 3. Potential and Recommended Additions

| Feature Name | Description | Status/Notes | File(s) Involved |
|---|---|---|---|
| Friend invites and deep links | Open a specific room from a share link/QR rather than manually entering a code. | **Recommended.** Add universal/app links, expiring invite tokens, and safe join confirmation. | New router/link service; room repository/RPC; Android/iOS link configuration |
| QR room join | Generate and scan a room-code QR for in-person setup. | **Recommended.** Particularly useful for party onboarding. | New room presentation/service modules and camera permissions |
| Custom character packs | Let hosts create private character/category packs. | **Recommended with moderation.** Requires ownership, validation, RLS, and pack-selection UX. | New Supabase tables/RPCs and `features/packs/` module |
| Curated pack marketplace | Publish/version official or community packs with ratings and moderation. | Longer-term addition after custom packs and trust/safety controls. | New backend schema, storage, moderation, and discovery UI |
| Rejoin by room/session history | Surface a resumable active room after app restart. | **High-value addition.** Persist safe membership pointer and verify server-side membership/status. | New session repository, splash/home UI, room lookup RPC |
| Push notifications | Notify invited players or alert disconnected players that a game is starting. | Requires FCM/APNs, consent, token lifecycle, and privacy updates. | New notification service/backend functions/platform configs |
| Achievements and player statistics | Track games played, wins as Imposter/Innocent, streaks, and badges. | Add only with clear account identity and privacy controls. | New profile/stats tables, RPCs, and feature module |
| Match history and round recap | Show prior games, characters, votes, and score changes. | Preserve hidden information until the game ends; define retention. | New history views and archive/read-model schema |
| Replay/highlight cards | Generate shareable end-game summaries without exposing sensitive identifiers. | Social-growth feature; export image/card from final results. | New share-card widget/service; game-over integration |
| Host moderation | Kick/mute players, lock room, regenerate code, or transfer host intentionally. | Server-authoritative controls and audit events required. | New room RPCs/policies and waiting-room controls |
| Spectator mode | Allow non-voting viewers after a round starts. | Requires a distinct role and strict secret/RLS model. | Schema/RPC extensions plus spectator presentation flow |
| Team or variant rules | Multiple Imposters, teams, no-timer mode, custom scoring, or elimination variants. | Add via explicit versioned rule configuration, not client-only flags. | Room schema, round engine RPCs, setup and results UI |
| Imposter final guess | Let an identified Imposter guess the character for a comeback bonus. | Natural deduction-game extension; needs a new server phase and scoring rule. | Round phase model, RPCs, Cubit, and game widgets |
| Rematch with same group | Create a fresh session preserving player roster/settings. | Useful end-game retention feature; must rotate secrets and reset scores atomically. | Game-over UI and new room/rematch RPC |
| Voice chat | Optional low-latency voice channel for remote games. | High complexity/cost and moderation/privacy burden; evaluate after core reliability. | New RTC provider, permissions, moderation, and room UX |
| Accessibility modes | Color-blind palette, reduced motion, haptics controls, larger tap targets, and narrated role reveal. | Strongly recommended as a structured settings initiative. | Theme/settings system and all gameplay widgets |
| Formal localization | Full Arabic/English resource catalogs with runtime locale selection and RTL QA. | Recommended before wider regional launch. | ARB resources, localization delegates, settings UI |
| Abuse reporting and blocking | Report harmful usernames/chat, mute users, and retain auditable moderation evidence. | Required before broad public matchmaking/community packs. | New trust-and-safety schema/services and UI |
| Public/private matchmaking | Browse public lobbies or automatically match players by language/rules. | Requires rate limits, abuse prevention, region/latency handling, and scalable presence. | New matchmaking service/RPCs and lobby feature |
| Web admin console | Manage character packs, categories, reports, bans, and operational game health. | Recommended internal tool once user-generated content launches. | Separate secured admin application/private backend schema |
| Feature flags and remote config | Gradually release rules/UI and disable faulty features without a client update. | Use server-authorized flags with environment separation and audit history. | New configuration service/table and bootstrap integration |
| Product analytics | Measure funnel, room start success, round completion, reconnects, and retention. | Add privacy-conscious events; never record role secrets/chat content. | New analytics abstraction, consent/privacy updates |
