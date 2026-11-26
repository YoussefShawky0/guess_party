# 004: Retention (sounds and haptics, stats and badges, analytics)

Branch: `feat/retention`. Three parts, built in order A → B → C, one commit each.
Read `AGENTS.md` and `specs/003-play-again/spec.md` (the "Rules for implementers"
section) first. The same rules apply here.

## Rules for implementers (all parts)

- Keep Online and Shared-Device mode separate. Never add authoritative game state on the client.
- No `BuildContext` use after an `await` without a `mounted` check.
- Code style: follow the nearest existing file. Cubits take dependencies in the constructor, and DI goes in `lib/core/di/injection_container.dart`.
- Every user-visible string goes in `lib/l10n/app_en.arb` **and** `lib/l10n/app_ar.arb` (Egyptian-friendly Modern Standard Arabic, like the existing keys). Then run `flutter gen-l10n`.
- Tests: use hand-written fakes, not mocktail. Every pure function and cubit gets unit tests.
- Every service that touches a platform (audio, haptics, Firebase) has an interface plus a silent/no-op implementation. Tests and CI use the no-op one. The app must build and run when the platform piece is missing.
- None of these features may ever throw into gameplay. Catch errors and report them with the existing Sentry pattern (see `google_interstitial_ad_service.dart`).
- The app is used in RTL. Use `EdgeInsetsDirectional` and `AlignmentDirectional`; for arrows, use `DirectionalFaIcon`.
- Shell for flutter on this machine (PowerShell):
  `$env:PUB_CACHE='D:\pub_cache'; $env:TEMP='D:\pub_cache\tmp'; $env:TMP='D:\pub_cache\tmp'`
- Use lean-ctx `ctx_*` tools for reading and searching. Native Grep and Glob are denied.
- Done means `flutter analyze` reports "No issues found!" and `flutter test` passes. Do not commit or push; the lead does that.

## Part A: Sounds and haptics

**Goal:** every round feels alive. Play a short sound plus a vibration at key moments, and give players two toggles in Settings.

### Cues (`enum GameCue`)
| Cue | When | Haptic |
|---|---|---|
| `tick` | each of the last 5 seconds of a timed phase (5,4,3,2,1) | `HapticFeedback.selectionClick` |
| `phaseStart` | a new phase begins (hints → voting → results, next round) | `mediumImpact` |
| `voteCast` | the current player's vote was accepted | `lightImpact` |
| `imposterCaught` | results revealed and the impostor was caught | `heavyImpact` |
| `imposterEscaped` | results revealed and the impostor escaped | `heavyImpact` |
| `gameWon` | game over and the current player has the top score (online), or any game end in shared-device mode | `heavyImpact` |
| `gameLost` | game over and the current player does not have the top score (online only) | `mediumImpact` |

### Design
- `lib/core/services/game_feedback.dart`:
  - `abstract class GameFeedback { bool get soundEnabled; bool get hapticsEnabled; Future<void> setSoundEnabled(bool); Future<void> setHapticsEnabled(bool); Future<void> play(GameCue cue); }`
  - `SilentGameFeedback` (no-op; toggles kept in memory).
  - `play` never throws.
- `lib/core/data/device_game_feedback.dart`:
  - Uses `audioplayers` (add the latest stable version) and `HapticFeedback`.
  - Stores the toggles in `SharedPreferences` under keys `feedback.sound_enabled` and `feedback.haptics_enabled`. Both default to `true`.
  - Audio must **mix with other apps**: do not take audio focus, and do not stop the user's music. Set a global `AudioContext` with Android `audioFocus: AndroidAudioFocus.none`, `usageType: AndroidUsageType.game`, and iOS category `ambient`.
  - Preload the players at startup (a small pool, one `AudioPlayer` per cue, `PlayerMode.lowLatency`).
- Pure mapping, unit tested, in `lib/features/game/presentation/feedback/game_cues.dart`:
  `List<GameCue> cuesForTransition(GameState? previous, GameState next)` (the cubit `GameState` from `game_cubit.dart`).
  - It covers phase changes, imposter reveal (caught vs escaped: use what the results phase content already shows; find where caught/escaped is decided in the UI and reuse that logic, do not invent new logic), and `GameEnded` (win/lose by top score; shared-device always `gameWon`).
  - Reconnect re-emits (`isReconnecting`, same phase, same round) must produce **no** cues.
