import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'payment_security_screen.dart';

/// Entry point from CartScreen / CheckoutScreen.
/// Loads the order, shows a summary, then hands off to PaymentSecurityScreen.
class PaymentFlowScreen extends StatefulWidget {
  final int orderId;
  final double amount;

  const PaymentFlowScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  Map? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    // If orderId is 0 (cart hasn't created an order yet), skip fetch
    if (widget.orderId > 0) {
      final res = await ApiService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = res.isSuccess ? res.data : null;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  double get _amount {
    if (_order != null) {
      return (_order!['total_amount'] ?? widget.amount).toDouble();
    }
    return widget.amount;
  }

  // Convert amount in rands to cents for PaymentSecurityScreen
  int get _amountCents => (_amount * 100).round();

  String get _orderSummary {
    if (_order == null) return 'Order total: R ${_amount.toStringAsFixed(2)}';
    final items = (_order!['items'] as List?) ?? [];
    final lines = items.take(3).map((i) =>
        '${i['product_name'] ?? 'Item'} x${i['quantity']}').join('\n');
    final more = items.length > 3 ? '\n+${items.length - 3} more items' : '';
    return lines + more;
  }

  void _proceed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSecurityScreen(
          orderId: widget.orderId,
          amountCents: _amountCents,
          orderSummary: _orderSummary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Due',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R ${_amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (widget.orderId > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Order #${_order?['order_number'] ?? widget.orderId}',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order summary
                  if (_order != null) ...[
                    Text('Order Summary',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ...(_order!['items'] as List? ?? [])
                              .take(5)
                              .map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['product_name'] ?? 'Item',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'x${item['quantity']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'R${item['subtotal']}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              Text(
                                'R ${_amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Payment method info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.creditcard_fill,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yoco Card Payment',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Secured by fingerprint or PIN',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(CupertinoIcons.lock_fill,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Proceed to Pay — R ${_amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Security note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.lock_fill,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by 256-bit encryption',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
