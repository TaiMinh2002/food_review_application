import 'package:flutter/material.dart';

/// Warm Culinary Minimal: spacing and geometry shared by all features.
abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
  static const double margin = 20, gutter = 12;
  static const page = EdgeInsets.all(margin);
}

abstract final class AppRadii {
  static const double small = 8, input = 12, card = 16, sheet = 24;
  static const inputBorder = BorderRadius.all(Radius.circular(input));
  static const cardBorder = BorderRadius.all(Radius.circular(card));
}

abstract final class AppColors {
  static const forest = Color(0xFF2F6B4F);
  static const forestPressed = Color(0xFF24543E);
  static const orange = Color(0xFFF28C45);
  static const gold = Color(0xFFF5B942);
  static const linen = Color(0xFFF8F6F0);
  static const ink = Color(0xFF242824);
  static const muted = Color(0xFF73786F);
  static const outline = Color(0xFFE3E5DE);
}

/// Semantic roles outside Material's ColorScheme. Never branch on brightness
/// inside a feature: use these roles so every component follows the theme.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.rating,
    required this.canvas,
    required this.onImage,
  });
  final Color success,
      onSuccess,
      successContainer,
      warning,
      onWarning,
      warningContainer,
      rating,
      canvas,
      onImage;

  static const light = AppSemanticColors(
    success: Color(0xFF2F7D4B),
    onSuccess: Colors.white,
    successContainer: Color(0xFFEAF4EC),
    warning: Color(0xFF805400),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFEBC5),
    rating: AppColors.gold,
    canvas: AppColors.linen,
    onImage: Colors.white,
  );
  static const dark = AppSemanticColors(
    success: Color(0xFF97D5AA),
    onSuccess: Color(0xFF003919),
    successContainer: Color(0xFF173B25),
    warning: Color(0xFFF5CB7C),
    onWarning: Color(0xFF432C00),
    warningContainer: Color(0xFF493619),
    rating: AppColors.gold,
    canvas: Color(0xFF141A16),
    onImage: Colors.white,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? rating,
    Color? canvas,
    Color? onImage,
  }) => AppSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    rating: rating ?? this.rating,
    canvas: canvas ?? this.canvas,
    onImage: onImage ?? this.onImage,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      rating: Color.lerp(rating, other.rating, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      onImage: Color.lerp(onImage, other.onImage, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
