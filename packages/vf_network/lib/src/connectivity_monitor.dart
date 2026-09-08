import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device believes it has a network path. Reachability of the
/// server is a separate question answered by actual requests.
abstract interface class ConnectivityMonitor {
  Future<bool> isOnline();

  /// Emits on every change, de-duplicated.
  Stream<bool> get onlineChanges;
}

/// [ConnectivityMonitor] on `connectivity_plus`.
final class PluginConnectivityMonitor implements ConnectivityMonitor {
  PluginConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

/// Scriptable monitor for tests.
final class FakeConnectivityMonitor implements ConnectivityMonitor {
  FakeConnectivityMonitor({bool initiallyOnline = true})
    : _online = initiallyOnline;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  // ignore: avoid_setters_without_getters, mirrors the real monitor's push model
  set online(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  Future<void> dispose() => _controller.close();
}
