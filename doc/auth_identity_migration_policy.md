# Guess Party Authentication Identity Migration Policy

**Status:** Approved for Phase 7 implementation  
**Phase:** 7 — Authentication Identity and Recovery  
**Prepared:** 2026-07-13  
**Production changes authorized:** No

## 1. Objective

Move persistent Guess Party accounts from synthetic
`<username>@guessparty.com` credentials to verified, user-owned email
identities without changing existing Supabase user IDs, breaking existing room
membership, or weakening anonymous guest play.

## 2. Identity and Authorization Rules

1. `auth.uid()` remains the only account identity used for authorization.
2. Display names are profile data and MUST NOT be used to authorize a player,
   recover an account, or infer account ownership.
3. Duplicate display names are allowed globally. Existing room RPCs continue to
   reject case-insensitive duplicate names within the same room.
4. Existing `players.user_id`, room membership, scores, and authored data remain
   attached to the same Supabase user ID throughout an in-place upgrade.
5. Client-editable user metadata MUST NOT be used by RLS or privileged RPCs.

## 3. Account Classes

### 3.1 Anonymous guests

- Guest sign-in continues to use `signInAnonymously()`.
- Signing out, clearing application data, or moving to another device can make
  an unlinked guest account unrecoverable.
- A guest may upgrade in place by linking and verifying a real email, then
  setting a password. This preserves the guest's Supabase user ID.

### 3.2 Legacy persistent accounts

- Accounts whose email ends in `@guessparty.com` remain sign-in compatible
  through an explicitly labeled legacy username flow.
- A legacy account may be migrated only after successfully authenticating with
  its existing username and password.
- Migration updates the authenticated account to a real email and requires
  confirmation of that address. The Supabase user ID is preserved.
- A username alone is never accepted as proof of ownership.
- Password recovery is unavailable for a legacy account until a real email has
  been verified; support staff must not transfer it based only on a username.

### 3.3 New persistent accounts

- New registrations require a valid real email, password, and display name.
- The email must be verified before the account is treated as recoverable.
- Login uses email and password. The display name remains independent of the
  sign-in identifier.

## 4. Guest-to-Account Upgrade

The approved upgrade path preserves the anonymous user's existing UID:

1. The signed-in guest supplies a real email and display name.
2. The app calls Supabase `updateUser` to link the email.
3. The user confirms ownership through the email callback.
4. Only after email verification does the app allow a password to be set.
5. User metadata is updated with the display name; authorization remains
   unchanged because the UID is unchanged.

Manual identity linking and the mobile redirect URL must be enabled in each
target Supabase environment before this flow is released.

If the supplied email already belongs to another account, Guess Party does not
automatically merge identities or gameplay records. The guest remains signed
in and receives instructions to finish the current room, sign out, and sign in
to the existing account. Any future merge workflow requires a separate,
audited backend design.

## 5. Password Recovery

- The recovery form accepts a real email only and always shows the same success
  response, whether or not the address exists, to reduce account enumeration.
- Supabase sends the recovery message to the verified address and redirects to
  the registered Guess Party mobile callback.
- The app shows the new-password screen only after receiving an authenticated
  password-recovery session/event.
- Password updates use Supabase `updateUser`; passwords are never stored or
  logged by the Flutter app.
- Recovery links and sessions must not expose role, room, chat, or gameplay
  content to telemetry.

## 6. Session Expiry

- Expired or revoked sessions return the user to authentication with a concise,
  recoverable message.
- Gameplay commands continue to fail closed when no `auth.uid()` is available.
- Auth-state navigation is owned once at the application/session boundary so a
  single expiry event cannot produce duplicate redirects.
- Anonymous users receive an explicit warning that signing out may make their
  guest account unrecoverable.

## 7. Compatibility Rollout

1. Ship a compatibility client that supports real-email registration/login,
   password recovery, guest upgrade, and the legacy username login path.
2. Validate email delivery, confirmation, recovery, and mobile redirects in the
   disposable/local environment and staging before production configuration.
3. Enable the required production Auth settings only after the compatible app
   is available.
4. Keep legacy username login available until a separately approved retirement
   plan demonstrates that remaining accounts have a safe path forward.
5. Never bulk-rewrite `auth.users`, `players.user_id`, or room data.

No public-table migration is expected for this phase. If implementation proves
that a database object is required, it must be introduced through a canonical
migration and contract tests before staging or production.

## 8. Environment Configuration Required for Release

- Anonymous sign-in enabled.
- Email/password sign-up enabled.
- Email confirmations enabled outside local automated tests.
- Manual identity linking enabled for guest upgrades.
- Legacy migration must use either single-confirm email changes or an audited
  privileged migration service because the synthetic old address is not
  user-owned. This choice requires separate production approval.
- `io.supabase.guessparty://login-callback` registered as an allowed redirect.
- Android and iOS registered to open the same callback.
- A production SMTP provider configured and monitored before public recovery is
  advertised.

These are deployment requirements, not authorization to modify the production
project during implementation.

## 9. Acceptance Tests

- Existing legacy username/password account can still sign in.
- Authenticated legacy account can begin an in-place real-email migration
  without changing UID.
- New account registers with real email and a separate display name.
- Password reset uses a generic response and a recovery-only password update.
- Anonymous guest play still works.
- Guest upgrade preserves UID after email verification.
- Duplicate global display names do not affect identity; duplicate names in one
  room remain rejected.
- Expired sessions redirect once and privileged gameplay operations fail closed.
- Online and Shared-Device games still complete under guest and persistent
  sessions.

## 10. Reference Guidance

- [Supabase password-based authentication](https://supabase.com/docs/guides/auth/passwords)
- [Supabase anonymous sign-ins and account conversion](https://supabase.com/docs/guides/auth/auth-anonymous)
- [Supabase Flutter mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
