# 005: Game UI design system and Home redesign (DRAFT, for debate)

Status: draft by the lead. To be challenged by a reviewer, then turned into the final `spec.md`.

## Product decisions already made by the owner (not up for debate)
- **Look:** game-style, easy to use, few buttons.
- **Font:** Baloo Bhaijaan 2 for headings and big buttons. Already downloaded to `assets/fonts/BalooBhaijaan2-Variable.ttf` (variable `wght` 400–800) with `BalooBhaijaan2-OFL.txt`.
- **Background:** an animated background of faint drifting icons (question marks, eyes, masks) over the navy background.
- **Top bar:** settings stays. Logout and the stats button leave the top bar and the body (my proposal below).
- **"Secure guest account" button:** keep the feature, move it out of the Home body.

## Current state (facts)
- `AppColors` (static brand constants) plus `AppColorsTheme` (a ThemeExtension, read via `AppColors.of(context)`). Light and dark themes in `lib/core/theme/app_theme.dart`. The brand is navy/blue (`primary #3F72AF`, `background #0A1929`, `surface #112D4E`).
- Home today has 6 actions of similar weight: settings, logout, secure account, create, join, stats.
- 16 screens build their own buttons and cards inline. There is no shared component layer except `lib/shared/widgets/` (a few widgets).
- Sounds and haptics exist (`GameFeedback`, Part A of 004). Stats and badges exist (`/stats`, `PlayerStatsCubit`).

## Proposal

### 1. Tokens (`lib/core/design/`)
- `GameTokens` as a `ThemeExtension`, with light and dark values:
  - spacing: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32
  - radius: sm 10, md 16, lg 24, pill 999
  - button depth (bottom "3D" edge): 5 px resting, 1 px pressed
  - motion: fast 120 ms, base 220 ms, slow 400 ms, plus a bouncy curve (`Curves.easeOutBack`)
  - reward color: gold `#F5B83D` plus a dark edge `#B7811A` (for badges, the trophy chip and win states)
- Typography: `display` / `title` / `button` use Baloo Bhaijaan 2 (weights 700–800 via `FontVariation('wght', …)`). Body text stays on the current default font so long text reads well.
- Keep all existing `AppColors` values. Add, don't rename, so the 16 screens don't break.

### 2. Components (`lib/shared/design/`)
- `GameButton`:
  - Variants: primary, secondary, danger, reward. Sizes: lg, md.
  - Chunky with a darker bottom edge; it presses down on tap (it translates and the edge shrinks).
  - It plays a light haptic through `GameFeedback`, and has a loading state.
  - Min height 56 (lg) / 48 (md). Fully accessible (Semantics button, focus).
- `GamePanel`: a card with a rounded border and a subtle inner highlight.
- `GameChip`: a pill with an icon and a label (used for the trophy count and the profile).
- `GameIconButton`: a round 44 px button.
- `GameTopBar`: [profile chip] … [trophy chip] [settings].
- `PlayerAvatar`: initials in a colored circle (color derived from the username hash), with an optional dot badge.
- `AnimatedGameBackground`:
  - One `CustomPainter` with a single `AnimationController` (looping 30 s), drawing about 14 faint FontAwesome glyphs via `TextPainter` that drift upward and wrap.
  - It is static when `MediaQuery.disableAnimations` is set, and stops when `TickerMode` is off.
  - `RepaintBoundary` around it.

### 3. Home redesign
- Top bar:
  - The profile chip (avatar plus username, with a yellow dot if guest or legacy) opens a `ProfileSheet` (modal bottom sheet).
  - The trophy chip shows `unlocked/6` badges and opens `/stats`.
  - Settings opens `/settings`.
- `ProfileSheet`:
  - Avatar and name, then 3 mini stats (games, wins, badges).
  - "Secure your account" (guest or legacy only), "Open stats", and "Log out".
  - Log out for a guest shows a confirm dialog: "You're a guest. Logging out deletes access to this account and its stats forever."
- Body:
  - A hero with the 3 existing character images. They idle-bob, and the impostor sways/peeks. All static with reduce-motion.
  - The title "مين الإمبوستر؟" (localized).
  - Two `GameButton.lg`: Create room (primary) and Join with code (secondary).
  - A small "How to play" text link (existing rules route).
- Removed from the Home body: the secure account button, the stats text button, and the logout icon.
- The trophy count needs stats on Home, so a `PlayerStatsCubit` is created on Home. It loads and shows nothing until loaded, and its failure hides the count (the chip shows the trophy icon only).

### 4. Rollout to other screens (second pass, same branch)
- `AnimatedGameBackground` behind: Home, Create room, Join room, Waiting room, Stats, Game Over. **Not** during active rounds (hints/voting/results), where it would distract and cost battery.
- Replace inline primary/secondary buttons with `GameButton` on those screens.
- Replace card containers with `GamePanel` where it is a 1:1 swap.

### 5. Docs and verification
- `docs/design-system.md`: tokens, components, do/don't, screenshots.
- A debug-only `/dev/gallery` route that shows every component in light and dark (not in release builds).
- Widget tests: button press state and haptic call, background static under disableAnimations, profile sheet guest logout confirm, Home shows exactly 2 primary actions.

## Open questions for the reviewer
1. Should body text also move to Baloo Bhaijaan 2, or stay on the default font?
2. Should the trophy chip on Home hit `get_my_stats` on every Home visit? Alternatives: cache the last count in prefs and refresh it in the background.
3. Should the background cover the game rounds too, at lower opacity, or stay off as proposed?
4. Is the "3D" button risky for RTL or large text scaling?
5. Is a light theme worth keeping for the game look, or should we go dark-only?
6. Anything in this plan that conflicts with AGENTS.md (online vs shared-device separation, BuildContext after async)?
