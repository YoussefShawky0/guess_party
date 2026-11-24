import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/shared/widgets/directional_fa_icon.dart';

Future<Matrix4> _transformFor(WidgetTester tester, TextDirection dir) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: dir,
      child: const DirectionalFaIcon(FontAwesomeIcons.chevronRight),
    ),
  );
  return tester.widget<Transform>(find.byType(Transform)).transform;
}

void main() {
  testWidgets('mirrors in RTL and not in LTR', (tester) async {
    expect((await _transformFor(tester, TextDirection.ltr)).entry(0, 0), 1);
    expect((await _transformFor(tester, TextDirection.rtl)).entry(0, 0), -1);
  });

  group('Character.displayName', () {
    const c = Character(
      id: '1',
      name: 'تفاح',
      nameEn: 'Apple',
      emoji: '🍎',
      category: 'fruits_vegetables',
      difficulty: 'easy',
      isActive: true,
    );

    test('English locale shows the English name', () {
      expect(c.displayName('en'), 'Apple');
    });

    test('Arabic locale shows the Arabic name', () {
      expect(c.displayName('ar'), 'تفاح');
    });

    test('missing English name falls back to Arabic', () {
      const old = Character(
        id: '2',
        name: 'موز',
        emoji: '🍌',
        category: 'fruits_vegetables',
        difficulty: 'easy',
        isActive: true,
      );
      expect(old.displayName('en'), 'موز');
    });
  });
}