- `voteCast`: fire it from the place where the vote submit succeeds (cubit success path or the vote UI callback). Do not fire it on optimistic taps that later fail.
- `tick`: `PhaseTimerWidget` gets an optional `ValueChanged<int>? onSecond` callback. The game screen passes one that plays `tick` when `1 <= remaining <= 5`. No DI lookups inside the timer widget.
- Provide `GameFeedback` with a `RepositoryProvider` above `MaterialApp.router` (find where `ThemeCubit`/`LocaleCubit` are provided). Widgets read it from context.
- A `GameFeedbackListener` widget (BlocListener on `GameCubit`) wraps both the online and the shared-device game content and calls `cuesForTransition`.
- Settings: two `SettingsTile` switches, "Sound effects" and "Vibration", in the same section style as the existing tiles.

### Sound assets
- Generate them; do not download anything. Add `tool/generate_sounds.py` (Python 3 stdlib only: `wave`, `math`, `struct`). It writes 7 short mono 44.1 kHz 16-bit WAV files to `assets/sounds/` (`tick.wav`, `phase_start.wav`, `vote_cast.wav`, `imposter_caught.wav`, `imposter_escaped.wav`, `game_won.wav`, `game_lost.wav`).
  - Use simple sine/triangle tones with attack/decay envelopes, 60–900 ms, peak about -6 dBFS, no clicks (fade in and out).
  - Tone ideas: caught = rising major arpeggio, escaped = sly descending minor, won = short fanfare, lost = soft two-note fall, tick = short woodblock-like blip.
- Commit the generated files, and register `assets/sounds/` in `pubspec.yaml`.

