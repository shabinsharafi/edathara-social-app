import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color forest   = Color(0xFF0D2B1F);
  static const Color green    = Color(0xFF1A5C3A);
  static const Color mint     = Color(0xFF34A853);
  static const Color lime     = Color(0xFFA8D5B5);
  static const Color gold     = Color(0xFFE8B84B);

  // Neutral
  static const Color cream    = Color(0xFFF5F2EB);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color ink      = Color(0xFF0A1628);
  static const Color slate    = Color(0xFF4A5568);
  static const Color mist     = Color(0xFFEEF2F0);
  static const Color border   = Color(0xFFDDE8E0);

  // Semantic
  static const Color error    = Color(0xFFDC2626);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color success  = Color(0xFF16A34A);
  static const Color info     = Color(0xFF3182CE);

  // Ground colors
  static const Color cricket  = Color(0xFF1A5C3A);
  static const Color football = Color(0xFF1A3A6C);
  static const Color badminton= Color(0xFF4A235A);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [forest, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A5C3A), Color(0xFF34A853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mint,
        primary: AppColors.forest,
        secondary: AppColors.mint,
        surface: AppColors.cream,
        background: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.slate,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mint,
          side: const BorderSide(color: AppColors.mint, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lime),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lime),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mint, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.outfit(color: AppColors.slate),
        hintStyle: GoogleFonts.outfit(color: AppColors.slate, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mist,
        selectedColor: AppColors.mint.withOpacity(0.2),
        labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.mint,
        unselectedItemColor: AppColors.slate,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
