import 'package:flutter/widgets.dart';

/// Width classes from the Material 3 window size class guidance.
enum WindowSizeClass {
  /// `< 600` — phones. Bottom navigation, single pane, drawer sidebar.
  compact,

  /// `600–840` — small tablets, split-screen. Navigation rail, single pane.
  medium,

  /// `> 840` — tablets, desktop, web. Persistent sidebar and content pane.
  expanded;

  bool get isCompact => this == compact;
  bool get isMedium => this == medium;
  bool get isExpanded => this == expanded;

  /// Whether at least [other] wide.
  bool operator >=(WindowSizeClass other) => index >= other.index;
}

/// Single source of truth for layout breakpoints.
abstract final class Breakpoints {
  /// Widths strictly below this are [WindowSizeClass.compact].
  static const double compact = 600;

  /// Widths at or above this are [WindowSizeClass.expanded].
  static const double expanded = 840;

  static WindowSizeClass classify(double width) {
    if (width < compact) return WindowSizeClass.compact;
    if (width < expanded) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }
}

extension WindowSizeClassX on BuildContext {
  /// The size class for the current [MediaQuery] width.
  WindowSizeClass get windowSizeClass =>
      Breakpoints.classify(MediaQuery.sizeOf(this).width);
}
