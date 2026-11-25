import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/feedback/game_cues.dart';

/// Reads the app-wide [GameFeedback]; falls back to a silent one when no
/// provider is above [context] (e.g. in isolated widget tests).
GameFeedback gameFeedbackOf(BuildContext context) {
  try {
    return RepositoryProvider.of<GameFeedback>(context, listen: false);
  } catch (_) {
    return _fallback;
  }
}

final GameFeedback _fallback = SilentGameFeedback();

/// Plays the countdown tick for the last five seconds of a timed phase.
void playTickIfDue(BuildContext context, int remainingSeconds) {
  if (!isTickSecond(remainingSeconds)) return;
  unawaited(gameFeedbackOf(context).play(GameCue.tick));
}

/// Turns [GameCubit] transitions and accepted votes into feedback cues.
class GameFeedbackListener extends StatefulWidget {
  const GameFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  State<GameFeedbackListener> createState() => _GameFeedbackListenerState();
}

class _GameFeedbackListenerState extends State<GameFeedbackListener> {
  StreamSubscription<GameState>? _stateSubscription;
  StreamSubscription<void>? _voteSubscription;
  GameState? _previous;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stateSubscription != null) return;
    final cubit = context.read<GameCubit>();
    _previous = cubit.state;
    _stateSubscription = cubit.stream.listen(_onState);
    _voteSubscription = cubit.voteAccepted.listen(
      (_) => _play(const [GameCue.voteCast]),
    );
  }

  void _onState(GameState next) {
    final previous = _previous;
    _previous = next;
    try {
      _play(cuesForTransition(previous, next));
    } catch (_) {
      // Feedback must never throw into gameplay.
    }
  }

  void _play(List<GameCue> cues) {
    if (!mounted || cues.isEmpty) return;
    final feedback = gameFeedbackOf(context);
    for (final cue in cues) {
      unawaited(feedback.play(cue));
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _voteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
