import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final semantic = dark ? AppSemanticColors.dark : AppSemanticColors.light;
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF96D4B2) : AppColors.forest,
          onPrimary: dark ? const Color(0xFF003822) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF24543E)
              : const Color(0xFFEBF3EE),
          onPrimaryContainer: dark
              ? const Color(0xFFB1F0CD)
              : AppColors.forestPressed,
          secondary: dark ? const Color(0xFFFFB689) : const Color(0xFF984800),
          onSecondary: dark ? const Color(0xFF552600) : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF743500)
              : const Color(0xFFFFDBC8),
          onSecondaryContainer: dark
              ? const Color(0xFFFFDBC8)
              : const Color(0xFF6E3200),
          tertiary: dark ? const Color(0xFFF5CB7C) : const Color(0xFF7E5900),
          error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFC74646),
          onError: dark ? const Color(0xFF690005) : Colors.white,
          errorContainer: dark
              ? const Color(0xFF5B2020)
              : const Color(0xFFFBEAEA),
          onErrorContainer: dark
              ? const Color(0xFFFFDAD6)
              : const Color(0xFF852727),
          surface: dark ? const Color(0xFF1C241E) : Colors.white,
          surfaceContainerLowest: dark ? const Color(0xFF101611) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF202B23)
              : const Color(0xFFF2F5EE),
          surfaceContainer: dark
              ? const Color(0xFF263129)
              : const Color(0xFFECEFE8),
          surfaceContainerHigh: dark
              ? const Color(0xFF303C33)
              : const Color(0xFFE6E9E3),
          surfaceContainerHighest: dark
              ? const Color(0xFF3B483E)
              : const Color(0xFFE0E3DD),
          onSurface: dark ? const Color(0xFFE6E9E3) : AppColors.ink,
          onSurfaceVariant: dark ? const Color(0xFFBAC5BA) : AppColors.muted,
          outline: dark ? const Color(0xFF89958B) : AppColors.muted,
          outlineVariant: dark ? const Color(0xFF414D44) : AppColors.outline,
        );
    TextStyle text(
      double size,
      double height,
      FontWeight weight, [
      double spacing = 0,
    ]) => TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: colors.onSurface,
    );
    final typography = TextTheme(
      headlineLarge: text(24, 32, FontWeight.w700, -.48),
      headlineMedium: text(20, 28, FontWeight.w600, -.3),
      headlineSmall: text(18, 26, FontWeight.w600, -.18),
      titleLarge: text(20, 28, FontWeight.w600, -.3),
      titleMedium: text(16, 22, FontWeight.w600, -.08),
      titleSmall: text(14, 20, FontWeight.w500),
      bodyLarge: text(16, 24, FontWeight.w400),
      bodyMedium: text(14, 20, FontWeight.w400),
      bodySmall: text(12, 16, FontWeight.w400, .12),
      labelLarge: text(14, 20, FontWeight.w600),
      labelMedium: text(13, 18, FontWeight.w500, .13),
      labelSmall: text(11, 14, FontWeight.w500, .22),
    );
    const shape = RoundedRectangleBorder(borderRadius: AppRadii.inputBorder);
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: const WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(typography.labelLarge),
      elevation: const WidgetStatePropertyAll(0),
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.inputBorder,
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      fontFamily: 'Inter',
      textTheme: typography,
      extensions: [semantic],
      scaffoldBackgroundColor: semantic.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: semantic.canvas,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: typography.headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: button.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.onSurface.withValues(alpha: .12);
            }
            if (!dark && states.contains(WidgetState.pressed)) {
              return AppColors.forestPressed;
            }
            return colors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .38)
                : colors.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? colors.outlineVariant
                  : colors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: button),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          shape: const WidgetStatePropertyAll(shape),
          foregroundColor: WidgetStatePropertyAll(colors.onSurface),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(colors.outlineVariant),
        enabledBorder: border(colors.outlineVariant),
        focusedBorder: border(colors.primary, 2),
        errorBorder: border(colors.error),
        focusedErrorBorder: border(colors.error, 2),
        disabledBorder: border(colors.outlineVariant),
        hintStyle: typography.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        errorStyle: typography.bodySmall?.copyWith(color: colors.error),
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: colors.primary,
        secondarySelectedColor: colors.primary,
        labelStyle: typography.labelMedium,
        side: BorderSide(color: colors.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => typography.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: typography.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
      ),
    );
  }
}
