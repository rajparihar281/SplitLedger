import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  // ── Typography ──────────────────────────────────────────────
  static final _baseTextTheme = GoogleFonts.outfitTextTheme();

  static final _textTheme = _baseTextTheme.copyWith(
    displayLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    titleMedium: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    titleSmall: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    bodyLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontSize: 16,
    ),
    bodyMedium: GoogleFonts.outfit(
      color: AppColors.slate,
      fontSize: 14,
    ),
    bodySmall: GoogleFonts.outfit(
      color: AppColors.slate,
      fontSize: 12,
    ),
    labelLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
    labelMedium: GoogleFonts.outfit(
      color: AppColors.slate,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    labelSmall: GoogleFonts.outfit(
      color: AppColors.slate,
      fontWeight: FontWeight.w500,
      fontSize: 11,
    ),
  );

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.paper,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coral,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ink,
        onPrimary: AppColors.white,
        secondary: AppColors.coral,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        error: AppColors.error,
        onError: AppColors.white,
      ),

      textTheme: _textTheme,

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── TabBar ────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.slate,
        indicatorColor: AppColors.coral,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ── Input Decoration ──────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(
            color: AppColors.coral,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.slate, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: AppColors.slate, fontSize: 14),
        errorStyle: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
        prefixIconColor: AppColors.slate,
        suffixIconColor: AppColors.slate,
      ),

      // ── Elevated Button (Ink primary) ─────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Filled Button ─────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coral,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Card ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.slate,
        size: 22,
      ),

      // ── FAB ───────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.outfit(
          color: AppColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.slate,
        elevation: 0,
      ),

      // ── Chip ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mist,
        selectedColor: AppColors.ink,
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // ── Progress Indicator ────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
      ),

      // ── SegmentedButton ───────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.ink;
            return AppColors.mist;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.white;
            return AppColors.ink;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── ListTile ──────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.outfit(
          color: AppColors.slate,
          fontSize: 13,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── DropdownMenu ──────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.mist,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
