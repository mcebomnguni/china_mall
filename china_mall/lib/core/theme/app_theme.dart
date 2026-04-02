import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF1F2937);

  // ── Primary reds ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFD42B2B);
  static const Color primaryDark = Color(0xFFB91C1C);
  static const Color primaryLight = Color(0xFFFEE2E2);

  // ── Accent gold ───────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFD4A843);
  static const Color accentLight = Color(0xFFFEF3C7);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F0EB);

  // ── Nav bar ───────────────────────────────────────────────────────────────
  static const Color navBg = Color(0xFF2D1A1A);

  // ── Borders & dividers ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color cardShadow = Color(0x0A000000);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3E7BFA);
  static const Color starRating = Color(0xFFF59E0B);

  // ── Dark mode surfaces ────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF1A1010);
  static const darkSurface = Color(0xFF241818);
  static const darkSurfaceVariant = Color(0xFF2E1F1F);
  static const darkBorder = Color(0xFF4A3333);

  static const darkTextPrimary = Color(0xFFF5F0EB);
  static const darkTextSecondary = Color(0xFFD4C4B8);
  static const darkTextTertiary = Color(0xFFA08E82);

  // ── Role colors ───────────────────────────────────────────────────────────
  static const storeColor = Color(0xFFD42B2B);
  static const courierColor = Color(0xFF377B78);
  static const adminColor = Color(0xFF215D7C);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD42B2B), Color(0xFFE85D3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient promoBannerGradient = LinearGradient(
    colors: [Color(0xFFD42B2B), Color(0xFFC41E1E), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFAF8F5), Color(0xFFFEE2E2), Color(0xFFFEF3C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF1A1010), Color(0xFF2E1515), Color(0xFF3D1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientRed = LinearGradient(
    colors: [Color(0xFFD42B2B), Color(0xFFE85D3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlack = LinearGradient(
    colors: [Color(0xFF2D1A1A), Color(0xFFD42B2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientStore = LinearGradient(
    colors: [Color(0xFFD42B2B), Color(0xFFE85D3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCourier = LinearGradient(
    colors: [Color(0xFF215F62), Color(0xFF39989A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAdmin = LinearGradient(
    colors: [Color(0xFF215D7C), Color(0xFF3D8BB2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDark = gradientBlack;
  static const gradientGold = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFB8922F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        tertiary: AppColors.textTertiary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.white,
        unselectedItemColor: Color(0x80FFFFFF),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        tertiary: AppColors.darkTextTertiary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.white,
        unselectedItemColor: Color(0x80FFFFFF),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: tertiary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: tertiary,
      ),
    );
  }
}
