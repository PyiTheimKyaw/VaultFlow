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
    this.eventSource,
    this.eventRetry = const Duration(seconds: 5),
  });

  final SyncEngine engine;
  final ConnectivityMonitor connectivity;

  /// Live count of outbox rows; a growing count means a local mutation.
  final Stream<int> outboxCount;
  final Duration debounce;
  final Duration period;

  /// Optional realtime nudge (`GET /sync/events`): each element means the
  /// server has changes for this user. The stream is re-opened with a
  /// backoff when it ends or errors, and only while the scheduler runs.
  final Stream<int> Function()? eventSource;
  final Duration eventRetry;

  StreamSubscription<int>? _eventSub;
  Timer? _eventReconnect;
  int _eventFailures = 0;

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
    _listenEvents();
    _trigger('start');
  }

  void _listenEvents() {
    final source = eventSource;
    if (source == null || !_started) return;
    _eventSub = source().listen(
      (_) {
        _eventFailures = 0;
        _trigger('event');
      },
      onError: (Object e) => _scheduleReconnect('error: $e'),
      onDone: () => _scheduleReconnect('closed'),
      cancelOnError: true,
    );
  }

  void _scheduleReconnect(String why) {
    if (!_started) return;
    _eventSub = null;
    _eventFailures++;
    final delay = eventRetry * (1 << (_eventFailures - 1).clamp(0, 5));
    _log.debug('event stream $why; reconnecting', fields: {'in': '$delay'});
    _eventReconnect?.cancel();
    _eventReconnect = Timer(delay, _listenEvents);
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
    unawaited(_eventSub?.cancel());
    _eventReconnect?.cancel();
    _eventSub = null;
    _eventReconnect = null;
    _connectivitySub = null;
    _outboxSub = null;
    _debounceTimer = null;
    _periodic = null;
  }
}
