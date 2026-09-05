import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  // Brand Colors - Clean Clinical Lab-Report Aesthetic
  static const Color background = Color(0xFF0F172A);      // Slate 900
  static const Color cardBg = Color(0xFF1E293B);          // Slate 800
  static const Color accent = Color(0xFF0D9488);          // Deep Teal
  static const Color borderMuted = Color(0xFF334155);     // Dark Border Slate
  static const Color borderBright = Color(0xFF475569);    // Medium Border Slate
  static const Color textWhite = Color(0xFFF8FAFC);       // Slate 50
  static const Color textGray = Color(0xFF94A3B8);        // Slate 400

  // Soft Corners
  static const double borderRadiusValue = 8.0;
  static BorderRadius get softBorderRadius => BorderRadius.circular(borderRadiusValue);
  
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      cardColor: cardBg,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: textWhite),
        displayMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textWhite),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textWhite, letterSpacing: 1.0),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textWhite),
        bodyLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: textWhite, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: textGray),
        labelLarge: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textGray, letterSpacing: 1.0),
        labelSmall: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w400, color: textGray),
      ),
      iconTheme: const IconThemeData(color: accent, size: 20),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: borderBright,
        selectionHandleColor: accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        hintStyle: GoogleFonts.inter(color: textGray, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
          borderSide: const BorderSide(color: borderMuted, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
          borderSide: const BorderSide(color: borderMuted, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
          borderSide: const BorderSide(color: borderBright, width: 1.0),
        ),
      ),
    );
  }
}
