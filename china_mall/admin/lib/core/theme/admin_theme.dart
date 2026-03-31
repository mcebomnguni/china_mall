import 'package:flutter/material.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
class AC {
  // Greens
  static const sidebar     = Color(0xFF0F2419);
  static const sidebarHover= Color(0xFF1A3C2B);
  static const primary     = Color(0xFF1D6B46);
  static const primaryLight= Color(0xFF2E8A5C);

  // Neutral
  static const bg          = Color(0xFFF4F6F3);
  static const surface     = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE4E8E2);
  static const textPrimary = Color(0xFF0F1A0D);
  static const textSecond  = Color(0xFF5C6B58);
  static const textMuted   = Color(0xFF9AA898);

  // Status
  static const success     = Color(0xFF16A34A);
  static const warning     = Color(0xFFD97706);
  static const error       = Color(0xFFDC2626);
  static const info        = Color(0xFF2563EB);

  // Chart palette
  static const chart1      = Color(0xFF1D6B46);
  static const chart2      = Color(0xFF2563EB);
  static const chart3      = Color(0xFFD97706);
  static const chart4      = Color(0xFFDC2626);
  static const chart5      = Color(0xFF7C3AED);
}

// ── Status badge helpers ──────────────────────────────────────────────────────
Color statusColor(String? s) {
  switch (s) {
    case 'approved': case 'active':        return AC.success;
    case 'pending':                         return AC.warning;
    case 'rejected':                        return AC.error;
    case 'more_info_required':
    case 'needs_changes':                   return AC.info;
    default:                                return AC.textMuted;
  }
}

String statusLabel(String? s) {
  switch (s) {
    case 'pending':            return 'Pending Review';
    case 'approved':           return 'Approved';
    case 'active':             return 'Active';
    case 'rejected':           return 'Rejected';
    case 'more_info_required': return 'More Info Required';
    case 'needs_changes':      return 'Changes Required';
    default:                   return s ?? 'Unknown';
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData adminTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AC.primary,
      surface: AC.surface,
      primary: AC.primary,
    ),
    scaffoldBackgroundColor: AC.bg,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w900),
      titleLarge:   TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium:  TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      bodyMedium:   TextStyle(fontSize: 14, color: AC.textPrimary),
      bodySmall:    TextStyle(fontSize: 12, color: AC.textSecond),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AC.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AC.primary,
        side: const BorderSide(color: AC.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AC.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AC.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AC.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AC.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AC.border),
      ),
      margin: EdgeInsets.zero,
    ),
  );
}
