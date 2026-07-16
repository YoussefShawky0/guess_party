# Phase 10 Release Operations Runbook

## Table of Contents

- [Purpose](#purpose)
- [Current Release Status](#current-release-status)
- [Required Owner Inputs](#required-owner-inputs)
- [Release Candidate Creation](#release-candidate-creation)
- [Artifact Verification](#artifact-verification)
- [Staged Rollout Policy](#staged-rollout-policy)
- [Rollback Policy](#rollback-policy)
- [Signing Key Loss or Compromise](#signing-key-loss-or-compromise)
- [Incident Ownership](#incident-ownership)
- [Blocked Items](#blocked-items)

## Purpose

This runbook defines the human-gated release process for Guess Party after the
Phase 10 CI/release-engineering work. It does not authorize a store upload,
production Supabase change, production Sentry change, or package identifier
change by itself.

## Current Release Status

The repository can validate source, database contracts, build metadata, and
fail-closed release wiring. A public Android/iOS release is still blocked until
the company owner supplies permanent identities, signing materials, store
ownership, and production configuration.

## Required Owner Inputs

| Input | Required Before | Storage |
|---|---|---|
| Permanent Android application ID | Any public Android artifact | Git-tracked Gradle config after approval |
| Android upload/release keystore | Production AAB build | CI secret store or approved local secret path |
| Android key alias/passwords | Production AAB build | CI secret store only |
| Production Dart define JSON | Production AAB build | CI secret store only |
| Permanent iOS bundle ID | iOS archive validation | Xcode project after approval |
| Apple team/signing strategy | iOS archive validation | Apple developer portal and CI secret store |
| Store rollout owner | Any store upload | Release notes / issue tracker |

## Release Candidate Creation

1. Confirm Phase 10 source gate is green on `master`.
2. Confirm staging Supabase migration promotion and smoke tests passed.
3. Confirm `pubspec.yaml` uses `major.minor.patch+build`.
4. Create an immutable tag matching the semantic version, for example `v1.0.0`.
5. Run the manual Release workflow for that tag.
6. Review the generated AAB, checksum, and provenance artifact.
7. Do not upload to a store until a human owner explicitly approves promotion.

## Artifact Verification

For every release candidate, retain:

- `app-production-release.aab`;
- `app-production-release.aab.sha256`;
- `app-production-release.provenance.json`;
- workflow URL and run ID;
- source commit SHA;
- release tag;
- Sentry release/dist values.

The workflow verifies the AAB signature with `jarsigner` and produces a SHA-256
checksum. Store upload remains a separate manual action.

## Staged Rollout Policy

Default rollout sequence:

1. internal testing;
2. closed testing, if applicable;
3. 10%;
4. 25%;
5. 50%;
6. 100%.

Each stage requires a human checkpoint reviewing crash rate, support reports,
Supabase errors, Sentry issues, authentication recovery, and gameplay integrity.

## Rollback Policy

If a release causes gameplay, auth, security, or crash regressions:

1. pause rollout immediately;
2. disable store promotion;
3. identify whether the issue is client-only or backend-coupled;
4. if client-only, prepare a hotfix with a higher build number;
5. if backend-coupled, stop and apply the Supabase rollback/playbook approved
   for that migration set;
6. document affected versions, users, and recovery steps.

Do not roll back production Supabase manually from the dashboard unless the CTO
or appointed release owner explicitly approves the exact SQL.

## Signing Key Loss or Compromise

If an upload key is lost:

1. stop all release attempts;
2. notify the store owner;
3. follow the store's upload-key reset process;
4. rotate CI secrets;
5. verify a new signed internal build before public rollout.

If a signing key is suspected compromised:

1. revoke/remove CI secrets immediately;
2. rotate credentials through the store-approved path;
3. audit workflow logs and artifact access;
4. generate a new provenance record for the replacement artifact;
5. document the incident and owner approvals.

## Incident Ownership

| Area | Primary Owner |
|---|---|
| Store rollout decision | Company/product owner |
| Supabase production data/schema | CTO or delegated backend owner |
| CI signing secrets | Release engineering owner |
| Crash/Sentry triage | Engineering owner |
| Player support communication | Product/support owner |

## Blocked Items

- Permanent Android application ID is not supplied.
- Android signing credentials are not supplied.
- iOS bundle/team/signing inputs are not supplied.
- Store account access is not supplied.
- Production/staging Supabase promotion remains separately gated.
