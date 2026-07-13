import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/presentation/reconnect_notice_gate.dart';

void main() {
  final start = DateTime.utc(2030, 1, 1, 12);

  test('shows back-online notice exactly once for a valid reconnect cycle', () {
    final gate = ReconnectNoticeGate();
    gate.startCycle(start);

    expect(gate.shouldShowBackOnline(start.add(const Duration(seconds: 2))), isTrue);
    expect(gate.shouldShowBackOnline(start.add(const Duration(seconds: 3))), isFalse);
  });

  test('suppresses short reconnects and cooldown stacking deterministically', () {
    final gate = ReconnectNoticeGate();
    gate.startCycle(start);
    expect(gate.shouldShowBackOnline(start.add(const Duration(milliseconds: 500))), isFalse);

    gate.startCycle(start.add(const Duration(seconds: 2)));
    expect(gate.shouldShowBackOnline(start.add(const Duration(seconds: 4))), isTrue);

    gate.startCycle(start.add(const Duration(seconds: 5)));
    expect(gate.shouldShowBackOnline(start.add(const Duration(seconds: 7))), isFalse);

    gate.startCycle(start.add(const Duration(seconds: 11)));
    expect(gate.shouldShowBackOnline(start.add(const Duration(seconds: 12))), isTrue);
  });
}
