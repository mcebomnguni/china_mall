import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
 
class CartItem {
  final int    productId;
  final String name;
  final String image;
  final double price;
  int          quantity;
  final int    storeId;
  final String storeName;
 
  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.storeId,
    required this.storeName,
  });
 
  Map<String, dynamic> toOrderItem() => {
        'product_id': productId,
        'quantity':   quantity,
      };
 
  double get total => price * quantity;
}
 
// ─────────────────────────────────────────────────────────────────────────────
 
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String  _deliveryMethod = 'standard';
  double? _deliveryFee;
  bool    _loading        = false;
  // Distinguish "empty cart" from "network error" for callers.
  String? _validateError;
 
  // ── Getters ────────────────────────────────────────────────────────────────
 
  List<CartItem> get items          => List.unmodifiable(_items);
  String         get deliveryMethod => _deliveryMethod;
  double?        get deliveryFee    => _deliveryFee;
  bool           get loading        => _loading;
  String?        get validateError  => _validateError;
 
  int    get count    => _items.fold(0, (sum, item) => sum + item.quantity);
  bool   get isEmpty  => _items.isEmpty;
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get total    => subtotal + (_deliveryFee ?? 0);
 
  // ── Mutations ──────────────────────────────────────────────────────────────
 
  void addItem(CartItem item) {
    final idx =
        _items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
 
  void removeItem(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }
 
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx =
        _items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      _items[idx].quantity = quantity;
      notifyListeners();
    }
  }
 
  void setDeliveryMethod(String method) {
    _deliveryMethod = method;
    notifyListeners();
  }
 
  // ── Validate cart ──────────────────────────────────────────────────────────
 
  /// Returns the validated cart data on success, or null on failure.
  /// Check [validateError] to distinguish a network failure from an empty cart.
  Future<Map?> validateCart() async {
    if (_items.isEmpty) {
      _validateError = null;
      return null;
    }
 
    _loading       = true;
    _validateError = null;
    notifyListeners();
 
    try {
      final res = await ApiService.checkCart(
        _items.map((i) => i.toOrderItem()).toList(),
        _deliveryMethod,
      );
 
      _loading = false;
 
      if (res.isSuccess) {
        _deliveryFee   = (res.data['delivery_fee'] ?? 0).toDouble();
        _validateError = null;
        notifyListeners();
        return res.data;
      } else {
        // Surface the error so callers can show it to the user.
        _validateError = res.errorMessage.isNotEmpty
            ? res.errorMessage
            : 'Could not validate cart. Please try again.';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _loading       = false;
      _validateError = 'Network error. Please check your connection.';
      notifyListeners();
      return null;
    }
  }
 
  // ── Clear ──────────────────────────────────────────────────────────────────
 
  void clear() {
    _items.clear();
    _deliveryFee   = null;
    _validateError = null;
    notifyListeners();
  }
}