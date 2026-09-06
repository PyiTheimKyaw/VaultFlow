import 'package:flutter/material.dart';

/// Brand and semantic colours. Everything else derives from the Material 3
/// [ColorScheme] generated from [seed].
abstract final class VfColors {
  /// Primary brand seed: a deep, trustworthy indigo.
  static const Color seed = Color(0xFF3556D8);

  /// Semantic colours that must read the same in both themes.
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);
  static const Color neutral = Color(0xFF757575);
}

/// Theme-aware semantic colours attached to [ThemeData.extensions].
@immutable
class VfSemanticColors extends ThemeExtension<VfSemanticColors> {
  const VfSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutral,
  });

  const VfSemanticColors.light()
    : this(
        success: VfColors.success,
        warning: VfColors.warning,
        danger: VfColors.danger,
        info: VfColors.info,
        neutral: VfColors.neutral,
      );

  const VfSemanticColors.dark()
    : this(
        success: const Color(0xFF81C784),
        warning: const Color(0xFFFFB74D),
        danger: const Color(0xFFE57373),
        info: const Color(0xFF4FC3F7),
        neutral: const Color(0xFFBDBDBD),
      );

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color neutral;

  @override
  VfSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? neutral,
  }) => VfSemanticColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    neutral: neutral ?? this.neutral,
  );

  @override
  VfSemanticColors lerp(VfSemanticColors? other, double t) {
    if (other == null) return this;
    return VfSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension VfSemanticColorsX on BuildContext {
  /// Semantic colours for the current theme.
  VfSemanticColors get semanticColors =>
      Theme.of(this).extension<VfSemanticColors>() ??
      const VfSemanticColors.light();
}
