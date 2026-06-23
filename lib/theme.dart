import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brahmana Naivedyam brand palette — matches the website (saffron / cream /
/// leaf green / marigold).
class Brand {
  static const saffron = Color(0xFFF97316);
  static const marigold = Color(0xFFFBBF24);
  static const leaf = Color(0xFF16A34A);
  static const leafLight = Color(0xFFDCFCE7);
  static const cream = Color(0xFFFFFBF0);
  static const warmWhite = Color(0xFFFFF8ED);
  static const ink = Color(0xFF1A0F00);
  static const inkSoft = Color(0xFF3D2B00);
  static const muted = Color(0xFF7C6347);
  static const border = Color(0xFFF0E0CC);
  static const tomato = Color(0xFFEF4444);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.saffron,
    primary: Brand.saffron,
    secondary: Brand.leaf,
    surface: Colors.white,
    background: Brand.cream,
    brightness: Brightness.light,
  );

  final body = GoogleFonts.plusJakartaSansTextTheme();
  final display = GoogleFonts.bricolageGrotesqueTextTheme();

  TextTheme text = body.copyWith(
    displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink),
    headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink),
    titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink),
    titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Brand.ink),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.cream,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Brand.ink,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Brand.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.saffron,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.leafLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.ink,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

String rupees(num v) => '₹${v.toStringAsFixed(0)}';
