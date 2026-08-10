import 'package:flutter/material.dart';

abstract final class FlMoeTheme {
  // Flutter's adaptive default stays an arrow on native desktop platforms.
  static const ButtonStyle _clickableButtonStyle = ButtonStyle(
    mouseCursor: WidgetStateMouseCursor.clickable,
  );

  static ThemeData light(Color seed) => _create(seed, Brightness.light);

  static ThemeData dark(Color seed) => _create(seed, Brightness.dark);

  static ThemeData _create(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? const Color(0xFFF7F9FC)
          : const Color(0xFF11151B),
    );
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: isDark ? const Color(0xFFE8ECF2) : const Color(0xFF273142),
        displayColor: isDark
            ? const Color(0xFFF3F6FA)
            : const Color(0xFF192233),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF1A2029) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textButtonTheme: const TextButtonThemeData(style: _clickableButtonStyle),
      filledButtonTheme: const FilledButtonThemeData(
        style: _clickableButtonStyle,
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: _clickableButtonStyle,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: _clickableButtonStyle,
      ),
      iconButtonTheme: const IconButtonThemeData(style: _clickableButtonStyle),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: _clickableButtonStyle,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        mouseCursor: WidgetStateMouseCursor.clickable,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        mouseCursor: WidgetStateMouseCursor.clickable,
      ),
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE8EDF4),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF313A48) : const Color(0xFF253142),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
