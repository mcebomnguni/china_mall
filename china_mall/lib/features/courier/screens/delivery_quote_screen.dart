import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/theme/app_theme.dart';
import 'delivery_tracking_screen.dart';
 
class DeliveryQuoteScreen extends StatefulWidget {
  final int orderId;
  final double pickupLat, pickupLng;
  final double deliveryLat, deliveryLng;
  final String pickupAddress, deliveryAddress;
 
  const DeliveryQuoteScreen({
    super.key,
    required this.orderId,
    required this.pickupLat, required this.pickupLng,
    required this.deliveryLat, required this.deliveryLng,
    required this.pickupAddress, required this.deliveryAddress,
  });
 
  @override
  State<DeliveryQuoteScreen> createState() => _DeliveryQuoteScreenState();
}
 
class _DeliveryQuoteScreenState extends State<DeliveryQuoteScreen> {
  Map<String, dynamic>? _quote;
  bool _loading = true;
  bool _booking = false;
  String? _selected; // 'courier_guy' or 'app_driver'
 
  @override
  void initState() {
    super.initState();
    _loadQuote();
  }
 
  Future<void> _loadQuote() async {
    setState(() => _loading = true);
    try {
      final quote = await DeliveryService.getDeliveryQuote(
        pickupLat: widget.pickupLat, pickupLng: widget.pickupLng,
        deliveryLat: widget.deliveryLat, deliveryLng: widget.deliveryLng,
      );
      setState(() {
        _quote = quote;
        // Pre-select the recommended option
        _selected = quote['recommended'];
      });
    } catch (_) {
      _showSnack('Failed to load delivery options.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }
 
  Future<void> _confirmBooking() async {
    if (_selected == null) return;
    setState(() => _booking = true);
    try {
      final res = await DeliveryService.bookDelivery(
        orderId: widget.orderId,
        deliveryType: _selected!,
        pickupAddress: widget.pickupAddress,
        pickupLat: widget.pickupLat, pickupLng: widget.pickupLng,
        deliveryAddress: widget.deliveryAddress,
        deliveryLat: widget.deliveryLat, deliveryLng: widget.deliveryLng,
      );
      if (res['statusCode'] == 201) {
        if (mounted) {
          final deliveryId = res['id'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryTrackingScreen(
                deliveryId: deliveryId,
                deliveryType: _selected!,
              ),
            ),
          );
        }
      } else {
        _showSnack(res['error'] ?? 'Booking failed.', error: true);
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _booking = false);
    }
  }
 
  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Choose Delivery',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding best delivery options...'),
                ],
              ),
            )
          : _quote == null
              ? const Center(child: Text('No delivery options available.'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recommended banner
                            if (_quote!['recommended'] != 'none')
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.recommend, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _quote!['recommended_reason'] ?? '',
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
 
                            const Text('Select Delivery Option',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
 
                            // Courier Guy option
                            _DeliveryOptionCard(
                              title: 'The Courier Guy',
                              icon: Icons.local_shipping,
                              available: _quote!['courier_guy_available'] == true,
                              price: _quote!['courier_guy_price'],
                              etaMinutes: _quote!['courier_guy_eta_minutes'],
                              isRecommended: _quote!['recommended'] == 'courier_guy',
                              isSelected: _selected == 'courier_guy',
                              onTap: _quote!['courier_guy_available'] == true
                                  ? () => setState(() => _selected = 'courier_guy')
                                  : null,
                            ),
                            const SizedBox(height: 12),
 
                            // App Driver option
                            _DeliveryOptionCard(
                              title: 'App Driver',
                              icon: Icons.directions_car,
                              available: _quote!['app_driver_available'] == true,
                              price: _quote!['app_driver_price'],
                              etaMinutes: _quote!['app_driver_eta_minutes'],
                              isRecommended: _quote!['recommended'] == 'app_driver',
                              isSelected: _selected == 'app_driver',
                              onTap: _quote!['app_driver_available'] == true
                                  ? () => setState(() => _selected = 'app_driver')
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
 
                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selected == null || _booking)
                              ? null
                              : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _booking
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Confirm Delivery',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
 
class _DeliveryOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool available;
  final dynamic price;
  final dynamic etaMinutes;
  final bool isRecommended;
  final bool isSelected;
  final VoidCallback? onTap;
 
  const _DeliveryOptionCard({
    required this.title,
    required this.icon,
    required this.available,
    required this.price,
    required this.etaMinutes,
    required this.isRecommended,
    required this.isSelected,
    this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: !available
              ? Colors.grey.shade100
              : isSelected
                  ? primary.withValues(alpha: 0.05)
                  : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 40,
                color: !available ? Colors.grey : isSelected ? primary : Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: !available ? Colors.grey : null)),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Fastest',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!available)
                    const Text('Not available',
                        style: TextStyle(color: Colors.grey))
                  else
                    Text(
                      etaMinutes != null
                          ? '~$etaMinutes min · R$price'
                          : 'R$price',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (available)
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? primary : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}