import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Platform identifier and a human-readable device name for `/auth/*`.
abstract final class DeviceInfo {
  static String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'linux',
    };
  }

  static String get name {
    if (kIsWeb) return 'Web browser';
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) return host;
    } on Object {
      // Not available on every platform.
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android device',
      TargetPlatform.iOS => 'iPhone',
      TargetPlatform.macOS => 'Mac',
      TargetPlatform.windows => 'Windows PC',
      _ => 'Device',
    };
  }
}
