import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimum connected players needed to skip or advance a phase.
const minConnectedPlayersToAdvance = 2;

/// Stable, language-neutral identifier for something a player may be told.
///
/// Cubits and failures carry a code; views turn it into text with
/// `localizedErrorMessage`. Raw exception text must never reach players.
///
/// The "notice" members at the end are not errors; they reuse the same
/// plumbing so auth snackbars can stay localized.
enum AppErrorCode {
  // Generic buckets.
  unknown,
  network,
  unauthorized,
  duplicateAction,
  invalidInput,

  // Stable codes raised by the database (exception message).
  authRequired,
  hostRequired,
  roomMemberRequired,
  roomParticipantRequired,
  roundParticipantRequired,
  roomNotFound,
  roundNotFound,
  playerNotFound,
  roomFull,
  roomAlreadyStarted,
  roomNotActive,
  notEnoughPlayers,
  onlineRoomRequired,
  invalidRoomSettings,
  invalidStaleSeconds,
  chatRateLimited,
  invalidChatContent,
  invalidReportReason,
  playerColumnUpdateForbidden,
  wrongPhase,
  votesIncomplete,
  usernameTaken,
  invalidUsername,

  // Client-side and constraint-derived gameplay codes.
  selfVote,
  notEnoughPlayersToAdvance,

  // Authentication.
  invalidCredentials,
  emailNotConfirmed,
  weakPassword,
  emailAlreadyRegistered,
  rateLimited,
  invalidEmail,
  accountAlreadyUpgraded,
  recoveryLinkInvalid,

  // Chat actions.
  chatLoadFailed,
  chatLoadOlderFailed,
  chatSendFailed,
  chatMuteFailed,
  chatConnectionInterrupted,
  reportFailed,

  // Notices (not errors).
  emailVerificationRequired,
  passwordResetRequested,
  accountUpgradeComplete,
  reportSubmitted,
}

const _dbCodes = <String, AppErrorCode>{
  'AUTH_REQUIRED': AppErrorCode.authRequired,
  'HOST_REQUIRED': AppErrorCode.hostRequired,
  'ROOM_MEMBER_REQUIRED': AppErrorCode.roomMemberRequired,
  'ROOM_PARTICIPANT_REQUIRED': AppErrorCode.roomParticipantRequired,
  'ROUND_PARTICIPANT_REQUIRED': AppErrorCode.roundParticipantRequired,
  'ROOM_NOT_FOUND': AppErrorCode.roomNotFound,
  'ROUND_NOT_FOUND': AppErrorCode.roundNotFound,
  'PLAYER_NOT_FOUND': AppErrorCode.playerNotFound,
  'ROOM_FULL': AppErrorCode.roomFull,
  'ROOM_ALREADY_STARTED': AppErrorCode.roomAlreadyStarted,
  'ROOM_NOT_ACTIVE': AppErrorCode.roomNotActive,
  'ROOM_FINISHED': AppErrorCode.roomNotActive,
  'NOT_ENOUGH_PLAYERS': AppErrorCode.notEnoughPlayers,
  'ONLINE_ROOM_REQUIRED': AppErrorCode.onlineRoomRequired,
  'INVALID_ROOM_SETTINGS': AppErrorCode.invalidRoomSettings,
  'INVALID_STALE_SECONDS': AppErrorCode.invalidStaleSeconds,
  'CHAT_RATE_LIMITED': AppErrorCode.chatRateLimited,
  'INVALID_CHAT_CONTENT': AppErrorCode.invalidChatContent,
  'INVALID_REPORT_REASON': AppErrorCode.invalidReportReason,
  'PLAYER_COLUMN_UPDATE_FORBIDDEN': AppErrorCode.playerColumnUpdateForbidden,
  'WRONG_PHASE': AppErrorCode.wrongPhase,
  'HINTS_PHASE_REQUIRED': AppErrorCode.wrongPhase,
  'VOTING_PHASE_REQUIRED': AppErrorCode.wrongPhase,
  'VOTES_INCOMPLETE': AppErrorCode.votesIncomplete,
  'USERNAME_TAKEN': AppErrorCode.usernameTaken,
  'DUPLICATE_LOCAL_USERNAME': AppErrorCode.usernameTaken,
  'INVALID_USERNAME': AppErrorCode.invalidUsername,
  'INVALID_CATEGORY': AppErrorCode.invalidInput,
  'INVALID_GAME_MODE': AppErrorCode.invalidInput,
  'INVALID_LOCAL_PLAYER_COUNT': AppErrorCode.invalidInput,
  'INVALID_EXTENSION_SECONDS': AppErrorCode.invalidInput,
  'REQUEST_ID_ALREADY_USED': AppErrorCode.duplicateAction,
};

