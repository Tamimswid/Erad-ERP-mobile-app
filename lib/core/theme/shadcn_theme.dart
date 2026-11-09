import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

abstract final class AppShadcnTheme {
  static const String fontFamily = 'Tajawal';

  // Warm neutral light palette.
  static sc.ColorScheme colors = sc.ColorScheme(
    brightness: Brightness.light,
    background: AppColors.background,
    foreground: Color(0xFF1C1917),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF1C1917),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF1C1917),
    primary: Color(0xFF1C1917),
    primaryForeground: Color(0xFFFAFAF9),
    secondary: Color(0xFFF1EFED),
    secondaryForeground: Color(0xFF1C1917),
    muted: Color(0xFFF1EFED),
    mutedForeground: Color(0xFF6B6560),
    accent: Color(0xFFF1EFED),
    accentForeground: Color(0xFF1C1917),
    destructive: Color(0xFFDC2626),
    border: Color(0x1A1C1917),
    input: Color(0x261C1917),
    ring: Color(0xFFA8A29E),
    chart1: Color(0xFF1C1917),
    chart2: Color(0xFF44403C),
    chart3: Color(0xFF78716C),
    chart4: Color(0xFFA8A29E),
    chart5: Color(0xFFD6D3D1),
  );

  // Luma style + large radius.
  static const double radius = 0.875;

  static sc.ThemeData get light {
    final typography = const sc.Typography.geist();
    return sc.ThemeData(
      colorScheme: colors,
      radius: radius,
      scaling: 1,
      density: sc.Density.defaultDensity,
      typography: typography.copyWith(sans: () => const TextStyle(fontFamily: fontFamily)),
    );
  }

  static TextStyle text(double size, FontWeight weight, [Color? color]) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: 1.4,
      color: color ?? colors.foreground,
    );
  }

  static ThemeData get materialLight {
    final scheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      primaryContainer: colors.secondary,
      onPrimaryContainer: colors.foreground,
      secondary: colors.secondary,
      onSecondary: colors.secondaryForeground,
      secondaryContainer: colors.muted,
      onSecondaryContainer: colors.mutedForeground,
      tertiary: colors.accent,
      onTertiary: colors.accentForeground,
      tertiaryContainer: colors.muted,
      onTertiaryContainer: colors.foreground,
      error: colors.destructive,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: colors.background,
      onSurface: colors.foreground,
      surfaceContainerLowest: colors.card,
      surfaceContainerLow: colors.card,
      surfaceContainer: colors.background,
      surfaceContainerHigh: colors.card,
      surfaceContainerHighest: colors.muted,
      onSurfaceVariant: colors.mutedForeground,
      outline: colors.border,
      outlineVariant: colors.border,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: colors.foreground,
      onInverseSurface: colors.background,
      inversePrimary: colors.primaryForeground,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      displayLarge: text(36, FontWeight.w800),
      displayMedium: text(30, FontWeight.w600),
      displaySmall: text(24, FontWeight.w600),
      headlineLarge: text(30, FontWeight.w600),
      headlineMedium: text(24, FontWeight.w600),
      headlineSmall: text(20, FontWeight.w600),
      titleLarge: text(18, FontWeight.w600),
      titleMedium: text(16, FontWeight.w600),
      titleSmall: text(14, FontWeight.w600),
      bodyLarge: text(16, FontWeight.w400),
      bodyMedium: text(14, FontWeight.w400),
      bodySmall: text(12, FontWeight.w400, colors.mutedForeground),
      labelLarge: text(14, FontWeight.w500),
      labelMedium: text(12, FontWeight.w500),
      labelSmall: text(12, FontWeight.w400, colors.mutedForeground),
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashColor: colors.primary.withValues(alpha: 0.06),
      highlightColor: colors.primary.withValues(alpha: 0.04),
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text(18, FontWeight.w600),
        iconTheme: IconThemeData(color: colors.foreground, size: 22),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          elevation: 0,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: text(14, FontWeight.w500, colors.primaryForeground),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: text(14, FontWeight.w500, colors.primaryForeground),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.foreground,
          backgroundColor: colors.card,
          side: BorderSide(color: colors.border),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: text(14, FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.foreground,
          shape: buttonShape,
          textStyle: text(14, FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: colors.foreground)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.muted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: colors.ring)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: colors.destructive)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: colors.destructive)),
        labelStyle: text(14, FontWeight.w400, colors.mutedForeground),
        floatingLabelStyle: text(14, FontWeight.w500, colors.foreground),
        hintStyle: text(14, FontWeight.w400, colors.mutedForeground),
        errorStyle: text(12, FontWeight.w400, colors.destructive),
        prefixIconColor: colors.mutedForeground,
        suffixIconColor: colors.mutedForeground,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.muted,
        selectedColor: colors.primary,
        disabledColor: colors.muted,
        labelStyle: text(13, FontWeight.w500, colors.mutedForeground),
        secondaryLabelStyle: text(13, FontWeight.w600, colors.primaryForeground),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: text(18, FontWeight.w600),
        contentTextStyle: text(14, FontWeight.w400),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.card,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: colors.border,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.foreground,
        contentTextStyle: text(14, FontWeight.w400, colors.primaryForeground),
        actionTextColor: colors.primaryForeground,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: colors.foreground,
        textColor: colors.foreground,
        subtitleTextStyle: text(12, FontWeight.w400, colors.mutedForeground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.muted,
        circularTrackColor: colors.muted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primaryForeground : colors.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primary : colors.muted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primary : colors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colors.primaryForeground),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.primary : colors.mutedForeground,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.muted,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.1),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.2),
        selectionHandleColor: colors.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: colors.foreground, borderRadius: BorderRadius.circular(10)),
        textStyle: text(12, FontWeight.w400, colors.primaryForeground),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
        textStyle: text(14, FontWeight.w400),
      ),
    );
  }
}
