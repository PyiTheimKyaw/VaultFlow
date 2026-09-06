/// Source of the current time, injectable so tests can control it.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime now();
}

/// Uses the wall clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

/// A clock that only moves when told to; for tests and deterministic logic.
final class FakeClock implements Clock {
  FakeClock([DateTime? initial])
    : _now = (initial ?? DateTime.utc(2026)).toUtc();

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => _now = _now.add(duration);

  /// Sets the clock to [instant].
  void set(DateTime instant) => _now = instant.toUtc();
}
