import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  // ─── Currency ────────────────────────────────────────────────────────────
  static String formatCurrency(double amount, {String symbol = 'R'}) {
    return '$symbol ${NumberFormat('#,##0.00').format(amount)}';
  }

  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return 'R${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'R${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'R${amount.toStringAsFixed(0)}';
  }

  // ─── Dates ───────────────────────────────────────────────────────────────
  static String formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String timeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return formatDate(isoString);
    } catch (_) {
      return isoString;
    }
  }

  // ─── Validation ──────────────────────────────────────────────────────────
  static String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final cleaned = v.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 9 || cleaned.length > 12) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateRequired(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? validatePrice(String? v) {
    if (v == null || v.isEmpty) return 'Price is required';
    final parsed = double.tryParse(v);
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    return null;
  }

  // ─── Status helpers ──────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'approved':
      case 'resolved':
      case 'paid':
        return const Color(0xFF22C55E);
      case 'cancelled':
      case 'rejected':
      case 'banned':
        return const Color(0xFFEF4444);
      case 'in_transit':
      case 'out_for_delivery':
      case 'picked_up':
      case 'in_review':
        return const Color(0xFF3B82F6);
      case 'payment_confirmed':
      case 'processing':
      case 'accepted':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFAAAAAF);
    }
  }

  // ─── SA Provinces ────────────────────────────────────────────────────────
  static const List<String> saProvinces = [
    'Gauteng',
    'Western Cape',
    'KwaZulu-Natal',
    'Eastern Cape',
    'Limpopo',
    'Mpumalanga',
    'North West',
    'Free State',
    'Northern Cape',
  ];
}