final _upperToken = RegExp(r'[A-Z][A-Z0-9_]{3,}');
final _sqlStateInText = RegExp(r'code:\s*([0-9A-Z]{5})');

/// Maps any thrown object to a stable [AppErrorCode]. Never returns raw text.
///
/// Data sources often wrap the original error in `Exception('...: $error')`,
/// so the SQLSTATE and database code survive only inside the text. Plain
/// exceptions are therefore scanned for exact upper-case database codes and
/// `code: <SQLSTATE>` before any wording heuristics (auth/network only).
AppErrorCode appErrorCodeFrom(Object error) {
  if (error is PostgrestException) {
    return _dbCodes[error.message.trim()] ??
        _fromSqlState(error.code, '${error.message} ${error.details}') ??
        _fromText(error.toString());
  }
  if (error is AuthRetryableFetchException) return AppErrorCode.network;
  if (error is AuthException) return _fromAuth(error);
  if (error is SocketException ||
      error is TimeoutException ||
      // package:http ClientException is not a direct dependency.
      error.runtimeType.toString() == 'ClientException') {
    return AppErrorCode.network;
  }
  return _fromText(error.toString());
}

AppErrorCode? _fromSqlState(String? sqlState, String text) {
  switch (sqlState) {
    case '23505':
      return AppErrorCode.duplicateAction;
    case '23514':
      // The only user-reachable check constraint is votes_check (no self-vote).
      return text.contains('votes_check') || text.contains('"votes"')
          ? AppErrorCode.selfVote
          : AppErrorCode.invalidInput;
    case '42501':
      return AppErrorCode.unauthorized;
    case '22023':
      return AppErrorCode.invalidInput;
    case '28000':
    case 'PGRST301':
      return AppErrorCode.authRequired;
  }
  return null;
}

AppErrorCode _fromAuth(AuthException error) {
  switch (error.code?.toLowerCase()) {
    case 'invalid_credentials':
      return AppErrorCode.invalidCredentials;
    case 'email_not_confirmed':
      return AppErrorCode.emailNotConfirmed;
    case 'user_already_exists':
    case 'email_exists':
      return AppErrorCode.emailAlreadyRegistered;
    case 'weak_password':
      return AppErrorCode.weakPassword;
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return AppErrorCode.rateLimited;
    case 'email_address_invalid':
      return AppErrorCode.invalidEmail;
  }
  if (error.statusCode == '429') return AppErrorCode.rateLimited;
  return _fromText(error.message);
}

AppErrorCode _fromText(String text) {
  for (final match in _upperToken.allMatches(text)) {
    final code = _dbCodes[match.group(0)];
    if (code != null) return code;
  }
  final sqlState = _sqlStateInText.firstMatch(text)?.group(1);
  final byState = _fromSqlState(sqlState, text);
  if (byState != null) return byState;

  final lower = text.toLowerCase();
  bool has(String s) => lower.contains(s);

  if (has('invalid login credentials') || has('invalid_credentials')) {
    return AppErrorCode.invalidCredentials;
  }
  if (has('email not confirmed') ||
      has('email_not_confirmed') ||
      has('verify your email')) {
    return AppErrorCode.emailNotConfirmed;
  }
  if (has('user already registered') ||
      has('user_already_exists') ||
      has('email_exists')) {
    return AppErrorCode.emailAlreadyRegistered;
  }
  if (has('weak_password') || (has('password') && has('weak'))) {
    return AppErrorCode.weakPassword;
  }
  if (has('rate limit') || has('too many requests')) {
    return AppErrorCode.rateLimited;
  }
  if (has('email_address_invalid') || (has('email') && has('invalid'))) {
    return AppErrorCode.invalidEmail;
  }
  if (has('sign in before upgrading')) return AppErrorCode.authRequired;
  if (has('already uses a real email')) {
    return AppErrorCode.accountAlreadyUpgraded;
  }
  if (has('recovery session') && has('no longer')) {
    return AppErrorCode.recoveryLinkInvalid;
  }
  if (has('socketexception') ||
      has('timeoutexception') ||
      has('clientexception') ||
      has('failed host lookup') ||
      has('no address associated with hostname') ||
      has('connection refused') ||
      has('connection closed') ||
      has('connection reset') ||
      has('network is unreachable')) {
    return AppErrorCode.network;
  }
  return AppErrorCode.unknown;
}
