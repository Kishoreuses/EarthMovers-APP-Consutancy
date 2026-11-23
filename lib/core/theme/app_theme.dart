import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Dark Palette ──────────────────────────────
  static const Color background = Color(0xFF0F0F1A);
  static const Color bgDark = background;
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF232340);
  static const Color glass = Color(0x0FFFFFFF); // 6% white
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white
  static const Color glassHighlight = Color(0x33FFFFFF); // 20% white

  // ─── Accent Colors ─────────────────────────────────
  static const Color amber = Color(0xFFF59E0B);
  static const Color primaryAmber = amber;
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFFD97706);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFF87171);
  static const Color purple = Color(0xFF8B5CF6);

  // ─── Text Colors ───────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Gradients ─────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF16162A), Color(0xFF0F0F1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF232340)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Border Radius ─────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  // ─── Shadows ───────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color, {double blur = 20}) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: blur,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Theme Data ────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: amber,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: blue,
        surface: surface,
        error: red,
        onPrimary: Color(0xFF1A1A2E),
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: const Color(0xFF1A1A2E),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: red),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: glassBorder),
        ),
      ),
      dividerColor: glassBorder,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? amber : textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? amber.withOpacity(0.3)
              : surface;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: amber,
        unselectedLabelColor: textSecondary,
        indicatorColor: amber,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }
}
