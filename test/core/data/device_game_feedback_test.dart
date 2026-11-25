import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/data/device_game_feedback.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeCuePlayer implements CuePlayer {
  final sounds = <GameCue>[];
  final vibrations = <GameCue>[];
  bool throwOnPlay = false;
  int preloads = 0;
  int lightTaps = 0;

  @override
  Future<void> lightTap() async {
    if (throwOnPlay) throw StateError('no haptics');
    lightTaps++;
  }

  @override
  Future<void> preload() async => preloads++;

  @override
  Future<void> playSound(GameCue cue) async {
    if (throwOnPlay) throw StateError('no audio');
    sounds.add(cue);
  }

  @override
  Future<void> vibrate(GameCue cue) async {
    if (throwOnPlay) throw StateError('no haptics');
    vibrations.add(cue);
  }
}

void main() {
  late FakeCuePlayer player;

  Future<DeviceGameFeedback> build() async => DeviceGameFeedback(
    preferences: await SharedPreferences.getInstance(),
    player: player,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    player = FakeCuePlayer();
  });

  test('both toggles default to enabled', () async {
    final feedback = await build();
    expect(feedback.soundEnabled, isTrue);
    expect(feedback.hapticsEnabled, isTrue);
  });

  test('toggles persist under the documented keys', () async {
    final feedback = await build();
    await feedback.setSoundEnabled(false);
    await feedback.setHapticsEnabled(false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('feedback.sound_enabled'), isFalse);
    expect(prefs.getBool('feedback.haptics_enabled'), isFalse);

    final reloaded = await build();
    expect(reloaded.soundEnabled, isFalse);
    expect(reloaded.hapticsEnabled, isFalse);
  });

  test('stored values are restored', () async {
    SharedPreferences.setMockInitialValues({
      'feedback.sound_enabled': false,
      'feedback.haptics_enabled': true,
    });
    final feedback = await build();
    expect(feedback.soundEnabled, isFalse);
    expect(feedback.hapticsEnabled, isTrue);
  });

  test('play honours each toggle independently', () async {
    final feedback = await build();
    await feedback.play(GameCue.voteCast);
    expect(player.sounds, [GameCue.voteCast]);
    expect(player.vibrations, [GameCue.voteCast]);

    await feedback.setSoundEnabled(false);
    await feedback.play(GameCue.tick);
    expect(player.sounds, [GameCue.voteCast]);
    expect(player.vibrations, [GameCue.voteCast, GameCue.tick]);

    await feedback.setHapticsEnabled(false);
    await feedback.play(GameCue.gameWon);
    expect(player.sounds, [GameCue.voteCast]);
    expect(player.vibrations, [GameCue.voteCast, GameCue.tick]);
  });

  test('play and preload never throw when the platform fails', () async {
    final feedback = await build();
    player.throwOnPlay = true;
    await feedback.play(GameCue.gameLost);
    await feedback.preload();
    expect(player.preloads, 1);
  });

  test('tapHaptic is a light haptic only and honours the toggle', () async {
    final feedback = await build();
    await feedback.tapHaptic();
    expect(player.lightTaps, 1);
    expect(player.sounds, isEmpty);
    expect(player.vibrations, isEmpty);

    await feedback.setHapticsEnabled(false);
    await feedback.tapHaptic();
    expect(player.lightTaps, 1);
  });

  test('tapHaptic never throws when the platform fails', () async {
    final feedback = await build();
    player.throwOnPlay = true;
    await feedback.tapHaptic();
    await SilentGameFeedback().tapHaptic();
  });

  test('silent feedback keeps toggles in memory and plays nothing', () async {
    final silent = SilentGameFeedback();
    expect(silent.soundEnabled, isTrue);
    await silent.setSoundEnabled(false);
    await silent.setHapticsEnabled(false);
    expect(silent.soundEnabled, isFalse);
    expect(silent.hapticsEnabled, isFalse);
    await silent.play(GameCue.tick);
  });
}
