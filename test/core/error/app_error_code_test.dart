import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('appErrorCodeFrom', () {
    test('maps exact database codes by message', () {
      expect(
        appErrorCodeFrom(
          const PostgrestException(message: 'HOST_REQUIRED', code: '42501'),
        ),
        AppErrorCode.hostRequired,
      );
      expect(
        appErrorCodeFrom(
          const PostgrestException(message: 'ROOM_FULL', code: 'P0001'),
        ),
        AppErrorCode.roomFull,
      );
      expect(
        appErrorCodeFrom(
          const PostgrestException(message: 'CHAT_RATE_LIMITED'),
        ),
        AppErrorCode.chatRateLimited,
      );
    });

    test('maps unique violations to duplicateAction, not an email error', () {
      final code = appErrorCodeFrom(
        const PostgrestException(
          message:
              'duplicate key value violates unique constraint "votes_pkey"',
          code: '23505',
        ),
      );
      expect(code, AppErrorCode.duplicateAction);
      expect(code, isNot(AppErrorCode.emailAlreadyRegistered));
    });

    test('maps the votes check violation to selfVote', () {
      expect(
        appErrorCodeFrom(
          const PostgrestException(
            message:
                'new row for relation "votes" violates check constraint "votes_check"',
            code: '23514',
          ),
        ),
        AppErrorCode.selfVote,
      );
      expect(
        appErrorCodeFrom(
          const PostgrestException(message: 'something else', code: '23514'),
        ),
        AppErrorCode.invalidInput,
      );
    });

    test('maps permission errors by SQLSTATE', () {
      expect(
        appErrorCodeFrom(
          const PostgrestException(message: 'permission denied', code: '42501'),
        ),
        AppErrorCode.unauthorized,
      );
    });

    test('ROUND_NOT_FOUND and PLAYER_NOT_FOUND are not auth errors', () {
      expect(
        appErrorCodeFrom(const PostgrestException(message: 'ROUND_NOT_FOUND')),
        AppErrorCode.roundNotFound,
      );
      expect(
        appErrorCodeFrom(const PostgrestException(message: 'PLAYER_NOT_FOUND')),
        AppErrorCode.playerNotFound,
      );
    });

    test('finds codes in errors wrapped by data sources', () {
      expect(
        appErrorCodeFrom(
          Exception(
            'Failed to submit hint: PostgrestException(message: HOST_REQUIRED, code: 42501)',
          ),
        ),
        AppErrorCode.hostRequired,
      );
      expect(
        appErrorCodeFrom(
          Exception(
            'Failed to submit vote: PostgrestException(message: new row for '
            'relation "votes" violates check constraint "votes_check", '
            'code: 23514)',
          ),
        ),
        AppErrorCode.selfVote,
      );
      expect(
        appErrorCodeFrom(StateError('ROOM_NOT_FOUND')),
        AppErrorCode.roomNotFound,
      );
    });

    test('maps auth exceptions by code', () {
      expect(
        appErrorCodeFrom(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        AppErrorCode.invalidCredentials,
      );
      expect(
        appErrorCodeFrom(
          const AuthApiException(
            'Email not confirmed',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        ),
        AppErrorCode.emailNotConfirmed,
      );
      expect(
        appErrorCodeFrom(
          const AuthApiException(
            'User already registered',
            statusCode: '422',
            code: 'user_already_exists',
          ),
        ),
        AppErrorCode.emailAlreadyRegistered,
      );
      expect(
        appErrorCodeFrom(
          const AuthApiException(
            'Password is too weak',
            statusCode: '422',
            code: 'weak_password',
          ),
        ),
        AppErrorCode.weakPassword,
      );
      expect(
        appErrorCodeFrom(
          const AuthApiException('slow down', statusCode: '429'),
        ),
        AppErrorCode.rateLimited,
      );
      expect(
        appErrorCodeFrom(
          const AuthApiException(
            'Email address "x" is invalid',
            statusCode: '400',
            code: 'email_address_invalid',
          ),
        ),
        AppErrorCode.invalidEmail,
      );
    });

    test('maps network exceptions', () {
      expect(
        appErrorCodeFrom(const SocketException('Failed host lookup')),
        AppErrorCode.network,
      );
      expect(appErrorCodeFrom(TimeoutException('slow')), AppErrorCode.network);
      expect(
        appErrorCodeFrom(AuthRetryableFetchException(message: 'offline')),
        AppErrorCode.network,
      );
      expect(
        appErrorCodeFrom(Exception('SocketException: Connection refused')),
        AppErrorCode.network,
      );
    });

    test('does not treat the word connection as a network error', () {
      expect(
        appErrorCodeFrom(Exception('connection pool configured')),
        AppErrorCode.unknown,
      );
    });

    test('unknown errors map to unknown and never expose raw text', () {
      final code = appErrorCodeFrom(Exception('NullPointer at 0xdeadbeef'));
      expect(code, AppErrorCode.unknown);
      final text = localizedErrorMessage(
        lookupAppLocalizations(const Locale('en')),
        code,
      );
      expect(text, isNot(contains('NullPointer')));
      expect(text, isNot(contains('deadbeef')));
    });
  });

  group('localizedErrorMessage', () {
    test('every AppErrorCode has a non-empty en and ar message', () {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        final l10n = lookupAppLocalizations(locale);
        for (final code in AppErrorCode.values) {
          expect(
            localizedErrorMessage(l10n, code).trim(),
            isNotEmpty,
            reason: '$code missing for $locale',
          );
        }
      }
    });

    test('Arabic messages differ from English ones', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ar = lookupAppLocalizations(const Locale('ar'));
      for (final code in AppErrorCode.values) {
        expect(
          localizedErrorMessage(ar, code),
          isNot(localizedErrorMessage(en, code)),
          reason: '$code is not translated',
        );
      }
    });
  });
}
