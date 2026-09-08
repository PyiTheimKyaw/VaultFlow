import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vf_core/vf_core.dart';

const _log = Logger('biometrics');

enum BiometricAvailability {
  /// Hardware present and at least one biometric enrolled.
  available,

  /// Hardware present but nothing enrolled (user must set it up in the OS).
  notEnrolled,

  /// No usable hardware or platform (web, most Linux desktops).
  unsupported,
}

/// Wraps the platform biometric prompt.
abstract interface class BiometricGate {
  Future<BiometricAvailability> availability();

  /// Shows the OS prompt; `true` only when the user passed it.
  Future<bool> authenticate({required String reason});
}

/// [BiometricGate] on `local_auth` (Face ID / Touch ID, Android biometrics,
/// Windows Hello).
final class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return BiometricAvailability.unsupported;
      }
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.unsupported;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.available;
    } on PlatformException catch (e) {
      _log.warning('biometric availability check failed', error: e);
      return BiometricAvailability.unsupported;
    } on MissingPluginException {
      return BiometricAvailability.unsupported;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException catch (e) {
      // Cancelled, locked out, or not available: all mean "not unlocked".
      _log.debug('biometric prompt failed', fields: {'code': e.code});
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Scriptable gate for tests and unsupported platforms.
final class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate({
    this.result = BiometricAvailability.available,
    this.succeed = true,
  });

  BiometricAvailability result;
  bool succeed;
  int prompts = 0;

  @override
  Future<BiometricAvailability> availability() async => result;

  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    return succeed;
  }
}
