import 'package:meta/meta.dart';

/// User-facing lock preferences (persisted by the app in `app_settings`).
@immutable
class LockSettings {
  const LockSettings({
    this.timeout = Duration.zero,
    this.biometricsEnabled = false,
  });

  /// How long the app may stay in the background before it locks.
  /// `Duration.zero` means immediately.
  final Duration timeout;
  final bool biometricsEnabled;

  static const List<Duration> timeoutChoices = [
    Duration.zero,
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  LockSettings copyWith({Duration? timeout, bool? biometricsEnabled}) =>
      LockSettings(
        timeout: timeout ?? this.timeout,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is LockSettings &&
      other.timeout == timeout &&
      other.biometricsEnabled == biometricsEnabled;

  @override
  int get hashCode => Object.hash(timeout, biometricsEnabled);
}

abstract interface class LockSettingsStore {
  Future<LockSettings> load();

  Future<void> save(LockSettings settings);
}

final class InMemoryLockSettingsStore implements LockSettingsStore {
  InMemoryLockSettingsStore([this.settings = const LockSettings()]);

  LockSettings settings;

  @override
  Future<LockSettings> load() async => settings;

  @override
  Future<void> save(LockSettings settings) async => this.settings = settings;
}
