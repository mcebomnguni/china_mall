class AppConstants {
  // Category slugs
  static const List<Map<String, String>> categories = [
    {'slug': 'clothing', 'label': 'Clothing', 'icon': '👘'},
    {'slug': 'shoes', 'label': 'Shoes', 'icon': '👟'},
    {'slug': 'blankets', 'label': 'Blankets', 'icon': '🛏'},
    {'slug': 'furniture', 'label': 'Furniture', 'icon': '🛋'},
    {'slug': 'carpets', 'label': 'Carpets', 'icon': '🪞'},
    {'slug': 'accessories', 'label': 'Accessories', 'icon': '💍'},
    {'slug': 'bags', 'label': 'Bags', 'icon': '👜'},
    {'slug': 'toys', 'label': 'Toys', 'icon': '🧸'},
    {'slug': 'kitchen', 'label': 'Kitchen', 'icon': '🍳'},
    {'slug': 'electronics', 'label': 'Electronics', 'icon': '📱'},
    {'slug': 'sportswear', 'label': 'Sportswear', 'icon': '⚽'},
  ];

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
  // For physical device on same WiFi, use your machine's IP:
  // static const String baseUrl = 'http://192.168.x.x:8000/api';
  // For production:
  // static const String baseUrl = 'https://api.chinamall.co.za/api';
}