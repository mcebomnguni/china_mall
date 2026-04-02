import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppConstants {
  // ── Top-level category groups ──────────────────────────────────────────────
  static const List<Map<String, String>> categoryGroups = [
    {'slug': 'clothes',     'label': 'Clothes'},
    {'slug': 'household',   'label': 'Household'},
    {'slug': 'electronics', 'label': 'Electronics'},
  ];

  // ── Sub-categories (ordered by parent group) ───────────────────────────────
  static const List<Map<String, String>> categories = [
    // Clothes
    {'slug': 'clothing',    'label': 'Clothing',    'parent': 'clothes'},
    {'slug': 'shoes',       'label': 'Shoes',       'parent': 'clothes'},
    {'slug': 'accessories', 'label': 'Accessories', 'parent': 'clothes'},
    {'slug': 'sportswear',  'label': 'Sportswear',  'parent': 'clothes'},
    {'slug': 'bags',        'label': 'Bags',        'parent': 'clothes'},
    // Household
    {'slug': 'blankets',    'label': 'Blankets',    'parent': 'household'},
    {'slug': 'furniture',   'label': 'Furniture',   'parent': 'household'},
    {'slug': 'carpets',     'label': 'Carpets',     'parent': 'household'},
    {'slug': 'kitchen',     'label': 'Kitchen',     'parent': 'household'},
    {'slug': 'toys',        'label': 'Toys',        'parent': 'household'},
    // Electronics
    {'slug': 'electronics', 'label': 'Electronics', 'parent': 'electronics'},
  ];

  // ── Category icon mapping (slug -> Lucide icon) ────────────────────────────
  static final Map<String, IconData> categoryIcons = {
    // Groups
    'clothes':     LucideIcons.shirt,
    'household':   LucideIcons.sofa,
    'electronics': LucideIcons.smartphone,
    // Sub-categories
    'clothing':    LucideIcons.shirt,
    'shoes':       LucideIcons.footprints,
    'accessories': LucideIcons.gem,
    'sportswear':  LucideIcons.dumbbell,
    'bags':        LucideIcons.shoppingBag,
    'blankets':    LucideIcons.bedDouble,
    'furniture':   LucideIcons.sofa,
    'carpets':     LucideIcons.frame,
    'kitchen':     LucideIcons.chefHat,
    'toys':        LucideIcons.baby,
  };

  /// Returns the Lucide icon for a category slug.
  static IconData categoryIcon(String slug) =>
      categoryIcons[slug] ?? LucideIcons.tag;

  /// Returns the parent group slug for a given sub-category slug.
  static String? categoryParent(String slug) {
    for (final c in categories) {
      if (c['slug'] == slug) return c['parent'];
    }
    return null;
  }

  /// Returns all sub-categories under a given parent group slug.
  static List<Map<String, String>> categoriesForParent(String parentSlug) =>
      categories.where((c) => c['parent'] == parentSlug).toList();

  // Order statuses with labels
  static const Map<String, String> orderStatusLabels = {
    'pending_payment': 'Awaiting Payment',
    'payment_confirmed': 'Payment Confirmed',
    'processing': 'Processing',
    'awaiting_pickup': 'Awaiting Pickup',
    'picked_up': 'Picked Up',
    'in_transit': 'In Transit',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'return_requested': 'Return Requested',
    'returned': 'Returned',
    'disputed': 'Disputed',
  };

  // Delivery methods
  static const Map<String, String> deliveryMethods = {
    'standard': 'Standard Delivery',
    'express': 'Express Delivery',
    'economy': 'Economy Delivery',
  };

  // Return reasons
  static const Map<String, String> returnReasons = {
    'damaged': 'Item is damaged',
    'incorrect': 'Wrong item received',
    'not_as_described': 'Not as described',
    'other': 'Other reason',
  };

  // User roles
  static const String roleBuyer = 'buyer';
  static const String roleVendor = 'vendor';
  static const String roleCourier = 'courier';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // Image placeholder
  static const String placeholderProduct =
      'https://via.placeholder.com/400x400?text=Product';
  static const String placeholderStore =
      'https://via.placeholder.com/400x200?text=Store';
  static const String placeholderAvatar =
      'https://via.placeholder.com/100x100?text=User';
}

class ApiConstants {
  // ── Change this to your deployed Django URL in production ──
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
