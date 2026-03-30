import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF08120D);

  static const green900 = Color(0xFF0E3B2B);
  static const green800 = Color(0xFF135238);
  static const green700 = Color(0xFF1D6B46);
  static const green600 = Color(0xFF2D8A57);
  static const green500 = Color(0xFF44A66D);
  static const green100 = Color(0xFFDCEFE2);
  static const green050 = Color(0xFFF4FBF6);

  static const background = Color(0xFFF6FBF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEAF5EE);
  static const border = Color(0xFFCCE2D4);

  static const darkBackground = Color(0xFF07110C);
  static const darkSurface = Color(0xFF102019);
  static const darkSurfaceVariant = Color(0xFF173227);
  static const darkBorder = Color(0xFF274939);

  static const success = Color(0xFF2D8A57);
  static const warning = Color(0xFFC98B2E);
  static const error = Color(0xFFB94848);
  static const info = Color(0xFF3E7BFA);

  static const textPrimary = Color(0xFF102019);
  static const textSecondary = Color(0xFF547161);
  static const textTertiary = Color(0xFF809486);

  static const darkTextPrimary = Color(0xFFF1F7F2);
  static const darkTextSecondary = Color(0xFFBCD0C1);
  static const darkTextTertiary = Color(0xFF89A291);

  static const storeColor = Color(0xFF1D6B46);
  static const courierColor = Color(0xFF377B78);
  static const adminColor = Color(0xFF215D7C);

  static const navBg = Color(0xFF133523);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF7FCF8), Color(0xFFE0F1E4), Color(0xFFCFE8D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF08120D), Color(0xFF123322), Color(0xFF18492E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientRed = LinearGradient(
    colors: [green700, green500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlack = LinearGradient(
    colors: [green900, green700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientStore = LinearGradient(
    colors: [green700, Color(0xFF56B67A)],
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
    colors: [Color(0xFF79B86D), Color(0xFF3F8F56)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentLight = green050;
  static const accent = green500;
  static const primary = green700;
  static const primaryDark = green900;
  static const primaryLight = green100;
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.green500,
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
            borderRadius: BorderRadius.circular(18),
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
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.green050,
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
      seedColor: AppColors.green500,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
      primary: AppColors.green500,
      secondary: AppColors.green100,
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
          borderSide: const BorderSide(color: AppColors.green500, width: 1.8),
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
          backgroundColor: AppColors.green500,
          foregroundColor: AppColors.black,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green100,
          side: const BorderSide(color: AppColors.green500),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
        selectedColor: AppColors.green500,
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
