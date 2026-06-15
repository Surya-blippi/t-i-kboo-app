import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography + theme.
/// Display: Unbounded — chunky, rounded, very online.
/// Body: Plus Jakarta Sans — clean, geometric, readable.
/// Fonts are bundled as assets (variable weight) — zero runtime fetch,
/// works offline, no flash of unstyled text.
/// Rule: NO italics anywhere. Weight does the emphasis instead.
class AppTheme {
  AppTheme._();

  static const String displayFamily = 'Unbounded';
  static const String bodyFamily = 'PlusJakartaSans';

  /// Our display/body fonts have no emoji glyphs, so emojis embedded in those
  /// text styles render as tofu squares. Fall back to the platform emoji font.
  static const List<String> _emojiFallback = ['Apple Color Emoji', 'Noto Color Emoji'];

  static TextStyle display(double size,
      {Color color = AppColors.textHi,
      FontWeight weight = FontWeight.w800,
      double height = 1.0,
      double letterSpacing = -1.0}) {
    return TextStyle(
      fontFamily: displayFamily,
      fontFamilyFallback: _emojiFallback,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: FontStyle.normal,
    );
  }

  static TextStyle body(double size,
      {Color color = AppColors.textMid,
      FontWeight weight = FontWeight.w500,
      double height = 1.4,
      double letterSpacing = 0}) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontFamilyFallback: _emojiFallback,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: FontStyle.normal,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.ink,
        primary: AppColors.lime,
        secondary: AppColors.pink,
        tertiary: AppColors.violet,
        onPrimary: AppColors.ink,
        onSurface: AppColors.textHi,
      ),
      textTheme: base.textTheme
          .apply(fontFamily: bodyFamily, bodyColor: AppColors.textHi, displayColor: AppColors.textHi),
      splashColor: AppColors.lime.withOpacity(0.08),
      highlightColor: Colors.transparent,
    );
  }
}
