import 'dart:async';

import 'package:vf_core/vf_core.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_sync/src/sync_engine.dart';

const _log = Logger('scheduler');

/// Decides *when* to sync: start, connectivity regained, local mutation
/// (debounced), app resumed, and a periodic timer. Mobile background runs
/// are registered by the app with workmanager and call the engine directly.
class SyncScheduler {
  SyncScheduler({
    required this.engine,
    required this.connectivity,
    required this.outboxCount,
    this.debounce = const Duration(seconds: 2),
    this.period = const Duration(minutes: 15),
  });

  final SyncEngine engine;
  final ConnectivityMonitor connectivity;

  /// Live count of outbox rows; a growing count means a local mutation.
  final Stream<int> outboxCount;
  final Duration debounce;
  final Duration period;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<int>? _outboxSub;
  Timer? _debounceTimer;
  Timer? _periodic;
  bool _started = false;
  int _lastCount = -1;

  bool get isRunning => _started;

  void start() {
    if (_started) return;
    _started = true;
    _connectivitySub = connectivity.onlineChanges.listen((online) {
      if (online) {
        _log.debug('connectivity regained');
        _trigger('connectivity');
      }
    });
    _outboxSub = outboxCount.listen((count) {
      final grew = count > 0 && count != _lastCount;
      _lastCount = count;
      if (grew) _scheduleDebounced();
    });
    _periodic = Timer.periodic(period, (_) => _trigger('periodic'));
    _trigger('start');
  }

  void onAppResumed() {
    if (_started) _trigger('resume');
  }

  /// User-initiated "Sync now".
  Future<SyncReport> syncNow() => engine.syncNow();

  void _scheduleDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _trigger('mutation'));
  }

  void _trigger(String reason) {
    _log.debug('sync triggered', fields: {'reason': reason});
    unawaited(engine.syncNow());
  }

  void stop() {
    _started = false;
    unawaited(_connectivitySub?.cancel());
    unawaited(_outboxSub?.cancel());
    _debounceTimer?.cancel();
    _periodic?.cancel();
    _connectivitySub = null;
    _outboxSub = null;
    _debounceTimer = null;
    _periodic = null;
  }
}
