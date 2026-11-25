import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // Brand Color Palette (Sierra Leone Flag inspired: Green, White, Blue, with Gold accents)
  static const Color primaryGreen = Color(0xFF0F9D58);
  static const Color primaryGreenDark = Color(0xFF0B6B3C);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentCyan = Color(0xFF00ACC1);
  static const Color goldenAmber = Color(0xFFFFB300);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateCard = Color(0xFF283548);
  static const Color slateLight = Color(0xFFF1F5F9);
  static const Color slateBorder = Color(0xFFCBD5E1);

  // Status Colors
  static const Color statusPassed = Color(0xFF2E7D32);
  static const Color statusPending = Color(0xFFED6C02);
  static const Color statusFlagged = Color(0xFFD32F2F);
  static const Color statusActive = Color(0xFF1976D2);

  // Currency Formatter
  static final NumberFormat _currencyFormatter =
      NumberFormat.currency(symbol: 'Le ', decimalDigits: 2);
  static final NumberFormat _integerFormatter = NumberFormat('#,##0');

  static String formatLeones(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatNumber(int count) {
    return _integerFormatter.format(count);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: accentBlue,
        onSecondary: Colors.white,
        tertiary: goldenAmber,
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
        surfaceContainerHighest: slateLight,
        error: statusFlagged,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusFlagged),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF10B981),
        onPrimary: Colors.black,
        secondary: const Color(0xFF38BDF8),
        onSecondary: Colors.black,
        tertiary: goldenAmber,
        surface: const Color(0xFF1E293B),
        onSurface: const Color(0xFFF8FAFC),
        surfaceContainerHighest: const Color(0xFF334155),
        error: const Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
