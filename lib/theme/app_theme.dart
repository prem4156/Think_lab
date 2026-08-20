import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Pastel Palette)
  static const Color bgDark = Color(0xFFF7F5FA); // Soft blush lavender pastel background
  static const Color surfaceDark = Color(0xFFFFFFFF); // Clean pure white surface
  static const Color surfaceCard = Color(0xFFFFFFFF); // Clean white card background
  static const Color surfaceCardBorder = Color(0xFFE8E2F0); // Delicate soft pastel lilac border

  // Cognitive Domain Accent Colors (Soft Pastel Tones)
  static const Color cyanSpeed = Color(0xFF46A6FF); // Pastel Sky Blue
  static const Color purpleMemory = Color(0xFF9B72CF); // Pastel Lavender Violet
  static const Color emeraldAttention = Color(0xFF34D399); // Pastel Mint Green
  static const Color coralFlexibility = Color(0xFFFF758F); // Pastel Soft Coral / Rose
  static const Color amberProblemSolving = Color(0xFFF59E0B); // Pastel Soft Amber / Gold
  static const Color pinkLanguage = Color(0xFFE879F9); // Pastel Bubblegum Pink / Orchid

  // UI Accents
  static const Color primaryNeon = Color(0xFF8B5CF6); // Dreamy Pastel Violet Accent
  static const Color secondaryNeon = Color(0xFF38BDF8); // Soft Pastel Cyan Accent
  static const Color textPrimary = Color(0xFF1E1B4B); // Deep slate/indigo text for crisp contrast
  static const Color textSecondary = Color(0xFF64748B); // Soothing medium slate
  static const Color textMuted = Color(0xFF94A3B8); // Soft pastel slate text

  // Pastel Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7DD3FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient memoryGradient = LinearGradient(
    colors: [Color(0xFFC4B5FD), Color(0xFF9B72CF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient speedGradient = LinearGradient(
    colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient attentionGradient = LinearGradient(
    colors: [Color(0xFFA7F3D0), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient flexibilityGradient = LinearGradient(
    colors: [Color(0xFFFCA5A5), Color(0xFFFF758F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient problemSolvingGradient = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient languageGradient = LinearGradient(
    colors: [Color(0xFFFBCFE8), Color(0xFFE879F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Pastel Theme Data
  static ThemeData get pastelTheme {
    final baseText = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);
    return ThemeData.light().copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.light(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surfaceDark,
      ),
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: textPrimary,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceCardBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => pastelTheme;
}
