# Phase 10 — Release Engineering Implementation Runbook

## Table of Contents

- [Objective](#objective)
- [External Inputs and Hard Gate](#external-inputs-and-hard-gate)
- [Starting State](#starting-state)
- [Locked Release Design](#locked-release-design)
- [Ordered Tasks](#ordered-tasks)
- [CI and Build Templates](#ci-and-build-templates)
- [Test Plan](#test-plan)
- [Stop Conditions](#stop-conditions)
- [Required Report](#required-report)
- [Reviewer Checklist](#reviewer-checklist)

## Objective

Produce reproducible, fail-closed Android release artifacts and prepare an iOS
archive path without committing credentials or guessing company identities.

## External Inputs and Hard Gate

Do not change the application ID or create a public release until all applicable
values are supplied by the company owner:

- permanent Android application ID;
- Android upload/release keystore, alias, and secret delivery mechanism;
- permanent iOS bundle ID;
- Apple team ID and signing/profile strategy;
- staging/production configuration from Phase 9;
- store account access and rollout owner.

If these values are absent, implement and test only generic CI, validation, and
documentation that does not bake in placeholder identities. Report the blocked
identity/signing tasks explicitly.

## Starting State

- Android still uses `com.example.guess_party`.
- `build.gradle.kts` supports an external `key.properties` and no longer
  deliberately selects debug signing for release.
- `.github/workflows/flutter-ci.yml` runs formatting, analyzer, Flutter tests,
  and only checks migration file presence; it does not construct Supabase or run
  pgTAP.
- There is no signed artifact workflow, provenance record, promotion policy,
  upgrade-install test, Fastlane setup, or iOS archive validation.

Phase 9 must be accepted and committed. Run the complete gate before editing.

## Locked Release Design

- Branch/PR CI validates source and backend contracts.
- Release CI is manually dispatched for an immutable Git tag.
- Production signing secrets live only in the CI secret store or an approved
  local secret file outside Git.
- A production build must fail when signing inputs are missing; it must never
  fall back to debug/unsigned while claiming release readiness.
- Version format remains semantic `major.minor.patch+build` in `pubspec.yaml`.
- Git tag format is `v<major>.<minor>.<patch>`; CI verifies tag/version equality.
- Build number must increase monotonically and is the Android `versionCode` and
  iOS `CFBundleVersion`.
- Retain release artifacts and checksums for 90 days; retain production symbols
  according to Sentry/store policy.
- Rollout defaults to internal testing, then 10%, 25%, 50%, and 100%, with an
  explicit human approval between stages.

## Ordered Tasks

| ID | Task |
|---|---|
| P10-001 | Verify Phase 9 gate and inventory existing CI/signing behavior |
| P10-002 | Add version/tag/build-number validation script and tests |
| P10-003 | Extend PR CI to construct local Supabase and run all pgTAP contracts |
| P10-004 | Add Android debug/staging build validation with Phase 9 define files |
| P10-005 | When permanent ID is supplied, replace namespace/application ID and verify upgrade implications |
| P10-006 | Add fail-closed production signing configuration using external inputs only |
| P10-007 | Add manual tag-based release workflow, checksums, provenance, and artifact retention |
| P10-008 | Add two-sequential-build upgrade-install script for emulator/device |
| P10-009 | Add iOS archive validation when bundle/team/signing inputs exist |
| P10-010 | Write staged rollout, rollback, key-loss, and incident ownership procedures |
| P10-011 | Run clean-checkout release gate and stop for senior review |

## CI and Build Templates

### Backend contract job

Extend CI with the equivalent of:

```yaml
backend-contracts:
  runs-on: ubuntu-latest
  timeout-minutes: 20
  steps:
    - uses: actions/checkout@v4
    - uses: supabase/setup-cli@v1
      with:
        version: latest
    - run: supabase start --exclude storage-api,imgproxy,studio,edge-runtime,logflare,vector
    - run: supabase test db
    - if: always()
      run: supabase stop --no-backup
```

Pin the CLI version after confirming the version used by the repository. Do not
leave `latest` in the final workflow.

### Fail-closed signing

The final Gradle logic must follow this behavior:

```kotlin
val isProductionTask = gradle.startParameter.taskNames.any {
    it.contains("Production", ignoreCase = true) &&
        it.contains("Release", ignoreCase = true)
}

if (isProductionTask && !keystorePropertiesFile.exists()) {
    throw GradleException("Production release signing is not configured.")
}
```

Do not log paths, aliases, passwords, or store contents. `key.properties`,
keystores, provisioning profiles, API keys, and service-account JSON remain
ignored.

### Release workflow

The manual/tag workflow must:

1. Checkout the exact tag.
2. validate a clean tree and version/tag match;
3. run formatter, analyzer, Flutter tests, local Supabase construction, and all
   database contracts;
4. validate Phase 9 production defines;
5. restore signing materials from CI secrets into a temporary directory;
6. build the production AAB;
7. run `jarsigner`/`apksigner` verification as appropriate;
8. generate SHA-256 checksums and provenance metadata;
9. upload artifacts without printing secrets;
10. delete temporary signing files in an `always()` cleanup step.

Do not automatically publish to a store in the first implementation. Store
promotion remains a separately approved human action.

## Test Plan

Required tests:

- wrong/missing version or tag fails;
- production build without signing inputs fails with the controlled error;
- debug and staging builds do not require production credentials;
- production artifact reports the permanent application ID once supplied;
- debug signing certificate is absent from the production artifact;
- CI constructs the canonical database and runs every contract file;
- two sequential signed builds install as an upgrade without data loss;
- workflow logs contain no key material or configuration values.

Commands include:

```powershell
flutter analyze
flutter test
supabase test db
flutter build appbundle --flavor production --release --dart-define-from-file=$env:PRODUCTION_DEFINE_FILE
git status --short
```

The production command is run only after authorized values are available.

## Stop Conditions

Stop rather than guess if the permanent ID, signing credentials, Apple inputs,
production define file, or store owner is missing. Stop if changing the
application ID would break an already published package or OAuth/deep-link
registration without a migration decision. Never push a tag, publish an
artifact, upload to a store, or change production services without explicit
authorization. Do not begin Phase 11.

## Required Report

Report completed/blocked task IDs, IDs supplied by the owner, CI jobs, secret
names without values, artifact verification output, checksum/provenance paths,
upgrade-install evidence, changed files, and confirmation that no store upload
occurred.

## Reviewer Checklist

- [ ] Permanent identities are company-owned and approved.
- [ ] Production signing fails closed.
- [ ] No credential or generated secret is tracked or logged.
- [ ] Backend and Flutter gates run from a clean checkout.
- [ ] Artifact identity, signature, version, and checksum are verified.
- [ ] Upgrade installation succeeds.
- [ ] Publishing remains human-gated.
