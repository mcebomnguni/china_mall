import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../cart/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _giftMessageCtrl = TextEditingController();
  bool _placing = false;
  bool _sendToOther = false;
  bool _isGift = false;

  static const _provinces = [
    'Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape',
    'Limpopo', 'Mpumalanga', 'North West', 'Free State', 'Northern Cape'
  ];
  String _province = 'Gauteng';

  @override
  void dispose() {
    for (final c in [_addressCtrl, _cityCtrl, _postalCtrl, _notesCtrl, _recipientNameCtrl, _recipientPhoneCtrl, _giftMessageCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);

    final cart = context.read<CartProvider>();
    final res = await ApiService.createOrder({
      'items': cart.items.map((i) => i.toOrderItem()).toList(),
      'delivery_method': cart.deliveryMethod,
      'delivery_address': _addressCtrl.text.trim(),
      'delivery_city': _cityCtrl.text.trim(),
      'delivery_province': _province,
      'delivery_postal_code': _postalCtrl.text.trim(),
      'buyer_notes': _notesCtrl.text.trim(),
    });

    setState(() => _placing = false);
    if (!mounted) return;

    if (res.isSuccess) {
      final orderId = res.data['id'];
      context.go('/payment/$orderId');
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
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Address',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressCtrl,
                decoration:
                    const InputDecoration(labelText: 'Street Address'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Postal Code'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Province dropdown
              DropdownButtonFormField<String>(
                initialValue: _province,
                decoration: InputDecoration(
                  labelText: 'Province',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: _provinces
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _province = v ?? 'Gauteng'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Order Notes (optional)'),
              ),

              const SizedBox(height: 20),

              // ── Send to someone else ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.userPlus, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Send to someone else',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _sendToOther,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _sendToOther = v),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _sendToOther
                          ? Column(
                              children: [
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _recipientNameCtrl,
                                  decoration: const InputDecoration(labelText: 'Recipient Name'),
                                  validator: (v) => _sendToOther && (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _recipientPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(labelText: 'Recipient Phone'),
                                  validator: (v) => _sendToOther && (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(LucideIcons.gift, size: 18, color: AppColors.textSecondary),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'This is a gift',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _isGift,
                                      activeTrackColor: AppColors.primary,
                                      onChanged: (v) => setState(() => _isGift = v),
                                    ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: _isGift
                                      ? Column(
                                          children: [
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller: _giftMessageCtrl,
                                              maxLength: 150,
                                              maxLines: 2,
                                              decoration: const InputDecoration(
                                                labelText: 'Gift Message',
                                                hintText: 'Add a personal message...',
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(LucideIcons.info, size: 14, color: AppColors.textTertiary),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'The recipient will only be notified on the day of delivery, not before.',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Text('Order Summary',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),

              // ── Delivery Schedule ───────────────────────────────────
              const _DeliveryScheduleCard(),
              const SizedBox(height: 16),

              ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        AppNetworkImage(
                          url: item.image,
                          width: 48,
                          height: 48,
                          radius: 10,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('x${item.quantity}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                        PriceText(price: item.total),
                      ],
                    ),
                  )),

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal',
                      style: Theme.of(context).textTheme.bodyMedium),
                  PriceText(price: cart.subtotal),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    cart.deliveryFee != null
                        ? 'R ${cart.deliveryFee!.toStringAsFixed(2)}'
                        : 'Calculated at payment',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: Theme.of(context).textTheme.headlineSmall),
                  PriceText(price: cart.total, large: true),
                ],
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Place Order',
                loading: _placing,
                onTap: _placeOrder,
                icon: CupertinoIcons.checkmark_shield,
              ),
              const SizedBox(height: 16),

              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.lock_fill,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text('Secured by 256-bit encryption',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery Schedule Card
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryScheduleCard extends StatelessWidget {
  const _DeliveryScheduleCard();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final String batchLabel;
    final String deliveryEstimate;

    if (hour < 9) {
      batchLabel = 'Morning Batch (9:00 AM)';
      deliveryEstimate = 'Expected delivery: Today by 1:00 PM';
    } else if (hour < 15) {
      batchLabel = 'Afternoon Batch (3:00 PM)';
      deliveryEstimate = 'Expected delivery: Today by 7:00 PM';
    } else {
      batchLabel = "Tomorrow's Morning Batch (9:00 AM)";
      deliveryEstimate = 'Expected delivery: Tomorrow by 1:00 PM';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.truck, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Delivery Schedule',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$batchLabel — $deliveryEstimate',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Orders are collected in batches at 9:00 AM and 3:00 PM daily from China Mall.',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
