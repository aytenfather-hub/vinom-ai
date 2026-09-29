import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class FbTheme {
  static const _cairo = 'Cairo';
  static const _poppins = 'Poppins';
  static const _pkg = 'fb_ui';

  static ThemeData light(String locale) => _build(locale, Brightness.light);
  static ThemeData dark(String locale) => _build(locale, Brightness.dark);

  static ThemeData _build(String locale, Brightness b) {
    final isDark = b == Brightness.dark;
    final family = locale == 'ar' ? _cairo : _poppins;
    final fallback = locale == 'ar' ? ['packages/$_pkg/$_poppins'] : ['packages/$_pkg/$_cairo'];
    final fg = isDark ? FbColors.cream : FbColors.cocoa;
    final body = isDark ? FbColors.cream.withValues(alpha: .86) : FbColors.ink;
    final scheme = ColorScheme(
      brightness: b,
      primary: FbColors.red,
      onPrimary: FbColors.cream,
      secondary: FbColors.mint,
      onSecondary: FbColors.cocoa,
      tertiary: FbColors.brown,
      onTertiary: FbColors.cream,
      error: FbColors.red,
      onError: FbColors.cream,
      surface: isDark ? FbColors.nightSurface : Colors.white,
      onSurface: fg,
      surfaceContainerLowest: isDark ? FbColors.night : FbColors.cream,
      surfaceContainerLow: isDark ? FbColors.nightSurface : FbColors.oat,
      outline: isDark ? FbColors.nightLine : FbColors.line,
    );
    TextStyle t(double size, FontWeight w, {Color? c, double h = 1.35}) =>
        TextStyle(fontFamily: family, package: _pkg, fontFamilyFallback: fallback, fontSize: size, fontWeight: w, color: c ?? fg, height: h);
    final text = TextTheme(
      displayLarge: t(48, FontWeight.w900, h: 1.15),
      displaySmall: t(34, FontWeight.w900, h: 1.2),
      headlineMedium: t(28, FontWeight.w900, h: 1.25),
      titleLarge: t(24, FontWeight.w900),
      titleMedium: t(20, FontWeight.w800),
      titleSmall: t(16, FontWeight.w800),
      bodyLarge: t(16, FontWeight.w400, c: body, h: 1.7),
      bodyMedium: t(14, FontWeight.w400, c: body, h: 1.65),
      bodySmall: t(12, FontWeight.w600, c: isDark ? FbColors.cream.withValues(alpha: .6) : FbColors.muted),
      labelLarge: t(16, FontWeight.w800),
      labelMedium: t(14, FontWeight.w700),
      labelSmall: t(12, FontWeight.w700),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? FbColors.night : FbColors.cream,
      textTheme: text,
      fontFamily: family,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: fg,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: FbRadius.cardAll),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? FbColors.nightSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: FbColors.mint, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: FbColors.red, width: 1.5)),
        hintStyle: text.bodyMedium?.copyWith(color: FbColors.muted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? FbColors.nightSurface : Colors.white,
        indicatorColor: FbColors.blushTint,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
        height: 72,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: FbColors.cocoa,
        contentTextStyle: text.labelMedium?.copyWith(color: FbColors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
