import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Matches the web app's Tailwind design system exactly
class AppColors {
  // Primary blue
  static const primary50 = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary200 = Color(0xFFBFDBFE);
  static const primary300 = Color(0xFF93C5FD);
  static const primary400 = Color(0xFF60A5FA);
  static const primary500 = Color(0xFF3B82F6);
  static const primary600 = Color(0xFF2563EB);
  static const primary700 = Color(0xFF1D4ED8);
  static const primary800 = Color(0xFF1E40AF);
  static const primary900 = Color(0xFF1E3A8A);

  // Secondary purple
  static const secondary500 = Color(0xFFA855F7);
  static const secondary600 = Color(0xFF9333EA);
  static const secondary700 = Color(0xFF7E22CE);

  // Cyan
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan500 = Color(0xFF06B6D4);

  // Indigo
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);

  // Success green
  static const success50 = Color(0xFFF0FDF4);
  static const success100 = Color(0xFFDCFCE7);
  static const success500 = Color(0xFF22C55E);
  static const success600 = Color(0xFF16A34A);
  static const success700 = Color(0xFF15803D);

  // Error red
  static const error50 = Color(0xFFFEF2F2);
  static const error100 = Color(0xFFFEE2E2);
  static const error500 = Color(0xFFEF4444);
  static const error600 = Color(0xFFDC2626);
  static const error700 = Color(0xFFB91C1C);

  // Warning
  static const warning50 = Color(0xFFFFFBEB);
  static const warning500 = Color(0xFFEAB308);

  // Orange
  static const orange500 = Color(0xFFF97316);
  static const orange700 = Color(0xFFC2410C);

  // Grays
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // Sidebar dark
  static const sidebarDark = Color(0xFF111827);   // gray-900
  static const sidebarMid = Color(0xFF1F2937);    // gray-800

  // Gradients
  static const List<Color> headerGradient = [indigo700, indigo600, cyan500];
  static const List<Color> sidebarGradient = [gray900, gray800];
  static const List<Color> blueGradient = [primary700, primary500, cyan500];
  static const List<Color> purpleGradient = [secondary700, secondary500, Color(0xFFEC4899)];
  static const List<Color> greenGradient = [success700, success500, Color(0xFF10B981)];
  static const List<Color> orangeGradient = [orange700, orange500, Color(0xFFFB923C)];

  // Premium Mesh Gradient Colors
  static const List<Color> meshBlue = [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF312E81)];
  static const List<Color> meshDark = [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E1B4B)];

  // Glassmorphism Utilities
  static BoxDecoration glass({
    Color? color,
    double opacity = 0.1,
    double blur = 10,
    BorderRadius? borderRadius,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: hasBorder ? Border.all(color: Colors.white.withValues(alpha: 0.15)) : null,
    );
  }

  // Premium Shadow
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary600,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: AppColors.gray900,
      ),
      scaffoldBackgroundColor: AppColors.gray50,
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: AppColors.gray300.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.gray900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.gray900),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary50,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(color: AppColors.primary700, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.outfit(color: AppColors.gray400, fontSize: 12, fontWeight: FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary700);
          }
          return const IconThemeData(color: AppColors.gray400);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary50,
        labelStyle: GoogleFonts.outfit(color: AppColors.primary700, fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary500.withValues(alpha: 0.4),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary600,
          side: const BorderSide(color: AppColors.primary200, width: 1.5),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary500, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.outfit(color: AppColors.gray500, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.outfit(color: AppColors.gray400),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.gray200, space: 1, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary500,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B), // gray-800 equivalent
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // gray-900 equivalent
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: AppColors.primary700.withValues(alpha: 0.4),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(color: AppColors.primary400, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.outfit(color: AppColors.gray400, fontSize: 12, fontWeight: FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary400);
          }
          return const IconThemeData(color: AppColors.gray400);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary900.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.outfit(color: AppColors.primary300, fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary600.withValues(alpha: 0.3),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary400,
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary500, width: 2)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.outfit(color: AppColors.gray400, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.outfit(color: AppColors.gray500),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1E293B), space: 1, thickness: 1),
    );
  }
}

