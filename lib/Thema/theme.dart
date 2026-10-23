// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BarberGoTheme {
  // Colors
  static const Color primary = Color(0xFF00D8FF); // Tosca
  static const Color primaryVariant = Color(0xFF0095BF);
  static const Color navy = Color(0xFF003F57);
  static const Color bgLight = Color(0xFFF7FAFC);
  static const Color success = Color(0xFF28A745);
  static const Color danger = Color(0xFFE53935);

  // Radius
  static const double cardRadius = 14.0;
  static const double defaultPadding = 16.0;

  // Light Theme
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryVariant,
        background: bgLight,
        surface: Colors.white,
        onPrimary: Colors.white,
        onBackground: navy,
        onSurface: navy,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
        actionsIconTheme: const IconThemeData(color: Colors.black54),
        centerTitle: false,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: navy),
        displayMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: navy),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: navy),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: navy),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: navy),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 6,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: danger,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          elevation: 3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      dividerColor: Colors.grey[200],
    );
  }

  // Dark Theme
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      primaryColor: primaryVariant,
      colorScheme: ColorScheme.dark(
        primary: primaryVariant,
        secondary: primary,
        background: const Color(0xFF0B1220),
        surface: const Color(0xFF0F1724),
        onPrimary: Colors.black,
        onBackground: Colors.white70,
        onSurface: Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        displayMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF0F1724),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F1724),
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey[400],
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: danger,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1220),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryVariant,
        contentTextStyle: GoogleFonts.poppins(color: Colors.black),
      ),
      dividerColor: Colors.grey[700],
    );
  }
}
