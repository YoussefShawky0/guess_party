# 003 — Play Again (rematch)

Status: server done and live; client to implement. Branch `feat/play-again`.

## Behaviour

**Online Mode**
1. On Game Over, the host of the finished room sees a **Play Again** button
   (above *Back to Home*). Non-hosts do not.
2. Host taps it → (interstitial ad, same as leaving Game Over) → **Create Room**
   screen pre-filled with the finished room's settings (category, rounds,
   max players, round duration). Host may change them. Game mode is fixed
   (shown but not changeable). Title: *Play Again*.
3. Host taps Create → server creates a new room and invites every other player
   of the finished room → host lands in the new **Waiting Room**.
4. Players still on Game Over get an invite card: "*{host} wants to play again*"
   with **Join** / **No thanks**.
   - Join → server joins them to the new room under the same name →
     (interstitial ad) → new Waiting Room.
   - No thanks → card goes away; they stay on Game Over.
   - Join can fail (room full / already started / invite gone): show the
     localized error, card goes away.
5. Waiting Room (host only): an **Invited players** section listing each invite
   with status Joined / Waiting… / Declined. Start stays enabled only at ≥ 4
   online players (existing rule). Host can still share the code or leave.

**Shared-Device Mode**
- Same Play Again button for the host (the device owner). Create Room is
  pre-filled including the local player names (host first), editable.
  No invites. Create → countdown as today.

## Server contract (live, do not change)

`rooms.rematch_of uuid` (nullable).

Table `room_invites` (RLS: select own invites or invites of a room you are a
member of; no client writes; in `supabase_realtime`):
`room_id uuid, previous_room_id uuid, user_id uuid, username text,
status text ('pending'|'accepted'|'declined'), created_at timestamptz,
responded_at timestamptz` — primary key `(room_id, user_id)`.

RPC `create_rematch(p_previous_room_id uuid, p_request_id uuid, p_category text,
p_max_rounds int, p_max_players int, p_round_duration int, p_host_username text,
p_local_names text[] default '{}') returns jsonb` —
same JSON shape as `create_room`: `{room: {...}, players: [...]}`.
Idempotent per `p_request_id`. Game mode is taken from the previous room.
Errors: `ROOM_NOT_FOUND`, `ROOM_NOT_FINISHED`, `HOST_REQUIRED`, plus every
`create_room` error.

RPC `respond_rematch_invite(p_room_id uuid, p_accept boolean) returns jsonb` —
decline → `null`; accept → same JSON shape as `join_room`:
`{room: {...}, player: {...}}`. Errors: `INVITE_NOT_FOUND`, plus every
`join_room` error (`ROOM_ALREADY_STARTED`, `ROOM_FULL`, `USERNAME_TAKEN`, ...).

## Client design

### Part A — data layer, cubits, errors, strings

Domain (`lib/features/room/domain/entities/`):
- `room_invite.dart`: `enum RoomInviteStatus { pending, accepted, declined }`;
  `class RoomInvite extends Equatable { roomId, previousRoomId, userId,
  username, status, createdAt? }`.
- `rematch_seed.dart`: `class RematchSeed extends Equatable { previousRoomId,
  gameMode, category, maxRounds, maxPlayers, roundDuration,
  List<String> localNames }` — `localNames` is empty for online, host first for
  local. Add `factory RematchSeed.fromFinishedRoom(Room room, List<Player>
  players)` that sorts players oldest-first (`createdAt`, then `id`) for
  `localNames` when `room.gameMode == 'local'`.

Data (`lib/features/room/data/`):
- `models/room_invite_model.dart`: `fromJson` (unknown status → pending).
- `RoomRemoteDataSource` + impl, new methods:
  - `Future<RoomSession> createRematch({requestId, previousRoomId, category,
    maxRounds, maxPlayers, roundDuration, hostUsername, localNames})` — parse
    with the existing `_parseCreatedSession`.
  - `Future<RoomSession?> respondToRematchInvite({roomId, accept})` — `null`
    on decline; on accept parse like `joinRoom`.
  - `Stream<List<RoomInvite>> watchRoomInvites({roomId})` —
    `client.from('room_invites').stream(primaryKey: ['room_id','user_id'])
    .eq('room_id', roomId)`, sorted by `createdAt` then `username`.
  - `Stream<List<RoomInvite>> watchMyRematchInvites({previousRoomId, userId})` —
    stream `.eq('user_id', userId)`, then filter `previous_room_id` client-side
    (Supabase streams accept one `eq`). Use a pure `rows → models` function so
    it is unit-testable (pattern: `lib/core/data/room_players_watcher.dart`).
