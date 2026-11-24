# Game UI design system

One page. Code lives in `lib/core/design/` (tokens) and `lib/shared/design/`
(components). Spec: `specs/005-game-ui/spec.md`.

## Typography

- Heading and button text use **Baloo Bhaijaan 2** (`BalooBhaijaan2`, variable
  font, weights 700 and 800).
- It is applied only through `textTheme` slots in `app_theme.dart`:
  `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `titleLarge`,
  `labelLarge`. Body styles keep the default font.
- Use `Theme.of(context).textTheme.headlineMedium` etc. Do not set
  `fontFamily` by hand.

## Tokens (`GameTokens`)

Read with `GameTokens.of(context)`. A light and a dark instance are registered
on both themes.

| Group | Values |
|---|---|
| `spacing` | xs 4, sm 8, md 12, lg 16, xl 24, xxl 32 |
| `radius` | sm 10, md 16, lg 24, pill 999 |
| `button` | depth 5 px resting, 1 px pressed; min height lg 56, md 48 |
| `motion` | fast 120 ms, base 220 ms, slow 400 ms, `bounce` = `Curves.easeOutBack` |
| `reward` | gold `#F5B83D`, edge `#B7811A` (trophy chip) |
| colors | primary/secondary/disabled face, edge and on-color; focus ring; background glyph |

Button colors are derived from `AppColors`. Add new colors to `AppColors`;
never rename existing ones.

## Components

- **`GameButton`**: chunky button with a darker bottom edge. `variant`
  primary or secondary, `size` lg or md, optional `icon`, `isLoading`.
  `onPressed: null` is the disabled look. Fills the available width; the
  height is a minimum, so the label wraps and the button grows with the text
  scale. Calls `GameFeedback.tapHaptic()` on tap. Has a focus ring and a
  button semantics role.
- **`GameChip`**: pill with icon and label (profile, trophy count). Give it a
  `semanticLabel` when the label is missing or unclear.
- **`GameIconButton`**: round 44 px icon button. `tooltip` is required and is
  also the semantic label.
- **`PlayerAvatar`**: initial in a circle, color picked from a fixed palette by
  a stable hash of the name. `showDot` adds the warning dot.
- **`AnimatedGameBackground`**: faint drifting glyphs behind a screen. One
  30 s controller drives a `CustomPainter`; glyphs are laid out once.

## Do

- One primary `GameButton` per screen. Everything else is secondary or a text
  button.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and `DirectionalFaIcon`
  for arrows, so Arabic (RTL) mirrors correctly.
- Test new components at text scale 2.0 in `ar` and `en`, with the real font
  (see `test/helpers/game_ui_helpers.dart`, `loadGameFonts`).
- Put `AnimatedGameBackground` outside any `BlocBuilder`/`BlocConsumer` so
  state changes never rebuild it.

## Don't

- Do not show `AnimatedGameBackground` during gameplay rounds (hints, voting,
  results, role reveal, pass device). It is for Home, Stats, Waiting Room.
- Do not change logic in a visual swap. Every `onPressed` condition, loading
  state and navigation call must stay exactly as it was; the existing tests
  for the screen must pass unchanged.
- Do not add a second primary button, or a danger-styled button for a
  confirmation (use a plain `TextButton`).
- Do not hard-code user-visible strings; use l10n (`en` and `ar`).

## Reduce-motion and battery rules

- `MediaQuery.disableAnimations` makes the background and the Home hero
  static (one frame, no ticker).
- The background also stops when the ticker mode is off, when the app is not
  `resumed`, and after 60 s without pointer input (any pointer resumes it).
- Any new endless animation must follow the same rules.
