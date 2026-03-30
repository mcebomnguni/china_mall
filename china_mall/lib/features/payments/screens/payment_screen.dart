import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../cart/providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  const PaymentScreen({super.key, required this.orderId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map? _order;
  bool _loading = true;
  bool _paying = false;
  bool _paid = false;
  Map? _paymentResult;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final res = await ApiService.getOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = res.isSuccess ? res.data : null;
      _loading = false;
    });
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    final res =
        await ApiService.payOrder(widget.orderId, 'test_token');
    setState(() => _paying = false);
    if (!mounted) return;

    if (res.isSuccess) {
      context.read<CartProvider>().clear();
      setState(() {
        _paid = true;
        _paymentResult = res.data;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_paid && _paymentResult != null) {
      return _SuccessView(result: _paymentResult!, orderId: widget.orderId);
    }

    final totalAmount = _order != null
        ? (_order!['total_amount'] ?? 0).toDouble()
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Order info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.bag_fill,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${widget.orderId}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            _order?['order_number'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Due',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium),
                      PriceText(price: totalAmount, large: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment method
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.creditcard_fill,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Yoco Card Payment',
                                style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            Text('Secured payment via Yoco',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const Spacer(),
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test mode notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🧪', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Test Mode — Payment always succeeds. No real money is charged.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              label: 'Pay R ${totalAmount.toStringAsFixed(2)}',
              loading: _paying,
              onTap: _pay,
              icon: CupertinoIcons.lock_fill,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Cancel',
              outline: true,
              color: AppColors.error,
              onTap: () => context.go('/orders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Map result;
  final int orderId;
  const _SuccessView({required this.result, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.success, size: 56),
              ),
              const SizedBox(height: 24),
              Text('Payment Successful!',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(result['message'] ?? 'Your order has been placed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Order',
                        value: result['order_number'] ?? ''),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Amount Paid',
                      value: 'R ${(result['amount_paid'] ?? 0).toStringAsFixed(2)}',
                    ),
                    if (result['vendor_payout_date'] != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Payout Date',
                        value: result['vendor_payout_date'],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Track My Order',
                icon: CupertinoIcons.location_fill,
                onTap: () => context.go('/orders/$orderId/track'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Home',
                outline: true,
                onTap: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
