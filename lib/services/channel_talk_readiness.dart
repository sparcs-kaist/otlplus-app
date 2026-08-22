import 'dart:async';

class ChannelTalkReadiness {
  final Completer<bool> _completer = Completer<bool>();

  Future<bool> get isReady => _completer.future;

  void markBooted() {
    if (!_completer.isCompleted) _completer.complete(true);
  }

  void markUnavailable() {
    if (!_completer.isCompleted) _completer.complete(false);
  }
}

final sharedChannelTalkReadiness = ChannelTalkReadiness();
