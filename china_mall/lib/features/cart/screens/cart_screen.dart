import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../payments/screens/payment_flow_screen.dart';
import '../../products/screens/discount_voucher_screen.dart';
 
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
 
  @override
  State<CartScreen> createState() => _CartScreenState();
}
 
class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cart;
  bool   _loading         = true;
  bool   _checkingOut     = false;
  Map<String, dynamic>? _appliedVoucher;
  double _voucherDiscount = 0;
  double _deliveryFee     = 0;
  String _deliveryMethod  = 'standard';
 
  @override
  void initState() {
    super.initState();
    _loadCart();
  }
 
  // ── Auth headers ───────────────────────────────────────────────────────────
 
  Future<Map<String, String>> get _headers async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
 
  // ── Load cart ──────────────────────────────────────────────────────────────
 
  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      // Try Supabase cart fetch first
      try {
        final client = SupabaseService.client;
        final user = client.auth.currentUser;
        if (user != null) {
          final rpc = await client
              .from('carts')
              .select('*, cart_items(*, product:products(*))')
              .eq('profile_id', user.id)
              .limit(1)
              .maybeSingle();
          if (rpc != null) {
            final data = rpc;
            if (data is Map<String, dynamic>) {
              setState(() => _cart = data);
              await _fetchDeliveryFee();
              return;
            }
          }
        }
      } catch (_) {
        // fall back to HTTP
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cart/'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _cart = data);
        // Fetch delivery fee for the current method after cart loads.
        await _fetchDeliveryFee();
      } else {
        _showError('Failed to load cart. Please try again.');
      }
    } catch (_) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Delivery fee ───────────────────────────────────────────────────────────
 
  Future<void> _fetchDeliveryFee() async {
    // Try Postgres RPC via Supabase first, fall back to Django endpoint.
    try {
      final client = SupabaseService.client;
      final rpcRes = await client.rpc('calculate_delivery_fee', params: {
        'cart_json': _cart ?? {},
        'method': _deliveryMethod,
      });
      if (rpcRes != null) {
        final data = rpcRes;
        double fee = 0;
        if (data is num) {
          fee = (data as num).toDouble();
        } else if (data is List && data.isNotEmpty) {
          fee = double.tryParse(data[0].toString()) ?? 0;
        } else {
          fee = double.tryParse(data?.toString() ?? '0') ?? 0;
        }
        if (mounted) setState(() => _deliveryFee = fee);
        return;
      }
    } catch (_) {
      // ignore and fall back to HTTP
    }

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/cart/delivery-fee/'),
        headers: await _headers,
        body: jsonEncode({'method': _deliveryMethod}),
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _deliveryFee = (body['fee'] ?? 0).toDouble());
      }
    } catch (_) {
      // Non-critical — silently ignore, delivery fee stays at 0.
    }
  }
 
  // ── Update quantity ────────────────────────────────────────────────────────
 
  Future<void> _updateQty(int itemId, int newQty) async {
    // Try Supabase update first
    try {
      final client = SupabaseService.client;
      final upd = await client
          .from('cart_items')
          .update({'quantity': newQty})
          .eq('id', itemId)
          .select();
      await _loadCart();
      return;
    } catch (_) {}

    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/cart/items/$itemId/'),
      headers: await _headers,
      body: jsonEncode({'quantity': newQty}),
    );
    if (res.statusCode == 200 && mounted) {
      setState(() => _cart = jsonDecode(res.body) as Map<String, dynamic>);
    } else if (mounted) {
      _showError('Could not update quantity. Please try again.');
    }
  }
 
  // ── Remove item ────────────────────────────────────────────────────────────
 
  Future<void> _removeItem(int itemId) async {
    // Try Supabase delete first
    try {
      final client = SupabaseService.client;
      await client.from('cart_items').delete().eq('id', itemId);
      await _loadCart();
      return;
    } catch (_) {}

    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/cart/items/$itemId/'),
      headers: await _headers,
    );
    if (res.statusCode == 200 && mounted) {
      setState(() => _cart = jsonDecode(res.body) as Map<String, dynamic>);
    } else if (mounted) {
      _showError('Could not remove item. Please try again.');
    }
  }
 
  // ── Clear cart ─────────────────────────────────────────────────────────────
 
  Future<void> _clearCart() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Try Supabase clear first
      try {
        final client = SupabaseService.client;
        final user = client.auth.currentUser;
        if (user != null) {
          // delete cart_items where cart_id belongs to user
          final cartsRes =
              await client.from('carts').select('id').eq('profile_id', user.id);
          if ((cartsRes as List).isNotEmpty) {
            final cartId = cartsRes[0]['id'];
            await client.from('cart_items').delete().eq('cart_id', cartId);
            await _loadCart();
            return;
          }
        }
      } catch (_) {}

      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/cart/clear/'),
        headers: await _headers,
      );
      _loadCart();
    }
  }
 
  // ── Voucher callbacks ──────────────────────────────────────────────────────
 
  void _onVoucherApplied(Map<String, dynamic> result) {
    setState(() {
      _appliedVoucher  = result;
      _voucherDiscount = double.tryParse(
              result['discount_amount']?.toString() ?? '0') ??
          0;
    });
  }
 
  void _onVoucherRemoved() {
    setState(() {
      _appliedVoucher  = null;
      _voucherDiscount = 0;
    });
  }
 
  // ── Totals ─────────────────────────────────────────────────────────────────
 
  double get _cartSubtotal =>
      double.tryParse(_cart?['total']?.toString() ?? '0') ?? 0;
 
  double get _finalTotal =>
      (_cartSubtotal + _deliveryFee - _voucherDiscount)
          .clamp(0, double.infinity);
 
  // ── Checkout — create order first, THEN navigate to payment ───────────────
 
  Future<void> _checkout() async {
    final items = (_cart?['items'] as List?) ?? [];
    if (items.isEmpty) return;
 
    setState(() => _checkingOut = true);
 
    try {
      // Try Supabase order creation first (client-side writes to Postgres).
      try {
        final client = SupabaseService.client;
        final user = client.auth.currentUser;
        if (user != null) {
          final orderInsert = {
            'profile_id': user.id,
            'total_amount': _finalTotal,
            'currency': 'ZAR',
            'status': 'pending_payment',
            'shipping_address': _cart?['shipping_address'] ?? {},
            'payment_meta': {},
          };

          final orderRes = await client.from('orders').insert(orderInsert).select();
          if ((orderRes as List).isNotEmpty) {
            final created = Map<String, dynamic>.from(orderRes[0] as Map);
            final orderId = created['id'];

            // Insert order items
            final inserts = <Map<String, dynamic>>[];
            for (final it in items) {
              int? productId;
              if (it is Map<String, dynamic>) {
                if (it['product_id'] != null) productId = it['product_id'];
                else if (it['product'] is Map && it['product']['id'] != null) productId = it['product']['id'];
                else if (it['productId'] != null) productId = it['productId'];
              }
              final qty = (it['quantity'] ?? it['qty'] ?? 1) as int;
              double unitPrice = 0;
              if (it['price'] != null) unitPrice = double.tryParse(it['price'].toString()) ?? 0;
              else if (it['unit_price'] != null) unitPrice = double.tryParse(it['unit_price'].toString()) ?? 0;
              if (productId != null) {
                inserts.add({
                  'order_id': orderId,
                  'product_id': productId,
                  'quantity': qty,
                  'unit_price': unitPrice,
                });
              }
            }

            if (inserts.isNotEmpty) {
              await client.from('order_items').insert(inserts);
            }

            if (!mounted) return;
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => PaymentFlowScreen(
                  orderId: orderId,
                  amount: _finalTotal,
                ),
              ),
            );
            return;
          }
        }
      } catch (_) {
        // fall through to HTTP fallback
      }

      // HTTP fallback: use central ApiService which itself will try Supabase first
      final createRes = await ApiService.createOrder({
        'delivery_method': _deliveryMethod,
        if (_appliedVoucher != null) 'voucher_code': _appliedVoucher!['code'],
      });

      if (!mounted) return;

      if (createRes.isSuccess) {
        final order = createRes.data as Map<String, dynamic>;
        final orderId = order['id'] as int? ?? (order['order_id'] as int? ?? 0);
        final amount = double.tryParse(order['total']?.toString() ?? order['amount']?.toString() ?? _finalTotal.toString()) ?? _finalTotal;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => PaymentFlowScreen(
              orderId: orderId,
              amount: amount,
            ),
          ),
        );
      } else {
        _showError(createRes.errorMessage);
      }
    } catch (_) {
      if (mounted) _showError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }
 
  // ── Vendor-grouped list builder ─────────────────────────────────────────

  Widget _buildVendorGroupedList(List items) {
    final grouped = groupBy<dynamic, String>(
      items,
      (item) => (item as Map<String, dynamic>)['store_name']?.toString() ?? 'Unknown Store',
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (_, groupIndex) {
        final storeName = grouped.keys.elementAt(groupIndex);
        final storeItems = grouped[storeName]!;

        return Container(
          margin: EdgeInsets.only(bottom: groupIndex < grouped.length - 1 ? 12 : 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Vendor header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.store, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        storeName,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        for (final item in storeItems) {
                          await _removeItem((item as Map<String, dynamic>)['id']);
                        }
                      },
                      child: const Icon(LucideIcons.trash2, size: 16, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Items in this vendor group
              ...storeItems.map((item) {
                final cartItem = item as Map<String, dynamic>;
                return _VendorCartItem(
                  item: cartItem,
                  onQtyChanged: (qty) => _updateQty(cartItem['id'], qty),
                  onRemove: () => _removeItem(cartItem['id']),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final items = (_cart?['items'] as List?) ?? [];
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Cart (${_cart?['item_count'] ?? 0})',
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : items.isEmpty
              ? const _EmptyCart()
              : Column(
                  children: [
                    // ── Vendor-grouped items list ────────────────────
                    Expanded(
                      child: _buildVendorGroupedList(items),
                    ),

                    // ── Sticky bottom bar ───────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: const Border(
                            top: BorderSide(color: AppColors.border)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Delivery method selector
                          Row(
                            children: [
                              const Text(
                                'Delivery',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              DropdownButton<String>(
                                value: _deliveryMethod,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                items: AppConstants.deliveryMethods.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
                                onChanged: (v) async {
                                  setState(() => _deliveryMethod = v ?? 'standard');
                                  await _fetchDeliveryFee();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Voucher widget
                          VoucherApplyWidget(
                            orderTotal: _cartSubtotal,
                            onApplied: _onVoucherApplied,
                            onRemoved: _onVoucherRemoved,
                          ),
                          const SizedBox(height: 12),

                          // Total row
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'R${_finalTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (_voucherDiscount > 0)
                                    Text(
                                      'Saved R${_voucherDiscount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _checkingOut ? null : _checkout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _checkingOut
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Checkout',
                                          style: TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Vendor Cart Item (used inside vendor-grouped sections)
// ─────────────────────────────────────────────────────────────────────────────

class _VendorCartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onQtyChanged;
  final VoidCallback onRemove;

  const _VendorCartItem({
    required this.item,
    required this.onQtyChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = item['in_stock'] == false;
    final price = double.tryParse(item['price']?.toString() ?? item['subtotal']?.toString() ?? '0') ?? 0;
    final originalPrice = double.tryParse(item['original_price']?.toString() ?? '0') ?? 0;
    final hasDiscount = originalPrice > 0 && originalPrice > price;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                item['product_image'] != null
                    ? Image.network(
                        item['product_image'],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.surfaceVariant,
                          child: const Icon(LucideIcons.image, size: 20, color: AppColors.textTertiary),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.surfaceVariant,
                        child: const Icon(LucideIcons.image, size: 20, color: AppColors.textTertiary),
                      ),
                if (outOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Sold Out',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['variant'] != null || item['size'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [item['size'], item['variant']].where((e) => e != null).join(' / '),
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'R${item['subtotal'] ?? price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        'R${originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Quantity controls
                    _QtyButton(
                      icon: LucideIcons.minus,
                      onTap: () => item['quantity'] > 1
                          ? onQtyChanged(item['quantity'] - 1)
                          : onRemove(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item['quantity']}',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: LucideIcons.plus,
                      onTap: () => onQtyChanged(item['quantity'] + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qty Button
// ─────────────────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Empty Cart
// ─────────────────────────────────────────────────────────────────────────────
 
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.cart,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add products to get started',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              // go_router compatible — was pushNamedAndRemoveUntil which crashes
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Browse Products',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