### Tests
- `cues_for_transition_test.dart`: every row of the table, reconnect gives no cues, and the first emission (null previous) gives no tick or phaseStart spam beyond `phaseStart` for the first phase.
- A `DeviceGameFeedback` toggle-persistence test with `SharedPreferences.setMockInitialValues`, behind a fake player seam (inject a `CuePlayer` interface so tests don't touch audioplayers).
- Settings widget test: the toggles call the service.

## Part B: Player stats and badges

**Goal:** a reason to come back. Lifetime stats plus unlockable badges, and a "New badge!" moment on Game Over.

### Server (already done by the lead, applied live)
`public.get_my_stats()` returns jsonb:
`{games_played, games_won, rounds_played, rounds_as_imposter, imposter_escapes, correct_votes}` (all ints).
- It counts finished games in both modes for `games_played` and `rounds_played`; the other four are Online-only (changed by `20261125000000_player_stats_shared_device.sql`, since Shared-Device seats are not people). It raises `AUTH_REQUIRED` (28000) with no session.
- Migration: `supabase/migrations/20261124000500_player_stats.sql`. Test: `supabase/tests/player_stats_contracts.test.sql`. Do not edit either.

### App
- New feature folder `lib/features/stats/` (data / domain / presentation like the others).
  - `PlayerStats` entity (6 ints, `PlayerStats.empty`), plus model parsing from the jsonb (missing key → 0).
  - `StatsRepository.getMyStats()` → `Either<Failure, PlayerStats>` via `rpc('get_my_stats')`, using the same error mapping as the room repository.
- Badges are pure and unit tested: `lib/features/stats/domain/badges.dart`.
  - `enum BadgeId { firstGame, regular, veteran, champion, masterOfDisguise, detective }`.
  - Targets: firstGame = 1 game, regular = 10 games, veteran = 50 games, champion = 10 wins, masterOfDisguise = 5 escapes, detective = 20 correct votes.
  - `List<BadgeProgress> evaluateBadges(PlayerStats s)`, where `BadgeProgress` has `id, current, target, unlocked`, and `current` is capped at `target`.
  - `Set<BadgeId> newlyUnlocked(Set<BadgeId> seen, List<BadgeProgress> now)`.
- Seen badges are stored in `SharedPreferences` key `stats.seen_badges` (a list of names) through a small `SeenBadgesStore` interface plus an implementation.
- `PlayerStatsCubit`:
  - States: `StatsLoading` / `StatsLoaded(stats, badges, newBadges)` / `StatsFailed(code)`.
  - `load()` fetches stats, evaluates the badges, computes `newBadges` against the seen store, then marks them seen.
- **Stats screen** at route `AppRoutes.stats` (`/stats`):
  - A header, a 2×3 grid of stat tiles (games, wins, rounds, as impostor, escapes, correct votes), and a badges grid. Locked badges are greyed out with a `current/target` progress bar; unlocked ones are colored.
  - Pull to refresh. Error state with retry (reuse `ErrorScreen` or the existing inline error widget).
  - **Guests** (anonymous, see how `home_view`/settings detect guests) see a card: "Create an account to keep your stats forever", which opens the existing account upgrade route.
  - Entry point: a tile/button on the Home screen near the existing actions, using the FontAwesome `chartSimple` or `trophy` icon.
- **Game Over (both modes)**: after the game ends, create a `PlayerStatsCubit` and `load()`. If `newBadges` is not empty, show a `NewBadgesCard` ("New badge unlocked!" with icons and names) above the actions. It must not delay the Play Again or Home buttons, and failures are silent. Shared-device Game Over shows the card too (games played unlock badges there).
- l10n: stat labels, badge names and descriptions ("Play your first game", ...), screen title, guest card, new-badge title.

### Tests
- Badges evaluation, caps, newlyUnlocked.
- Model parsing (including missing keys).
- The cubit with a fake repository and a fake store: new badges are computed then saved; the second load gives none.
- Stats screen widget test: loaded, guest card, error retry.
- Game Over shows the new-badge card for online and never for shared-device.

## Part C: Firebase Analytics

**Goal:** learn what players do: finished games, popular categories, drop-off points.

- Add `firebase_core` and `firebase_analytics` (latest stable). **No** `google-services` Gradle plugin and **no** `google-services.json`: initialize from dart-defines so CI and production builds without Firebase still compile.
- `AppConfig` gets optional `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, plus `bool get hasFirebase` (all four non-empty). Follow how `ADMOB_INTERSTITIAL_ID` / `SENTRY_DSN` are read and validated. Missing values are allowed in every environment.
  The lead has already put the dev values in `config/development.online.local.json` (gitignored). Never print or commit them.
- `lib/core/services/analytics_service.dart`:
  - `abstract class AnalyticsService { Future<void> log(AnalyticsEvent e); }` with a sealed `AnalyticsEvent` hierarchy (typed fields, `name`, `Map<String, Object> params`).
  - `NoopAnalyticsService`.
  - `lib/core/data/firebase_analytics_service.dart` wraps `FirebaseAnalytics.instance.logEvent`. It never throws; errors go to Sentry breadcrumbs only.
- Startup (`main.dart`/bootstrap): if `hasFirebase`, run `Firebase.initializeApp(options: FirebaseOptions(...))` inside try/catch, then register `FirebaseAnalyticsService`; otherwise (or on failure) use `NoopAnalyticsService`. Never block the first frame for more than the existing init does.
- **Privacy:** no usernames, room codes, user IDs, chat text or character names in any event.
  - Add `<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />` to the Android manifest.
  - Call `setAnalyticsCollectionEnabled(false)` when `APP_ENVIRONMENT` is `development` **unless** a new optional define `ANALYTICS_DEBUG=true` is set (the lead will set it locally).
- Events. Log them at the authoritative success point (after the server call succeeds), never in `build()`:
  - `game_started {mode, category, players, rounds}`: when the game actually starts (countdown done / first round loaded, once per room).
  - `game_finished {mode, category, rounds}`: `GameEnded` reached.
  - `game_left_early {mode, phase}`: the player leaves via the leave-game dialog.
  - `room_created {mode, category}`, `room_joined {}`.
  - `rematch_started {mode}`, `rematch_invite_answered {accepted}`.
  - `stats_viewed {}`, `badge_unlocked {badge}`.
- Inject `AnalyticsService` into the cubits that own these moments (optional constructor param defaulting to `const NoopAnalyticsService()`, so existing tests keep compiling), or use a listener widget where no cubit owns the moment.
- Tests: event param maps (no PII keys), config `hasFirebase` parsing, and one cubit test per event family with a recording fake.
