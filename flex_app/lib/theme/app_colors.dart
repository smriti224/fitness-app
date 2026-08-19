import 'package:flutter/material.dart';

/// Matches the colors from the React mockup exactly, so the real app looks
/// like what you approved there instead of default Flutter styling.
class AppColors {
  final Color bg, surface, surfaceAlt, border, text, textMuted, accent, accentDark, onAccent, rest;
  const AppColors({
    required this.bg, required this.surface, required this.surfaceAlt, required this.border,
    required this.text, required this.textMuted, required this.accent, required this.accentDark,
    required this.onAccent, required this.rest,
  });

  static const light = AppColors(
    bg: Color(0xFFEDE4E0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3EDE8),
    border: Color(0xFFE3D8CF),
    text: Color(0xFF665A48),
    textMuted: Color(0xFF9F8772),
    accent: Color(0xFF4C7A3D),
    accentDark: Color(0xFF375C2C),
    onAccent: Color(0xFFF2EDE6),
    rest: Color(0xFFC8DBBE),
  );

  static const dark = AppColors(
    bg: Color(0xFF050705),
    surface: Color(0xFF0D110D),
    surfaceAlt: Color(0xFF141A13),
    border: Color(0xFF1F2E1D),
    text: Color(0xFFE4F5E6),
    textMuted: Color(0xFF6B8A6E),
    accent: Color(0xFF39FF6A),
    accentDark: Color(0xFF1FB854),
    onAccent: Color(0xFF041008),
    rest: Color(0xFF496653),
  );
}

/// Lets any widget grab the current theme's colors via AppTheme.of(context).
class AppTheme extends InheritedWidget {
  final AppColors colors;
  final bool isDark;
  final VoidCallback toggleMode;

  const AppTheme({
    super.key,
    required this.colors,
    required this.isDark,
    required this.toggleMode,
    required super.child,
  });

  static AppTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(result != null, 'No AppTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => colors != oldWidget.colors;
}
