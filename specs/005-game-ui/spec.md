# 005: Game UI design system and Home redesign

Final spec. Agreed between the lead and a reviewer from `draft.md`; the debate decisions are folded in below.
Branch: `feat/retention` (on top of 004).

## Rules for implementers
- Follow the "Rules for implementers" sections of `specs/003-play-again/spec.md` and `specs/004-retention/spec.md` (lean-ctx tools only, the PowerShell env prefix for flutter, en+ar l10n, hand-written fakes, no commits).
- AGENTS.md:
  - No `BuildContext` use after `await` without a `mounted` check.
  - Online and Shared-Device stay separate.
- **No logic changes** on screens that only get a visual swap. Every `onPressed` condition, loading state and navigation call stays byte-for-byte the same.
- RTL: use `EdgeInsetsDirectional` and `AlignmentDirectional`, and `DirectionalFaIcon` for arrows.
- Done means `flutter analyze` reports "No issues found!" and every test passes.

## Fixed product decisions
- Game-style look, few buttons. Baloo Bhaijaan 2 for headings and buttons. Animated background of faint drifting icons.
- Settings stays in the top bar. Logout and stats leave the top bar and the body. The secure-account feature stays but leaves the Home body.

## 1. Font and tokens
- `pubspec.yaml` `flutter.fonts`: family `BalooBhaijaan2`, asset `assets/fonts/BalooBhaijaan2-Variable.ttf`.
- Apply Baloo **only** through `textTheme` slots: `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `titleLarge`, `labelLarge` (buttons). Set the weight with `fontVariations: [FontVariation('wght', 700 or 800)]` and also set `fontWeight` to match. Body styles keep the default font. Do this for both the light and dark themes in `app_theme.dart`.
- `lib/core/design/game_tokens.dart`: a `GameTokens` `ThemeExtension` with light and dark instances registered in both themes, plus a `GameTokens.of(context)` accessor.
  - spacing: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32
  - radius: sm 10, md 16, lg 24, pill 999
  - button: `depth` 5 px resting / 1 px pressed, `minHeightLg` 56, `minHeightMd` 48
  - motion: fast 120 ms, base 220 ms, slow 400 ms, plus `bounce = Curves.easeOutBack`
  - reward: gold `#F5B83D`, edge `#B7811A` (the trophy chip)
  - The button face/edge colors per variant are derived from the existing `AppColors`. Add new colors; don't rename existing ones.

## 2. Components (`lib/shared/design/`)
- **`GameButton`**:
  - `variant`: primary | secondary. `size`: lg | md. Plus `icon`, `label`, `onPressed` (null = disabled look), `isLoading`.
  - Chunky with a darker bottom edge. On press it translates down by `depth - pressedDepth` and the edge shrinks (`motion.fast`).
  - `minHeight` is a **minimum**: the label may wrap to 2 lines, and the button grows with the text scale.
  - On tap it calls `GameFeedback.tapHaptic()`.
  - `Semantics(button: true, label: label)`, with focus/pressed states visible (keyboard/TalkBack focus ring).
- **`GameChip`**: a pill with icon, label and `onTap`, plus an optional `semanticLabel` (button role).
- **`GameIconButton`**: a round 44 px button with a required `tooltip`/semantic label.
- **`PlayerAvatar`**: initials in a circle. The color is chosen deterministically from a fixed palette by the username's hash. It has an optional `showDot` (warning-yellow dot).
- **`AnimatedGameBackground`**:
  - It wraps `child` and paints behind it.
  - One `AnimationController` (30 s loop), with about 14 faint FontAwesome glyphs (`circleQuestion`, `eye`, `masksTheater`, `userSecret`) drifting upward and wrapping, at low alpha from the theme.
  - The `TextPainter`s are laid out **once** and cached. Use `CustomPainter(repaint: controller)`, never `setState`, inside a `RepaintBoundary`.
  - **Static** (one frame, no ticking) when `MediaQuery.disableAnimations` is set.
  - Pauses when `TickerMode` is off, when the app lifecycle is not `resumed`, and after **60 s with no pointer input** (a `Listener` resumes it).
- **`GameFeedback.tapHaptic()`**: a new method on the interface. It does a light haptic only (no sound), respects `hapticsEnabled`, and never throws. Implement it in `DeviceGameFeedback` and `SilentGameFeedback`, and in the test fakes.

## 3. Home redesign
- The body is wrapped in `AnimatedGameBackground`.
- **Top bar** (`GameTopBar` or inline Row):
  - **Profile chip:** `PlayerAvatar` plus username. It shows the dot for guest or legacy accounts and opens `ProfileSheet`.
  - **Trophy chip** (gold): `unlocked/total` with total = `badges.length`. Semantics: "3 of 6 badges" (localized). It opens `/stats`. While unknown, it shows the trophy icon only.
  - **Settings** `GameIconButton`.
