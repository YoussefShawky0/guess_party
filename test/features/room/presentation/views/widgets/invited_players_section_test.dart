import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/presentation/views/widgets/invited_players_section.dart';
import 'package:guess_party/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

RoomInvite _i(String name, RoomInviteStatus s) => RoomInvite(
  roomId: 'r',
  previousRoomId: 'p',
  userId: name,
  username: name,
  status: s,
);

void main() {
  testWidgets('renders each invite with its status', (tester) async {
    await tester.pumpWidget(
      _wrap(
        InvitedPlayersSection(
          invites: [
            _i('Ann', RoomInviteStatus.accepted),
            _i('Bob', RoomInviteStatus.pending),
            _i('Cid', RoomInviteStatus.declined),
          ],
        ),
      ),
    );
    expect(find.text('Invited players'), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Waiting…'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
  });

  testWidgets('renders nothing when empty', (tester) async {
    await tester.pumpWidget(_wrap(const InvitedPlayersSection(invites: [])));
    expect(find.text('Invited players'), findsNothing);
  });

  testWidgets('scope renders nothing without a cubit provider', (tester) async {
    await tester.pumpWidget(_wrap(const InvitedPlayersScope()));
    expect(find.text('Invited players'), findsNothing);
  });
}
