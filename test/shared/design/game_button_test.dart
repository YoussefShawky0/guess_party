import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/shared/design/game_button.dart';
import 'package:guess_party/shared/design/player_avatar.dart';

import '../../helpers/game_ui_helpers.dart';

const _longArabic =
    'ابدأ لعبة جديدة مع كل أصدقائك وعائلتك دلوقتي حالا وخلينا نشوف مين الإمبوستر';

void main() {
  setUpAll(loadGameFonts);

  final face = find.byKey(const Key('game-button-face'));

  Widget button({
    VoidCallback? onPressed,
    String label = 'Create room',
    GameButtonVariant variant = GameButtonVariant.primary,
    GameButtonSize size = GameButtonSize.lg,
    bool isLoading = false,
    double width = 320,
  }) => Center(
    child: SizedBox(
      width: width,
      child: GameButton(
        label: label,
        onPressed: onPressed,
        variant: variant,
        size: size,
        isLoading: isLoading,
        icon: const Icon(Icons.add),
      ),
    ),
  );

  testWidgets('press moves the face down and release restores it', (
    tester,
  ) async {
    await tester.pumpWidget(
      gameTestApp(
        home: Scaffold(body: button(onPressed: () {})),
      ),
    );
    // The face is a Transform, so measure a child that moves with it.
    final label = find.text('Create room');
    final rest = tester.getTopLeft(label).dy;

    final gesture = await tester.startGesture(tester.getCenter(face));
    await tester.pump(); // starts the implicit animation
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(label).dy, closeTo(rest + 4, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(label).dy, rest);
  });

  testWidgets('tapHaptic is called once per tap and never when disabled', (
    tester,
  ) async {
    final feedback = CountingFeedback();
    var pressed = 0;
    await tester.pumpWidget(
      gameTestApp(
        feedback: feedback,
        home: Scaffold(body: button(onPressed: () => pressed++)),
      ),
    );

    await tester.tap(find.byType(GameButton));
    await tester.pumpAndSettle();
    expect(feedback.taps, 1);
    expect(pressed, 1);

    await tester.tap(find.byType(GameButton));
    await tester.pumpAndSettle();
    expect(feedback.taps, 2);
    expect(pressed, 2);

    await tester.pumpWidget(
      gameTestApp(
        feedback: feedback,
        home: Scaffold(body: button(onPressed: null)),
      ),
    );
    await tester.tap(find.byType(GameButton));
    await tester.pumpAndSettle();
    expect(feedback.taps, 2);
  });

  testWidgets('loading ignores taps and shows a spinner', (tester) async {
    final feedback = CountingFeedback();
    var pressed = 0;
    await tester.pumpWidget(
      gameTestApp(
        feedback: feedback,
        home: Scaffold(
          body: button(onPressed: () => pressed++, isLoading: true),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(GameButton), warnIfMissed: false);
    await tester.pump();
    expect(pressed, 0);
    expect(feedback.taps, 0);
  });

  testWidgets('exposes a button role with its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      gameTestApp(
        home: Scaffold(body: button(onPressed: () {})),
      ),
    );
    expect(
      tester.getSemantics(find.byType(GameButton)),
      isSemantics(isButton: true, label: 'Create room', isEnabled: true),
    );

    await tester.pumpWidget(
      gameTestApp(home: Scaffold(body: button(onPressed: null))),
    );
    expect(
      tester.getSemantics(find.byType(GameButton)),
      isSemantics(isButton: true, label: 'Create room', isEnabled: false),
    );
    handle.dispose();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
        'a long Arabic label does not overflow (${locale.languageCode}, x$scale)',
        (tester) async {
          for (final variant in GameButtonVariant.values) {
            for (final size in GameButtonSize.values) {
              await tester.pumpWidget(
                gameTestApp(
                  locale: locale,
                  textScale: scale,
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: button(
                        onPressed: () {},
                        label: _longArabic,
                        variant: variant,
                        size: size,
                        width: 280,
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
          // The button grows instead of clipping.
          expect(tester.getSize(face).height, greaterThanOrEqualTo(48));
        },
      );
    }
  }

  testWidgets('minHeight is a minimum: the button grows with the text', (
    tester,
  ) async {
    await tester.pumpWidget(
      gameTestApp(
        textScale: 2,
        home: Scaffold(
          body: button(onPressed: () {}, label: _longArabic),
        ),
      ),
    );
    expect(tester.getSize(face).height, greaterThan(56));
  });

  test('PlayerAvatar picks a stable color and initial per name', () {
    expect(PlayerAvatar.colorFor('Sam'), PlayerAvatar.colorFor('  sam '));
    expect(PlayerAvatar.stableHash('abc'), PlayerAvatar.stableHash('abc'));
    expect(PlayerAvatar.initialOf(' sam'), 'S');
    expect(PlayerAvatar.initialOf('يوسف'), 'ي');
    expect(PlayerAvatar.initialOf('  '), '?');
  });

  testWidgets('PlayerAvatar shows the warning dot only when asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      gameTestApp(
        home: const Scaffold(body: PlayerAvatar(name: 'Sam')),
      ),
    );
    expect(find.byKey(const Key('player-avatar-dot')), findsNothing);
    await tester.pumpWidget(
      gameTestApp(
        home: const Scaffold(body: PlayerAvatar(name: 'Sam', showDot: true)),
      ),
    );
    expect(find.byKey(const Key('player-avatar-dot')), findsOneWidget);
  });
}
