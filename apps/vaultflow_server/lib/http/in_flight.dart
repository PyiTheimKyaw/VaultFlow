import 'dart:async';

import 'package:dart_frog/dart_frog.dart';

/// Counts requests currently being handled so shutdown can wait for them.
class InFlightTracker {
  int _count = 0;
  final _idle = <Completer<void>>[];

  int get count => _count;

  void _start() => _count++;

  void _finish() {
    _count--;
    if (_count == 0) {
      for (final c in _idle) {
        c.complete();
      }
      _idle.clear();
    }
  }

  /// Completes once no request is in flight, or after [timeout]. Returns
  /// whether the server actually drained.
  Future<bool> drain(Duration timeout) async {
    if (_count == 0) return true;
    final completer = Completer<void>();
    _idle.add(completer);
    var drained = true;
    await completer.future.timeout(
      timeout,
      onTimeout: () {
        drained = false;
        _idle.remove(completer);
      },
    );
    return drained;
  }
}

/// Registers every request with [tracker] for the duration of its handler,
/// including streamed responses (the counter drops when the body is done).
Middleware trackInFlight(InFlightTracker tracker) {
  return (handler) => (context) async {
    tracker._start();
    var released = false;
    void release() {
      if (!released) {
        released = true;
        tracker._finish();
      }
    }

    try {
      final response = await handler(context);
      // Keep the request counted while a streamed body is still flowing.
      final body = response.bytes();
      final controller = StreamController<List<int>>(sync: true);
      body.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          release();
          unawaited(controller.close());
        },
        cancelOnError: false,
      );
      return response.copyWith(body: controller.stream);
    } on Object {
      release();
      rethrow;
    }
  };
}
