import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'package:guess_party/core/data/device_game_feedback.dart';
import 'package:guess_party/core/services/game_feedback.dart';

/// [CuePlayer] backed by audioplayers (one low-latency player per cue) and
/// [HapticFeedback]. Sounds mix with other apps and never take audio focus.
class AudioplayersCuePlayer implements CuePlayer {
  final Map<GameCue, AudioPlayer> _players = {};

  static const _assets = <GameCue, String>{
    GameCue.tick: 'sounds/tick.wav',
    GameCue.phaseStart: 'sounds/phase_start.wav',
    GameCue.voteCast: 'sounds/vote_cast.wav',
    GameCue.imposterCaught: 'sounds/imposter_caught.wav',
    GameCue.imposterEscaped: 'sounds/imposter_escaped.wav',
    GameCue.gameWon: 'sounds/game_won.wav',
    GameCue.gameLost: 'sounds/game_lost.wav',
  };

  @override
  Future<void> preload() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.sonification,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
    for (final entry in _assets.entries) {
      final player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _players[entry.key] = player;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(entry.value));
    }
  }

  @override
  Future<void> playSound(GameCue cue) async {
    final player = _players[cue];
    if (player == null) return;
    await player.play(AssetSource(_assets[cue]!));
  }

  @override
  Future<void> vibrate(GameCue cue) {
    switch (cue) {
      case GameCue.tick:
        return HapticFeedback.selectionClick();
      case GameCue.voteCast:
        return HapticFeedback.lightImpact();
      case GameCue.phaseStart:
      case GameCue.gameLost:
        return HapticFeedback.mediumImpact();
      case GameCue.imposterCaught:
      case GameCue.imposterEscaped:
      case GameCue.gameWon:
        return HapticFeedback.heavyImpact();
    }
  }
}
