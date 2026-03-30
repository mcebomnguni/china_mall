import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
class AppTheme {
  // COLORS
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color textGold = Color(0xFFD4AF37);

  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFFCCCCCC);

  static const Color darkBg = Color(0xFF121212);

  static const Color goldLight = Color(0xFFFFD54F);

  // ── Base Text Colors ──────────────────────────────────────────────────────
  // Dark mode: text must be LIGHT (near white / platinum) on dark backgrounds
  static const Color textOnDark        = Color(0xFFE5E4E2); // platinum — readable on dark
  static const Color textOnDarkMuted   = Color(0xFFAAAAAA); // muted platinum
  static const Color textOnDarkSubtle  = Color(0xFF777777); // subtle hint text on dark
 
  // Light mode: text must be DARK on light backgrounds
  static const Color textOnLight       = Color(0xFF1A1A1A); // near black
  static const Color textOnLightMuted  = Color(0xFF555555); // medium grey
  static const Color textOnLightSubtle = Color(0xFF999999); // hint text
 
  // ── Gold Palette ──────────────────────────────────────────────────────────
  static const Color gold          = Color(0xFFB8860B); // dark gold (use on light bg)
  static const Color goldBright    = Color(0xFFE6C84A); // highlight gold (use on dark bg)
  static const Color goldPale      = Color(0xFFF5E6A3); // pale gold tint
 
  // ── Platinum Palette ──────────────────────────────────────────────────────
  static const Color platinum      = Color(0xFFE5E4E2);
  static const Color platinumLight = Color(0xFFF2F1F0);
  static const Color platinumDark  = Color(0xFFB8B8B8);
 
  // ── Dark Theme Surfaces ───────────────────────────────────────────────────
  static const Color darkSurface   = Color(0xFF1A1A1A);
  static const Color darkSurface2  = Color(0xFF252525);
  static const Color darkBorder    = Color(0xFF3A3A3A);
 
  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF8F7F5);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF2F1F0);
  static const Color lightBorder   = Color(0xFFDDDBD8);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color success      = Color(0xFF2E7D52);
  static const Color successLight = Color(0xFF4CAF80);
  static const Color warning      = Color(0xFFD4A017);
  static const Color error        = Color(0xFFC0392B);
  static const Color info         = Color(0xFF2C5F8A);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color statusPending        = Color(0xFFD4A017);
  static const Color statusPendingOutcome = Color(0xFFE6A020);
  static const Color statusOpened        = Color(0xFF3A80B8);
  static const Color statusReturned      = Color(0xFFE67E22);
  static const Color statusApproved      = Color(0xFF2E9E62);
  static const Color statusDeclined      = Color(0xFFE03030);

  // ── Card Decorations ─────────────────────────────────────────────────────
  static BoxDecoration get cardDecorationDark => BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration get cardDecorationLight => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? cardDecorationDark : cardDecorationLight;
  }

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary  = isDark ? textOnDark       : textOnLight;
    final secondary = isDark ? textOnDarkMuted  : textOnLightMuted;
    final accent   = isDark ? goldBright       : gold;
 
    return TextTheme(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 48, fontWeight: FontWeight.w700,
        color: primary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 36, fontWeight: FontWeight.w600,
        color: primary, letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 28, fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: accent,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: accent,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: primary, letterSpacing: 0.5,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: secondary, letterSpacing: 0.8,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 15, color: primary,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14, color: secondary,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12, color: secondary,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: primary, letterSpacing: 1.2,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: secondary, letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: secondary, letterSpacing: 1.0,
      ),
    );
  }
 
  // ── DARK THEME ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary:          goldBright,    // gold accent — visible on dark
        onPrimary:        darkBg,        // text ON gold buttons → dark
        secondary:        platinum,
        onSecondary:      darkBg,
        surface:          darkSurface,
        onSurface:        textOnDark,    // ✅ platinum text on dark cards
        surfaceContainerHighest: darkSurface2,
        outline:          darkBorder,
        error:            error,
        onError:          Colors.white,
        primaryContainer: Color(0xFF2A2000),
        onPrimaryContainer: goldBright,
        secondaryContainer: darkSurface2,
        onSecondaryContainer: platinum,
      ),
      textTheme: _buildTextTheme(isDark: true),
 
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: goldBright, letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: platinum),
        actionsIconTheme: const IconThemeData(color: platinum),
      ),
 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldLight,
          foregroundColor: darkBg,       // dark text on gold button ✅
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
      ),
 
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldBright,   // bright gold text visible on dark ✅
          side: const BorderSide(color: goldBright, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2,
          ),
        ),
      ),
 
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldBright,
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),
 
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: goldBright, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnDarkMuted),
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnDarkSubtle),
        prefixIconColor: textOnDarkMuted,
        suffixIconColor: textOnDarkMuted,
        // Ensure typed text is visible ✅
        floatingLabelStyle: GoogleFonts.montserrat(fontSize: 13, color: goldBright),
      ),
 
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
 
      listTileTheme: const ListTileThemeData(
        textColor: textOnDark,
        iconColor: textOnDarkMuted,
      ),
 
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 0.5,
      ),
 
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface2,
        selectedColor: Color(0xFF3A2E00),
        labelStyle: GoogleFonts.montserrat(fontSize: 12, color: textOnDark),
        secondaryLabelStyle: GoogleFonts.montserrat(fontSize: 12, color: goldBright),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder),
        ),
        side: const BorderSide(color: darkBorder),
      ),
 
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: goldBright,
        unselectedItemColor: textOnDarkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 10),
      ),
 
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF2A2000),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: goldBright);
          }
          return const IconThemeData(color: textOnDarkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: goldBright);
          }
          return GoogleFonts.montserrat(fontSize: 10, color: textOnDarkMuted);
        }),
      ),
 
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.montserrat(fontSize: 14, color: textOnDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(darkSurface2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
 
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface2,
        contentTextStyle: GoogleFonts.montserrat(color: textOnDark, fontSize: 13),
        actionTextColor: goldBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
      ),
 
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 20, fontWeight: FontWeight.w700, color: goldBright,
        ),
        contentTextStyle: GoogleFonts.montserrat(fontSize: 14, color: textOnDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
 
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface2,
        textStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder),
        ),
      ),
 
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? goldBright : platinumDark),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? const Color(0xFF4A3800)
            : darkSurface2),
      ),
 
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? goldLight : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(darkBg),
        side: const BorderSide(color: darkBorder, width: 1.5),
      ),
 
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? goldBright : textOnDarkMuted),
      ),
 
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: goldBright,
        linearTrackColor: darkSurface2,
      ),
    );
  }
 
  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary:          gold,          // dark gold — visible on white ✅
        onPrimary:        Colors.white,
        secondary:        platinumDark,
        onSecondary:      textOnLight,
        surface:          lightSurface,
        onSurface:        textOnLight,   // ✅ dark text on light cards
        surfaceContainerHighest: lightSurface2,
        outline:          lightBorder,
        error:            error,
        onError:          Colors.white,
        primaryContainer: Color(0xFFFFF3CC),
        onPrimaryContainer: Color(0xFF5C4200),
        secondaryContainer: lightSurface2,
        onSecondaryContainer: textOnLight,
      ),
      textTheme: _buildTextTheme(isDark: false),
 
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: gold, letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: textOnLight),
        actionsIconTheme: const IconThemeData(color: textOnLightMuted),
      ),
 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,  // white text on gold ✅
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
      ),
 
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,          // dark gold text on white ✅
          side: const BorderSide(color: gold, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2,
          ),
        ),
      ),
 
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),
 
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnLightMuted),
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnLightSubtle),
        prefixIconColor: textOnLightMuted,
        suffixIconColor: textOnLightMuted,
        floatingLabelStyle: GoogleFonts.montserrat(fontSize: 13, color: gold),
      ),
 
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
 
      listTileTheme: const ListTileThemeData(
        textColor: textOnLight,
        iconColor: textOnLightMuted,
      ),
 
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 0.5,
      ),
 
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface2,
        selectedColor: Color(0xFFFFF0B3),
        labelStyle: GoogleFonts.montserrat(fontSize: 12, color: textOnLight),
        secondaryLabelStyle: GoogleFonts.montserrat(fontSize: 12, color: gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder),
        ),
        side: const BorderSide(color: lightBorder),
      ),
 
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: gold,
        unselectedItemColor: textOnLightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 1,
        selectedLabelStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 10),
      ),
 
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: const Color(0xFFFFF0B3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: gold);
          }
          return const IconThemeData(color: textOnLightMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: gold);
          }
          return GoogleFonts.montserrat(fontSize: 10, color: textOnLightMuted);
        }),
      ),
 
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.montserrat(fontSize: 14, color: textOnLight),
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(lightSurface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
 
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textOnLight,
        contentTextStyle: GoogleFonts.montserrat(color: lightSurface, fontSize: 13),
        actionTextColor: goldBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
      ),
 
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 20, fontWeight: FontWeight.w700, color: gold,
        ),
        contentTextStyle: GoogleFonts.montserrat(fontSize: 14, color: textOnLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
 
      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        textStyle: GoogleFonts.montserrat(fontSize: 13, color: textOnLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder),
        ),
        elevation: 4,
        shadowColor: const Color(0x1A000000),
      ),
 
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? gold : platinumDark),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? const Color(0xFFFFE47A)
            : lightSurface2),
      ),
 
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? gold : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: platinumDark, width: 1.5),
      ),
 
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? gold : textOnLightMuted),
      ),
 
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: lightSurface2,
      ),
    );
  }
 
  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB8860B), Color(0xFFD4A017), Color(0xFFE6C84A), Color(0xFFD4A017)],
    stops: [0.0, 0.3, 0.6, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
 
  static const LinearGradient goldGradientSimple = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFE6C84A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
 
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
 
  // ── Decorations (context-aware) ───────────────────────────────────────────
  /// Use this in dark mode only — gold border on dark card
  static BoxDecoration get goldBorderDecorationDark => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: gold.withValues(alpha: 0.4), width: 1),
  );
 
  /// Use this in light mode only — gold border on light card
  static BoxDecoration get goldBorderDecorationLight => BoxDecoration(
    color: lightSurface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: gold.withValues(alpha: 0.5), width: 1),
  );
 
  /// Returns the correct decoration based on current brightness
  static BoxDecoration goldBorderDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? goldBorderDecorationDark : goldBorderDecorationLight;
  }
 
  // ── Status helpers ────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending review':
      case 'pending_review':   return statusPending;
      case 'opened':           return statusOpened;
      case 'pending outcome':
      case 'pending_outcome':  return statusPendingOutcome;
      case 'returned':         return statusReturned;
      case 'approved':         return statusApproved;
      case 'declined':         return statusDeclined;
      default:                 return platinumDark;
    }
  }
 
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending_review':   return 'Pending Review';
      case 'opened':           return 'Opened';
      case 'pending_outcome':  return 'Pending Outcome';
      case 'returned':         return 'Returned';
      case 'approved':         return 'Approved';
      case 'declined':         return 'Declined';
      default:                 return status;
    }
  }
 
  // ── Convenience: text color for current theme ─────────────────────────────
  static Color primaryText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? textOnDark : textOnLight;
 
  static Color secondaryText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? textOnDarkMuted : textOnLightMuted;
 
  static Color accentGold(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? goldBright : gold;
}