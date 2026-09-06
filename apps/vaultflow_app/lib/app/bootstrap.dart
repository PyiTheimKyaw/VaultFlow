import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_ui/vf_ui.dart';
import 'package:window_manager/window_manager.dart';

const _log = Logger('bootstrap');

/// Whether the app is running as a desktop process (not web, not mobile).
bool get isDesktop =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };

/// Platform set-up that must happen before `runApp`.
///
/// * Web: path-based URLs (`/vault/abc` instead of `/#/vault/abc`).
/// * Desktop: window title and minimum size.
Future<void> bootstrap() async {
  Logger.minimumLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  if (kIsWeb) {
    usePathUrlStrategy();
    return;
  }

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'VaultFlow',
      minimumSize: Size(VfSizes.minWindowWidth, VfSizes.minWindowHeight),
      size: Size(1200, 800),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    _log.debug('desktop window configured');
  }
}
