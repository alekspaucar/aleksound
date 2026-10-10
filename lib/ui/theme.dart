import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette(
      {required this.background,
      required this.surface,
      required this.text,
      required this.muted,
      required this.line});
  final Color background, surface, text, muted, line;
  Color get accent => text;
  static const light = AppPalette(
      background: Color(0xFFFAFAFA),
      surface: Color(0xFFF0F0F0),
      text: Color(0xFF171717),
      muted: Color(0xFF626262),
      line: Color(0xFFDDDDDD));
  static const dark = AppPalette(
      background: Color(0xFF101010),
      surface: Color(0xFF202020),
      text: Color(0xFFF5F5F5),
      muted: Color(0xFFAAAAAA),
      line: Color(0xFF383838));
}

extension PaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme =
      ColorScheme.fromSeed(seedColor: p.text, brightness: brightness).copyWith(
    primary: p.text,
    onPrimary: p.background,
    surface: p.surface,
    onSurface: p.text,
    secondary: p.text,
    onSecondary: p.background,
    surfaceTint: Colors.transparent,
  );
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: p.background,
    colorScheme: scheme,
    fontFamily: 'sans-serif',
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
          fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -1),
      headlineMedium: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.6),
      titleLarge: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -.3),
      titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12, color: p.muted),
    ).apply(bodyColor: p.text, displayColor: p.text),
    iconTheme: IconThemeData(color: p.text),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44))),
    dividerTheme: DividerThemeData(color: p.line, thickness: .5),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.background,
      indicatorColor: p.surface,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: p.text)),
      labelTextStyle:
          WidgetStatePropertyAll(TextStyle(color: p.text, fontSize: 12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.text,
      side: BorderSide(color: p.line),
      labelStyle: TextStyle(color: p.text),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.text,
      thumbColor: p.text,
      inactiveTrackColor: p.line,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
    ),
  );
}
