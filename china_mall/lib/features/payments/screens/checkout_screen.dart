import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
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
  bool _placing = false;

  static const _provinces = [
    'Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape',
    'Limpopo', 'Mpumalanga', 'North West', 'Free State', 'Northern Cape'
  ];
  String _province = 'Gauteng';

  @override
  void dispose() {
    for (final c in [_addressCtrl, _cityCtrl, _postalCtrl, _notesCtrl]) {
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

              const SizedBox(height: 28),
              Text('Order Summary',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),

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
