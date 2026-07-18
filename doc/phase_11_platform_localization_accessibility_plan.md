# Phase 11 — Platform Policy, Localization, and Accessibility Runbook

## Table of Contents

- [Objective](#objective)
- [Starting State and Gate](#starting-state-and-gate)
- [Locked Product Policy](#locked-product-policy)
- [Localization Implementation](#localization-implementation)
- [Accessibility Implementation](#accessibility-implementation)
- [Platform and Store Implementation](#platform-and-store-implementation)
- [Ordered Tasks](#ordered-tasks)
- [Test Plan](#test-plan)
- [Stop Conditions](#stop-conditions)
- [Required Report](#required-report)
- [Reviewer Checklist](#reviewer-checklist)

## Objective

Declare the supported production platforms, provide complete English/Arabic
localization with RTL behavior, and make core gameplay usable with large text,
screen readers, keyboard/focus navigation, and reduced motion.

## Implementation Status (2026-07-18)

- Localization infrastructure is implemented with generated English and Arabic
  ARB resources; English is the fallback locale and Arabic is RTL-capable.
- Shared-Device copy explicitly states that internet access and an authenticated
  session are required. The persisted database value `local` is unchanged.
- Android Play update checks are gated by Android platform, production
  environment, and `play` distribution.
- Core room, reveal, voting, chat, timer, score, and navigation controls now
  expose localized labels or semantics without including unrevealed secrets.
- Store metadata is under `store_metadata/` and links to the externally managed
  privacy policy only: https://youssefshawky0.github.io/guess-party-privacy/
- The obsolete local privacy draft was deleted; no policy content is duplicated
  in this repository.

## Starting State and Gate

Phase 10 must be accepted and committed. The signed Android release smoke gate
must pass, or Phase 10 must explicitly document why signing remains externally
blocked while non-release accessibility work is authorized.

Verified starting facts (before this phase):

- Player-facing strings were hard-coded across the UI in English with some
  Arabic error text.
- `flutter_localizations`, generated ARB resources, and `l10n.yaml` were absent.
- Android update calls were platform-gated but not Play-distribution-gated.
- There was no systematic semantics, contrast, text-scale, focus-order,
  reduced-motion, or screen-reader test suite.

## Locked Product Policy

- Supported public platforms: Android and iOS.
- Web and Windows runners remain development artifacts and are not advertised
  as production-supported.
- Supported languages: English (`en`) and Arabic (`ar`).
- English is the fallback locale.
- Shared Device remains the user-facing label; database value `local` is never
  translated or changed.
- Play in-app update appears only for Android production builds whose
  `APP_DISTRIBUTION` is `play`.
- iOS uses App Store/open-store behavior defined by product release policy; it
  never invokes the Android Play API.
- Accessibility correctness outranks animation and decorative layout fidelity.

## Localization Implementation

Add SDK localization dependencies and generation:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

Add `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

Create `app_en.arb` and `app_ar.arb`. Every player-facing string must use a
semantic key, including dialogs, validation, snackbars, reconnect banners,
Auth/recovery, game phases, chat, Settings, and accessibility labels.

Parameterized example:

```json
{
  "playersNeeded": "{count, plural, =1{1 more player needed} other{{count} more players needed}}",
  "@playersNeeded": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```

Arabic must be authored as natural Arabic, not machine-transliterated English.
Do not localize database values, RPC error codes, route paths, telemetry field
names, or internal enum/wire values. Map error codes to localized presentation
copy at the UI/error boundary.

Configure the app:

```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

Locale follows the device by default. If a language selector already exists or
is added, persist only `system`, `en`, or `ar` in SharedPreferences and expose
it through a dedicated locale Cubit; do not combine it with gameplay state.

## Accessibility Implementation

### Semantics

Add explicit labels/hints where visible text is insufficient:

- create/join/start controls;
- room code/share actions;
- player host/online state;
- secret-card reveal/hide action without reading hidden content prematurely;
- hint submission and voting targets;
- timer value and phase transitions;
- score/result rows;
- reconnect status;
- chat send, load older, mute, and report actions.

Never place unrevealed role, character, or imposter data in a semantics label,
tooltip, hidden widget, or traversal node.

### Text scale and layout

- Support text scaling through at least 200% for Auth, room, gameplay controls,
  results, Settings, and chat.
- Replace fixed-height text containers where they clip.
- Permit wrapping and vertical button growth.
- Preserve tap targets of at least 48 logical pixels.
- Do not globally clamp `textScaler` to hide layout defects.

### Focus and input

- Provide logical traversal order matching visual reading order in LTR and RTL.
- Dialog focus starts on the title/first field and returns to its invoker.
- All core actions work with keyboard activation in widget tests.
- Destructive leave/report actions retain confirmation.

### Contrast and motion

- Validate normal text at 4.5:1 and large text/icons at 3:1 against actual
  backgrounds.
- Use color plus icon/text for host, online, error, and selection states.
- Respect platform reduced-motion/accessible-navigation settings: replace
  nonessential animation with immediate transitions and avoid repeated
  celebratory motion.

## Platform and Store Implementation

Update service contract:

```dart
class UpdateService {
  static bool isSupported(AppConfig config) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      config.environment == AppEnvironment.production &&
      config.distribution == AppDistribution.play;
}
```

Inject configuration rather than reading globals in presentation. Tests must
prove unsupported platforms/distributions never call `in_app_update`.

Create/update store metadata for exactly the implemented product:

- connected Online and Shared-Device gameplay;
- internet/session requirement;
- supported Android/iOS versions;
- Auth/recovery and account-deletion/support path if implemented;
- privacy disclosures consistent with Supabase and Sentry use;
- English and Arabic descriptions/screenshots where required.

Do not claim offline play, unsupported platforms, voice chat, public
matchmaking, or unimplemented moderation outcomes.

## Ordered Tasks

| ID | Task |
|---|---|
| P11-001 | Run Phase 10 gate and inventory every player-facing literal and core screen |
| P11-002 | Add localization dependencies/configuration and English ARB baseline |
| P11-003 | Replace hard-coded strings by feature, keeping wire/error codes internal |
| P11-004 | Add reviewed Arabic translations and RTL-safe layouts |
| P11-005 | Add locale selection/persistence only if required by current Settings UX |
| P11-006 | Add semantics and secret-state accessibility protections |
| P11-007 | Fix 200% text scale, focus order, tap targets, contrast, and reduced motion |
| P11-008 | Gate Play updates by platform, production environment, and distribution |
| P11-009 | Add localization/accessibility widget and full-flow tests |
| P11-010 | Update privacy, support, platform, and store metadata |
| P11-011 | Run Android/iOS candidate validation and stop for senior review |

## Test Plan

Automated tests must run core screens under:

```dart
const Locale('en')
const Locale('ar')
```

and at text scales `1.0`, `1.3`, and `2.0`. Required scenarios:

- guest and persistent Auth/recovery;
- create/join and non-host navigation;
- Online role reveal, hints, voting, results, next round, reconnect, and finish;
- Shared-Device pass/reveal/hints/sequential voting/results;
- chat pagination/send/mute/report;
- Settings/update visibility;
- no hidden secret text in unauthorized semantics trees.

Use semantics tests to locate controls by localized label and invoke actions.
Include RTL golden/layout checks only where deterministic repository support
already exists; do not replace behavioral tests with goldens.

Manual device matrix:

| Platform | Locale | Text | Screen reader | Required |
|---|---|---:|---|---:|
| Android | English | 100% and 200% | TalkBack | Yes |
| Android | Arabic RTL | 100% and 200% | TalkBack | Yes |
| iOS | English | default and accessibility size | VoiceOver | Yes when Apple environment available |
| iOS | Arabic RTL | default and accessibility size | VoiceOver | Yes when Apple environment available |

Final gate:

```powershell
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
supabase test db
rg -n "Text\(['\"]|labelText:\s*['\"]|hintText:\s*['\"]" lib --glob "*.dart"
```

Every remaining literal finding must be internal/non-player-facing or documented.

## Stop Conditions

Stop if Phase 10 is not accepted, professional Arabic review is unavailable for
release sign-off, a screen requires exposing hidden state to assistive
technology, or store/privacy claims cannot be verified. Do not silently drop a
language, clamp text scaling, disable semantics, advertise unsupported
platforms, or invoke Android update APIs elsewhere.

## Required Report

Report task IDs, ARB key counts and parity, untranslated literals, locale/text
scale/semantics test output, contrast results, manual device matrix, update
gating results, metadata changes, external iOS/translation gates, and all
changed files.

## Reviewer Checklist

- [ ] English and Arabic ARB keys are identical and complete.
- [ ] RTL and 200% text do not block core gameplay.
- [ ] Screen readers cannot reveal unauthorized secrets.
- [ ] Focus order and tap targets are usable.
- [ ] Status never relies on color alone.
- [ ] Play updates run only on Android production Play builds.
- [ ] Store/privacy claims match implemented behavior.
- [ ] Full gameplay and database gates remain green.