- `RoomRepository` (domain) + `RoomRepositoryImpl`: mirror the four methods;
  futures wrapped `try { Right } catch (e) { Left(ServerFailure.from(e)) }`,
  streams passed through.

Cubits:
- `RoomCubit.createRematch({required RematchSeed seed, required String category,
  required int maxRounds, required int maxPlayers, required int roundDuration,
  required String username, List<String>? localPlayerNames})` — mirrors
  `createNewRoom` (same request-id/fingerprint idempotency, host username =
  first local name in local mode, remaining names sent as `localNames`),
  emits `RoomLoading` → `RoomWithPlayerCreated` | `RoomError(code)`.
- New `lib/features/room/presentation/cubit/rematch_invite_cubit.dart`
  (Game Over, non-host): `RematchInviteCubit({required RoomRepository
  repository, required String previousRoomId, required String userId})`.
  - `start()` subscribes to `watchMyRematchInvites`; the newest `pending`
    invite → `RematchInvited(invite)`; none → `RematchIdle`.
  - `accept()` → `RematchJoining(invite)` → `RematchJoined(roomId)` or
    `RematchFailed(code)`.
  - `decline()` → calls the RPC, emits `RematchIdle`, and ignores that invite
    afterwards even if the stream re-emits it before the server update lands.
  - Stream errors are swallowed (stay in current state); cancel on `close()`.
  - Never emits after close.
- New `lib/features/room/presentation/cubit/room_invites_cubit.dart`
  (Waiting Room, host): `RoomInvitesCubit({repository, roomId})`, state is
  `List<RoomInvite>` (empty by default), `start()` subscribes, errors ignored.
- Register both in `lib/core/di/injection_container.dart` as factories with
  parameters (`registerFactoryParam`), following existing style.

Errors: add `AppErrorCode.roomNotFinished` (`ROOM_NOT_FINISHED`) and
`AppErrorCode.inviteNotFound` (`INVITE_NOT_FOUND`) to `_dbCodes`, with cases
in `app_error_localizer.dart`.

Strings — add to **both** `app_en.arb` and `app_ar.arb`, then `flutter gen-l10n`:

| key | en | ar |
|---|---|---|
| `rematchInviteTitle` (placeholder `host`) | {host} wants to play again | {host} عايز يلعب تاني |
| `rematchInviteBody` | Join a new game with the same group. | انضم لجيم جديد مع نفس الشلة. |
| `rematchJoin` | Join | انضم |
| `rematchDecline` | No thanks | لا شكراً |
| `invitedPlayers` | Invited players | اللاعيبة المدعوين |
| `inviteStatusAccepted` | Joined | انضم |
| `inviteStatusPending` | Waiting… | مستني… |
| `inviteStatusDeclined` | Declined | رفض |
| `errRoomNotFinished` | This game hasn't finished yet. | الجيم ده لسه مخلصش. |
| `errInviteNotFound` | This invite is no longer available. | الدعوة دي مبقتش متاحة. |

`playAgain` already exists — reuse it (add the Arabic one only if missing).

Tests (Part A):
- `test/features/room/presentation/cubit/rematch_invite_cubit_test.dart`:
  idle → invited when a pending invite arrives; ignores invites for other
  previous rooms / non-pending; accept success → joined(roomId);
  accept failure → failed(code); decline → idle and stays idle when the same
  pending invite is re-emitted; no emit after close.
- `room_invites_cubit_test.dart`: emits the streamed list.
- `room_cubit_test.dart`: `createRematch` success and error; extend the existing
  hand-written `FakeRoomRepository` (no mocktail).
- Model test: `RoomInviteModel.fromJson` incl. unknown status;
  `RematchSeed.fromFinishedRoom` ordering for local mode, empty names online.
- Any other `implements RoomRepository` fakes in `test/` must get the new
  methods so the suite compiles.

### Part B — UI (after Part A)

