# Phase 9 — Environment Separation and Observability Implementation Runbook

## Table of Contents

- [Objective](#objective)
- [Starting State and Gate](#starting-state-and-gate)
- [Locked Configuration Contract](#locked-configuration-contract)
- [Implementation Design](#implementation-design)
- [Ordered Tasks](#ordered-tasks)
- [Test Plan](#test-plan)
- [Stop Conditions](#stop-conditions)
- [Required Report](#required-report)
- [Reviewer Checklist](#reviewer-checklist)

## Objective

Make development, staging, and production builds identify themselves, connect
only to the intended Supabase/Sentry projects, and emit privacy-safe telemetry.
Release artifacts must not depend on a bundled `.env` file.

## Starting State and Gate

Phase 8 must be accepted and committed. Run:

```powershell
git status --short
flutter analyze
flutter test
supabase test db
```

Current facts:

- `AppConfig` reads `flutter_dotenv`.
- `.env` is included under Flutter assets and is therefore public in a shipped
  application.
- Sentry environment and trace sampling exist, but release/distribution and
  centralized event scrubbing are incomplete.
- No development/staging/production flavor matrix exists.

## Locked Configuration Contract

Use compile-time Dart defines for every non-local build. Define:

| Define | Required | Rule |
|---|---:|---|
| `APP_ENVIRONMENT` | Yes | `development`, `staging`, or `production` |
| `APP_DISTRIBUTION` | Yes | `local`, `internal`, `play`, or `appstore` |
| `SUPABASE_URL` | Yes | Valid HTTPS URL except local development may use loopback HTTP |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Public/publishable client key only |
| `SENTRY_DSN` | No | Empty disables Sentry cleanly |
| `SENTRY_TRACES_SAMPLE_RATE` | No | Default `0.1`, clamped to `0.0–1.0` |
| `SENTRY_RELEASE` | Production/staging | CI-generated immutable release name |
| `SENTRY_DIST` | Production/staging | CI build number/distribution |

Do not accept `SUPABASE_SERVICE_ROLE_KEY`, database passwords, signing secrets,
Auth tokens, or SMTP credentials in application configuration.

Tracked configuration files may contain placeholders only:

```json
{
  "APP_ENVIRONMENT": "development",
  "APP_DISTRIBUTION": "local",
  "SUPABASE_URL": "http://127.0.0.1:54321",
  "SUPABASE_PUBLISHABLE_KEY": "REPLACE_WITH_LOCAL_PUBLISHABLE_KEY",
  "SENTRY_DSN": "",
  "SENTRY_TRACES_SAMPLE_RATE": "0.0"
}
```

Real staging/production values remain CI secrets/environment configuration and
must never be committed.

## Implementation Design

### App configuration

Replace `flutter_dotenv` bootstrap with a compile-time configuration object.
The public interface must remain injectable/testable:

```dart
enum AppEnvironment { development, staging, production }
enum AppDistribution { local, internal, play, appstore }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.distribution,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.sentryDsn,
    required this.sentryTracesSampleRate,
    required this.sentryRelease,
    required this.sentryDist,
  });

  factory AppConfig.fromMap(Map<String, String> values);
  factory AppConfig.fromCompileTime();

  void validateForBuild();
}
```

`fromCompileTime` reads `String.fromEnvironment`. `fromMap` remains the unit-test
seam. Remove `.env` from `pubspec.yaml` assets and remove `flutter_dotenv` when
no source imports remain.

Validation must fail startup/build checks when:

- environment/distribution values are unknown;
- URL or publishable key is missing;
- production uses loopback, `.local`, development, or staging endpoints;
- production uses `local` or `internal` distribution;
- development uses `play` or `appstore` distribution;
- a publishable-key field contains obvious service-role/JWT secret markers;
- staging/production release or distribution identifiers are missing.

Do not print key values in validation failures.

### Build identities

Add Android product flavors `development`, `staging`, and `production` on an
`environment` dimension. Until Phase 10 supplies the permanent ID, keep the
current base ID but use `.dev` and `.staging` suffixes. Production gets no
suffix. Do not claim the placeholder production ID is release-ready.

Add equivalent iOS schemes/configurations. Scheme names must be
`GuessParty-Development`, `GuessParty-Staging`, and `GuessParty-Production`.
Only configuration plumbing is in scope; signing/team changes remain Phase 10.

### Sentry privacy

Create one telemetry boundary instead of direct ad-hoc sensitive calls. The
scrubber must remove keys matching, case-insensitively:

```text
password, token, authorization, cookie, secret, service_role,
character_id, imposter_player_id, role, chat, content, message
```

Configure Sentry with:

```dart
options.environment = config.environment.name;
options.release = config.sentryRelease;
options.dist = config.sentryDist;
options.tracesSampleRate = config.sentryTracesSampleRate;
options.sendDefaultPii = false;
options.beforeSend = telemetryScrubber.scrubEvent;
options.beforeBreadcrumb = telemetryScrubber.scrubBreadcrumb;
```

Allowed breadcrumbs contain identifiers needed for operations but no player
copy or secrets: room ID hash, round number, phase name, connection state,
command name, and success/failure class.

### CI guards

Add a script that validates a define file without printing values and use it in
CI before staging/production builds. CI must deliberately test that a
production build pointed at `127.0.0.1` or a known non-production endpoint
fails.

Document local commands:

```powershell
flutter run --flavor development --dart-define-from-file=config/development.local.json
flutter build apk --flavor staging --dart-define-from-file=$env:STAGING_DEFINE_FILE
flutter build appbundle --flavor production --dart-define-from-file=$env:PRODUCTION_DEFINE_FILE
```

The two non-local commands are examples only until real CI files exist.

## Ordered Tasks

| ID | Task |
|---|---|
| P9-001 | Record Phase 8 gate and current backend/Sentry identity behavior |
| P9-002 | Add failing AppConfig environment, distribution, endpoint, and secret-rejection tests |
| P9-003 | Implement compile-time AppConfig and remove bundled `.env` dependence |
| P9-004 | Add Android flavors and matching iOS schemes/configurations |
| P9-005 | Add centralized Sentry release metadata and event/breadcrumb scrubber |
| P9-006 | Replace sensitive/ad-hoc breadcrumbs with approved structured fields |
| P9-007 | Add define validation script and CI negative guards |
| P9-008 | Add development runbook and staging/production external-input checklist |
| P9-009 | Run all environment builds possible without company secrets and full regression gate |
| P9-010 | Update master ledger and stop for senior review |

## Test Plan

Unit tests must cover all environment/distribution combinations, missing values,
invalid URLs, loopback production rejection, service-role marker rejection,
sample-rate clamping, optional Sentry, and required release/dist metadata.

Telemetry tests must construct events/breadcrumbs containing every forbidden
key and prove the emitted result contains none of the values. Include nested
maps, lists, exception text, and HTTP headers.

Build tests:

```powershell
flutter analyze
flutter test
supabase test db
flutter build apk --debug --flavor development --dart-define-from-file=config/development.local.json
```

Staging/production build validation runs only when authorized define files are
available. Absence is reported as an external gate, not converted into fake
values.

Search gates:

```powershell
rg -n "flutter_dotenv|dotenv|\.env" lib pubspec.yaml
rg -n "password|token|character_id|imposter_player_id|content" lib --glob "*.dart"
```

The first search must find no runtime `.env` dependency. Findings from the
second must be reviewed to prove sensitive values do not enter telemetry.

## Stop Conditions

Stop if Phase 8 is not committed, real staging/production project values are
required to continue, flavor changes would force a permanent package/bundle ID,
or an SDK prevents deterministic telemetry scrubbing. Do not invent URLs,
project refs, DSNs, application IDs, teams, or secrets. Do not change production
Supabase/Sentry settings and do not begin Phase 10.

## Required Report

Report task IDs, config contract changes, flavor/scheme names, all removed
`.env` references, telemetry redaction evidence, build commands/output, external
gates, changed files, and confirmation that no real configuration was committed.

## Reviewer Checklist

- [ ] Release artifacts do not bundle `.env`.
- [ ] Production endpoint mismatch fails closed.
- [ ] Only publishable client configuration can enter the app.
- [ ] Sentry environment/release/dist are deterministic.
- [ ] Secrets, Auth data, chat, and hidden roles are scrubbed.
- [ ] Development, staging, and production identities cannot be confused.
- [ ] Gameplay and database regression gates pass.