- **Trophy count source:** a new read-only `BadgeSummaryCubit` (or `PlayerStatsCubit.peek()`) that **never touches `SeenBadgesStore`**, so the Game Over "new badge" moment stays intact. Flow:
  - It shows the cached value from `SharedPreferences` first, under a key including the user id, e.g. `stats.summary.<userId>` → `{unlocked, total, gamesPlayed}`.
  - It then refreshes from `get_my_stats` in the background and updates the cache.
  - The cache is cleared on logout.
  - Failure keeps the cache, or shows nothing.
- **Hero:** the 3 existing character images with one shared gentle bob animation; the impostor is phase-offset. It is static under reduce-motion. Under it, the title "مين الإمبوستر؟" in `headlineMedium` (Baloo), localized.
- **Actions:** exactly two `GameButton.lg`: Create room (primary) and Join with code (secondary). Below them, a small "How to play" text button that calls the existing `showHowToPlayDialog`. Do not invent a route.
- **Guest banner:** a one-line dismissible banner, "Secure your account to keep your stats", that opens account upgrade. It shows only when the user is guest/legacy **and** the summary has `gamesPlayed > 0`. With no data, no banner. Dismissal is stored per user in prefs.
- **Removed:** the secure-account button, the stats text button, and the logout icon.

### ProfileSheet (modal bottom sheet)
- Avatar and name, then 3 mini stats from the summary (games, wins, badges `unlocked/total`). Hide the mini stats if there is no data.
- Rows:
  - "Secure your account" (guest/legacy only) → account upgrade
  - "My stats" → `/stats`
  - "Log out"
- **Logout flow** (AGENTS.md safe):
  - Capture `HomeCubit` and the router from the Home context before anything async. Close the sheet first.
  - For **non-guests**: call `signOutUser()` as today.
  - For **guests**, from the Home context, show a dialog:
    - Text: "You're playing as a guest. If you log out, you can't get this account or its stats back."
    - Primary: `GameButton` "Secure account" → account upgrade. Secondary: a plain `TextButton` "Log out anyway" (not danger-styled).
    - Barrier tap and back **cancel**; they never log out.
    - Check `mounted` before every post-await use of context.

## 4. Rollout (visual swap only)
- `AnimatedGameBackground` and `GameButton` on the main CTA only, on:
  - **Create room:** the submit button only. Keep the exact `onPressed: isLoading || _isCreateDisabled() ? null : _createRoom` and the loading spinner.
  - **Join room:** its join button.
  - **Waiting room:** the background goes **outside** the `BlocConsumer` (around `waiting_room_view.dart` ~L96) so realtime updates never rebuild it. Swap the host's Start button only, keeping its exact conditions.
    While in that file, localize the hard-coded `'Syncing your player...'` (~L146).
  - **Stats:** the background only.
- **Not touched:** gameplay round screens (hints/voting/results, role reveal, pass device), Game Over, auth screens, settings.

## 5. Docs
- `docs/design-system.md`, one page, no screenshots: tokens, components with usage, do/don't (one primary per screen, background never during rounds, no logic changes in visual swaps, reduce-motion rules).

## 6. Tests
- **Real fonts in widget tests:** a test helper that loads `BalooBhaijaan2-Variable.ttf` with `FontLoader('BalooBhaijaan2')` in `setUpAll`, used by the overflow tests.
- **`GameButton`:**
  - Press state changes the offset. `tapHaptic` is called once per tap, and not at all when disabled.
  - Semantics: button role plus label.
  - No overflow (`tester.takeException()` is null) at `textScaler` 1.0 and 2.0 in `ar` and `en`, with a long Arabic label.
- **`AnimatedGameBackground`:** with `disableAnimations: true`, no ticker is active (`tester.hasRunningAnimations` is false after pump). It pauses on lifecycle `paused`.
- **Home:**
  - Exactly two `GameButton`s.
  - No logout or secure-account widgets in the body.
  - The trophy chip shows the cached count, then the refreshed count, and its semantic label is "3 of 6 badges".
  - Guest banner: shown with `gamesPlayed > 0` for guests; hidden for full accounts and when there is no data.
- **ProfileSheet:**
  - Guest logout opens the dialog. Barrier tap cancels and `signOutUser` is not called. "Log out anyway" calls it. "Secure account" navigates.
  - A non-guest logs out directly.
- **Badge summary:**
  - It never calls `SeenBadgesStore`.
  - The cache is keyed by user and cleared on logout.
- **Rollout screens:** the existing tests still pass unchanged (proves no logic change).

## Follow-ups (not in this PR)
- A "Play again / last room" shortcut on Home.
- The design system on Game Over and the gameplay screens.
