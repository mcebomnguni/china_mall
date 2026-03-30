/// Central validation library — use in all TextFormField validators
class Validators {
  // ─── Required ─────────────────────────────────────────────────────────────
  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  // ─── Email ────────────────────────────────────────────────────────────────
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  // ─── Password ─────────────────────────────────────────────────────────────
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  // ─── Phone ────────────────────────────────────────────────────────────────
  static String? phone(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.length < 9 || cleaned.length > 13) {
      return 'Enter a valid phone number';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Phone must contain only numbers';
    return null;
  }

  // ─── Price ────────────────────────────────────────────────────────────────
  static String? price(String? v) {
    if (v == null || v.isEmpty) return 'Price is required';
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return 'Enter a valid price';
    if (d <= 0) return 'Price must be greater than 0';
    if (d > 999999) return 'Price seems too high';
    return null;
  }

  // ─── Stock quantity ───────────────────────────────────────────────────────
  static String? quantity(String? v) {
    if (v == null || v.isEmpty) return 'Quantity is required';
    final i = int.tryParse(v);
    if (i == null) return 'Enter a whole number';
    if (i < 0) return 'Quantity cannot be negative';
    if (i > 99999) return 'Quantity seems too high';
    return null;
  }

  // ─── Name ─────────────────────────────────────────────────────────────────
  static String? name(String? v, {int min = 2, int max = 50}) {
    if (v == null || v.isEmpty) return 'Name is required';
    if (v.trim().length < min) return 'Name must be at least $min characters';
    if (v.trim().length > max) return 'Name must be under $max characters';
    return null;
  }

  // ─── Postal code (SA) ─────────────────────────────────────────────────────
  static String? postalCode(String? v) {
    if (v == null || v.isEmpty) return 'Postal code is required';
    if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) {
      return 'Enter a valid 4-digit postal code';
    }
    return null;
  }

  // ─── URL ──────────────────────────────────────────────────────────────────
  static String? url(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final re = RegExp(r'^https?://[^\s/$.?#].[^\s]*$', caseSensitive: false);
    if (!re.hasMatch(v.trim())) return 'Enter a valid URL starting with http:// or https://';
    return null;
  }

  // ─── Min length ───────────────────────────────────────────────────────────
  static String? Function(String?) minLength(int min, [String? field]) {
    return (String? v) {
      if (v == null || v.isEmpty) return '${field ?? 'This field'} is required';
      if (v.trim().length < min) return '${field ?? 'This field'} must be at least $min characters';
      return null;
    };
  }
}