- `GameEnded` → navigation sites (`game_end_navigation_listener.dart`,
  `local_mode_game_screen.dart`) add `'gameMode'` (String) to the Game Over
  `extra`. Router Game Over route passes `roomId` (path), `gameMode`
  (optional, default online), `currentUserId` (from `AuthSessionService`),
  `roomRepository`, and a `RematchInviteCubit` factory; extra keys stay
  optional so old callers/tests keep working.
- `GameOverView` (keep existing params and defaults):
  - `isHost` = the player whose `userId == currentUserId` has `isHost`.
  - Host: **Play Again** button (primary, above Back to Home; Back to Home
    becomes secondary/outlined). On tap, guarded like `_goHome` (single
    `_leaving` flag shared with Back to Home): fetch room via
    `roomRepository.getRoomDetails(roomId)` (show a spinner on the button;
    on failure show the localized error and re-enable), build
    `RematchSeed.fromFinishedRoom`, `await adService.showAfterGameIfReady()`,
    `if (!mounted) return;`, `context.go(AppRoutes.createRoom, extra: seed)`.
  - Non-host in Online Mode: provide and `start()` a `RematchInviteCubit`;
    `RematchInvited` → an invite card (not a dialog) pinned above the bottom
    buttons with Join / No thanks; `RematchJoining` → buttons disabled with
    spinner; `RematchJoined` → ad then `context.go(roomWaiting(newRoomId))`;
    `RematchFailed` → `ErrorSnackBar` with `localizedErrorMessage`.
  - Host name in the card = `players.firstWhere(isHost).username`.
- `CreateRoomView`: optional `RematchSeed? rematch`. When set: initial state
  from the seed, title `playAgain`, game mode selector shown but not
  changeable (wrap with `IgnorePointer` + reduced opacity, or add an
  `enabled` flag to `GameModeSelector`), category = seed.category if it is in
  the fetched active list, else the first one; `LocalPlayersInput` gets
  `initialNames: seed.localNames`; Create calls `RoomCubit.createRematch`.
  Router `createRoom` route reads `state.extra as RematchSeed?`.
- `LocalPlayersInput`: new optional `initialNames` (default empty) applied in
  `_initializeControllers` and notified once after the first frame.
- Waiting Room: router provides `RoomInvitesCubit` (started) alongside the
  existing `RoomCubit`. `WaitingRoomBody` shows an `InvitedPlayersSection`
  (new widget file under `views/widgets/`) for the host only when the list is
  non-empty, between the share button and the players list, with a bounded
  height (e.g. `ConstrainedBox(maxHeight: 140)` + scroll). Each row: name +
  status chip (Joined = success colour, Waiting… = muted, Declined = error).
  RTL-safe (Directional insets/alignment; Font Awesome directional icons via
  `DirectionalFaIcon`).
- Tests (Part B): GameOverView — host sees Play Again and non-host doesn't;
  non-host sees the invite card when the cubit is `RematchInvited` and Join
  calls `accept()`; Play Again and Back to Home cannot both fire
  (single-flight). CreateRoomView with a seed pre-fills and calls
  `createRematch`. LocalPlayersInput reports initial names. InvitedPlayersSection
  renders statuses and nothing for an empty list.

## Rules for implementers

- Keep Online and Shared-Device modes separate; authoritative state only via
  Supabase RPCs (never write `room_invites` / `rooms` directly).
- After every `await` in a widget: `if (!mounted) return;` before using
  `context`. No `BuildContext` across async gaps.
- No new packages. Follow existing patterns (Either/`ServerFailure.from`,
  hand-written fakes, `context.l10n`, `AppColors.of(context)`).
- Every user-visible string goes through l10n (en + ar).
- RTL-safe layout: `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`; `DirectionalFaIcon` for directional FA icons.
- Do not touch `supabase/`, do not commit, do not push.
- Use lean-ctx tools (`ctx_read`, `ctx_search`, `ctx_shell`, `ctx_patch`);
  native Grep/Glob are denied.
- Build/test env on this PC (PowerShell):
  `$env:PUB_CACHE='D:\pub_cache'; $env:TEMP='D:\pub_cache\tmp'; $env:TMP='D:\pub_cache\tmp'`
  then `flutter gen-l10n`, `dart format <changed files>`, `flutter analyze`,
  `flutter test`. All must pass before reporting done.
