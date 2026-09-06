import 'package:flutter/widgets.dart';

/// 4-pt spacing scale.
abstract final class VfSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page padding per size class is applied by layouts; this is
  /// the default inner padding of cards and list tiles.
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
}

/// Corner radii.
abstract final class VfRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double pill = 999;
}

/// Fixed panel sizes used by the adaptive layout.
abstract final class VfSizes {
  static const double sidebarWidth = 280;
  static const double detailWidth = 360;
  static const double railWidth = 80;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
}
