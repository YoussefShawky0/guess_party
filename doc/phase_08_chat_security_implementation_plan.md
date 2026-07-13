# Phase 8 — Chat Security and Reliability Implementation Runbook

## Table of Contents

- [Objective](#objective)
- [Starting State and Gate](#starting-state-and-gate)
- [Locked Design](#locked-design)
- [Database Implementation](#database-implementation)
- [Flutter Implementation](#flutter-implementation)
- [Ordered Tasks](#ordered-tasks)
- [Test Plan](#test-plan)
- [Stop Conditions](#stop-conditions)
- [Required Report](#required-report)
- [Reviewer Checklist](#reviewer-checklist)

## Objective

Make round-scoped chat safe and bounded without changing gameplay phases. The
server must enforce identity, membership, content length, throttling, and report
ownership. The client must use cursor pagination and exactly one Realtime
subscription without message duplication.

## Starting State and Gate

Before editing:

```powershell
git status --short
flutter analyze
flutter test
supabase test db
```

Phase 7 must be committed and the working tree must contain no unrelated
changes. If Docker reconstruction is required, use only:

```powershell
supabase stop --no-backup
supabase start --ignore-health-check
```

Current facts:

- `messages` is round-scoped and limited to 1–500 characters.
- Existing RLS checks room membership and message ownership.
- `SupabaseChatRepository.getMessages` fetches unlimited history.
- Each Realtime change currently triggers a full-history query.
- `ChatWidget` owns subscription and mutable message logic.

## Locked Design

- Page size: default 30, maximum 50.
- Sort key: `(created_at DESC, id DESC)`; cursors contain both values.
- Send limit: five accepted messages per player per rolling ten seconds.
- Sending uses `send_chat_message`; clients cannot insert directly.
- The server derives the sender from `auth.uid()` and room membership. No
  caller-supplied `player_id` is accepted by the RPC.
- Realtime remains on `public.messages`; one owner merges inserts by message ID.
- A mute hides messages only for the muting player. It does not alter delivery,
  delete content, or punish the muted player.
- Reports are immutable user submissions with auditable status. This phase does
  not add automatic bans, admin dashboards, public matchmaking, push
  notifications, or unread counts.

## Database Implementation

Create one canonical migration named with the next real timestamp and suffix
`_chat_security_and_reliability.sql`. Never edit an applied canonical migration.

### Tables

Implement the following schema contract, adapting only constraint names to the
repository convention:

```sql
create table public.player_mutes (
  room_id uuid not null references public.rooms(id) on delete cascade,
  muter_player_id uuid not null references public.players(id) on delete cascade,
  muted_player_id uuid not null references public.players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (room_id, muter_player_id, muted_player_id),
  constraint player_mutes_no_self check (muter_player_id <> muted_player_id)
);

create table public.message_reports (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  reporter_player_id uuid not null references public.players(id) on delete cascade,
  reason text not null check (char_length(btrim(reason)) between 1 and 500),
  status text not null default 'open'
    check (status in ('open', 'reviewed', 'dismissed', 'actioned')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (message_id, reporter_player_id)
);
```

Enable RLS. A player may select and manage only their own mute rows. An
authenticated room participant may insert one report for a message in their
room, but clients must not update report status. Only `service_role` may read or
moderate all reports. Grant no report moderation capability to `anon` or
`authenticated`.

### Send RPC

Implement this public interface:

```sql
public.send_chat_message(
  p_room_id uuid,
  p_round_id uuid,
  p_content text
) returns jsonb
```

The security-definer function must set `search_path = ''` and:

1. Require `auth.uid()`.
2. Trim content and enforce 1–500 characters.
3. Lock per authenticated user with `pg_advisory_xact_lock` so concurrent sends
   cannot race the rate check.
4. Resolve exactly one online or current room player whose `user_id` equals
   `auth.uid()` and whose room matches `p_room_id`.
5. Verify `p_round_id` belongs to that room and the player is a round
   participant.
6. Reject when five messages by that player exist in the preceding ten seconds
   with error `CHAT_RATE_LIMITED`.
7. Insert the message and return its ID, room ID, round ID, player ID, content,
   created time, and current username.

Revoke direct `INSERT` on `public.messages` from `anon` and `authenticated`.
Grant RPC execution to `authenticated` only. Retain RLS SELECT protection and
Realtime publication membership.

### Pagination RPC

Implement:

```sql
public.list_chat_messages(
  p_room_id uuid,
  p_round_id uuid,
  p_before_created_at timestamptz default null,
  p_before_id uuid default null,
  p_limit integer default 30
) returns table (
  id uuid,
  room_id uuid,
  round_id uuid,
  player_id uuid,
  username text,
  content text,
  created_at timestamptz
)
```

Require membership, clamp/validate the limit to 1–50, require both cursor fields
together, and use:

```sql
and (
  p_before_created_at is null
  or (m.created_at, m.id) < (p_before_created_at, p_before_id)
)
order by m.created_at desc, m.id desc
limit p_limit
```

### Moderation RPCs

Add authenticated, membership-checking functions:

```sql
public.set_player_muted(p_room_id uuid, p_muted_player_id uuid, p_muted boolean)
  returns void

public.report_chat_message(p_message_id uuid, p_reason text)
  returns uuid
```

Both functions derive the caller's player ID from `auth.uid()`. Duplicate report
submission must be idempotent or return a stable human-mappable
`MESSAGE_ALREADY_REPORTED` error; choose idempotent return of the existing ID.

## Flutter Implementation

Replace map-based public chat contracts with immutable typed models:

```dart
class ChatCursor {
  const ChatCursor({required this.createdAt, required this.id});
  final DateTime createdAt;
  final String id;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.roundId,
    required this.playerId,
    required this.username,
    required this.content,
    required this.createdAt,
  });
  // fields above; equality by id and immutable value fields
}

class ChatPage {
  const ChatPage({required this.messages, required this.nextCursor});
  final List<ChatMessage> messages;
  final ChatCursor? nextCursor;
}
```

Use this repository interface:

```dart
abstract interface class ChatRepository {
  Future<ChatPage> getMessages({
    required String roomId,
    required String roundId,
    ChatCursor? before,
    int limit = 30,
  });

  Stream<ChatMessage> watchNewMessages({
    required String roomId,
    required String roundId,
  });

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String roundId,
    required String content,
  });

  Future<void> setMuted({
    required String roomId,
    required String playerId,
    required bool muted,
  });

  Future<void> reportMessage({
    required String messageId,
    required String reason,
  });
}
```

Create a `ChatCubit` or equivalent presentation coordinator as the only owner of
initial loading, older-page loading, the Realtime subscription, deduplication,
send state, mute filtering, and retry state. Keep messages keyed by ID and sort
ascending for display. A repeated Realtime insert must update/ignore that ID,
never append a duplicate.

`ChatWidget` becomes rendering and user-intent forwarding only. Add:

- load-older control or top-scroll pagination;
- long-press actions for mute/unmute and report;
- generic player-safe rate-limit and send failure copy;
- mounted-safe dialogs/snackbars;
- no technical exception text in the UI.

## Ordered Tasks

| ID | Task |
|---|---|
| P8-001 | Run baseline gate and record current chat channel/query counts |
| P8-002 | Add failing database contracts for membership, impersonation, throttling, pagination, mutes, and reports |
| P8-003 | Add the canonical chat migration and exact grants/RLS policies |
| P8-004 | Add typed chat models and update the repository contract |
| P8-005 | Implement RPC-backed repository methods and one insert stream |
| P8-006 | Add ChatCubit/coordinator with pagination and ID deduplication |
| P8-007 | Reduce ChatWidget to presentation and add mute/report UI |
| P8-008 | Add repository, Cubit, widget, reconnect, and disposal tests |
| P8-009 | Run clean local construction and the complete regression gate |
| P8-010 | Update the master ledger and stop for senior review |

## Test Plan

Database tests must prove actual denial/error behavior for:

- non-member SELECT, pagination, send, mute, and report;
- caller-supplied impersonation being impossible;
- sixth message inside ten seconds rejected and a later message accepted using a
  deterministic test clock/controlled timestamps;
- cursor pages containing no duplicate or skipped IDs when timestamps tie;
- report status cannot be changed by an authenticated client;
- duplicate report and mute operations are deterministic;
- direct message INSERT is unavailable to authenticated clients.

Flutter tests must prove:

- first page is bounded to 30 and older pages merge correctly;
- one channel exists per active round and is replaced on round change;
- reconnect/repeated events do not duplicate messages;
- disposal cancels the channel;
- muted-player messages are hidden only for that viewer;
- report/mute dialogs do not use stale context;
- server errors map to concise, non-technical copy.

Final commands:

```powershell
flutter analyze
flutter test
supabase test db
rg -n "Supabase\.instance|\.from\('messages'\)|\.channel\(" lib/shared lib/features/chat
```

Expected: analyzer clean, every Flutter/database test passes, and Supabase calls
exist only in the chat data implementation.

## Stop Conditions

Stop and report without workaround if Phase 7 is uncommitted, authoritative
schema construction fails, a required production change appears necessary,
message Realtime cannot be retained without weakening RLS, or a migration would
change gameplay RPC/wire contracts.

Do not deploy migrations remotely and do not start Phase 9.

## Required Report

Report task IDs completed, exact migration/RPC/grant changes, changed files,
channel counts before/after, full test output, manual chat/reconnect results,
production-change confirmation, and residual risks.

## Reviewer Checklist

- [ ] Direct INSERT cannot bypass rate limiting.
- [ ] Sender identity comes only from `auth.uid()` membership.
- [ ] Pagination ordering is deterministic.
- [ ] Realtime uses one owner and deduplicates IDs.
- [ ] Mutes/reports cannot target another room or be impersonated.
- [ ] No secret gameplay state or chat content enters telemetry.
- [ ] Full gameplay and Shared-Device regression gates pass.
