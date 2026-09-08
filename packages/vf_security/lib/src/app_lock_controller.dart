import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show AppLifecycleState;
import 'package:vf_core/vf_core.dart';
import 'package:vf_security/src/biometric_gate.dart';
import 'package:vf_security/src/lock_settings.dart';
import 'package:vf_security/src/pin_vault.dart';

const _log = Logger('app_lock');

/// Drives the lock overlay.
///
/// The vault locks when a PIN is set and the app has been in the background
/// for at least [LockSettings.timeout]; a cold start with a PIN starts
/// locked. Biometrics are an optional shortcut; the PIN is always the
/// fallback. Without a PIN there is nothing to lock behind, so the vault is
/// never locked.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required this.pin,
    required this.biometrics,
    required this.settingsStore,
    this.clock = const SystemClock(),
  });

  final PinVault pin;
  final BiometricGate biometrics;
  final LockSettingsStore settingsStore;
  final Clock clock;

  bool _locked = false;
  bool _obscured = false;
  bool _pinSet = false;
  bool _initialized = false;
  DateTime? _hiddenAt;
  LockSettings _settings = const LockSettings();
  BiometricAvailability _biometricAvailability =
      BiometricAvailability.unsupported;

  bool get isLocked => _locked;

  /// True while the app is inactive (app switcher); the UI draws a cover so
  /// OS snapshots do not show vault contents.
  bool get isObscured => _obscured;

  bool get hasPin => _pinSet;
  bool get isInitialized => _initialized;
  LockSettings get settings => _settings;
  BiometricAvailability get biometricAvailability => _biometricAvailability;

  bool get canUseBiometrics =>
      _settings.biometricsEnabled &&
      _biometricAvailability == BiometricAvailability.available;

  /// Loads settings and locks immediately if a PIN exists (cold start).
  Future<void> initialize() async {
    _settings = await settingsStore.load();
    _pinSet = await pin.hasPin;
    _biometricAvailability = await biometrics.availability();
    _locked = _pinSet;
    _initialized = true;
    notifyListeners();
  }

  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _setObscured(true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _setObscured(true);
        _hiddenAt ??= clock.now();
      case AppLifecycleState.resumed:
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (_pinSet &&
            !_locked &&
            hiddenAt != null &&
            clock.now().difference(hiddenAt) >= _settings.timeout) {
          _locked = true;
          _log.debug('locked after background timeout');
        }
        _setObscured(false);
      case AppLifecycleState.detached:
        break;
    }
  }

  void lock() {
    if (!_pinSet || _locked) return;
    _locked = true;
    notifyListeners();
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_locked || !canUseBiometrics) return false;
    final ok = await biometrics.authenticate(reason: 'Unlock your vault');
    if (ok) _unlock();
    return ok;
  }

  Future<PinVerifyResult> unlockWithPin(String code) async {
    final result = await pin.verify(code);
    if (result is PinOk) _unlock();
    return result;
  }

  /// Sets a new PIN (or replaces the current one) and keeps the vault
  /// unlocked so the user is not locked out of the screen they are on.
  Future<void> setPin(String code) async {
    await pin.setPin(code);
    _pinSet = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    await pin.clear();
    _pinSet = false;
    _locked = false;
    await updateSettings(_settings.copyWith(biometricsEnabled: false));
  }

  Future<void> updateSettings(LockSettings settings) async {
    _settings = settings;
    await settingsStore.save(settings);
    notifyListeners();
  }

  Future<void> refreshBiometricAvailability() async {
    _biometricAvailability = await biometrics.availability();
    notifyListeners();
  }

  void _unlock() {
    _locked = false;
    _hiddenAt = null;
    notifyListeners();
  }

  void _setObscured(bool value) {
    if (_obscured == value && !value && !_locked) return;
    _obscured = value;
    notifyListeners();
  }
}
