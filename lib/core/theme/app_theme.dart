import 'package:flutter/material.dart';

class AppTheme {
  // Warna Utama GlowMate
  static const Color primaryColor = Color(0xFFF30B9A); // Pink GlowMate
  static const Color secondaryColor = Color(0xFFE91E63); // Pink Tua untuk kontras
  
  // Warna Light Mode
  static const Color scaffoldColorLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF7A7A7A);
  static const Color cardColorLight = Colors.white;

  // Warna Dark Mode
  static const Color scaffoldColorDark = Color(0xFF121212); // Hitam Material Standar
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color cardColorDark = Color(0xFF1E1E1E); // Abu-abu gelap untuk kartu

  /// ======== TEMA TERANG (LIGHT) ========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldColorLight,
      cardColor: cardColorLight,

      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColorLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimaryLight,
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondaryLight),
      ),

      cardTheme: const CardThemeData(
        color: cardColorLight,
        elevation: 1,
        margin: EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryLight),
        titleLarge: TextStyle(
          fontSize: 20,
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// ======== TEMA GELAP (DARK) - BARU DITAMBAHKAN ========
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryColor, // Pakai pink tua biar lebih kontras di background hitam
      scaffoldBackgroundColor: scaffoldColorDark,
      cardColor: cardColorDark,

      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColorDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimaryDark,
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor, // Tombol tetap cerah
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C), // Input field sedikit lebih terang dari background
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondaryDark),
      ),

      cardTheme: const CardThemeData(
        color: cardColorDark,
        elevation: 1,
        margin: EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryDark),
        titleLarge: TextStyle(
          fontSize: 20,
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}