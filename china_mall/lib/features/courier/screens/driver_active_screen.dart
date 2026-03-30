import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/theme/app_theme.dart';
 
class DriverActiveScreen extends StatefulWidget {
  final int deliveryId;
  final String pickupAddress;
  final String deliveryAddress;
 
  const DriverActiveScreen({
    super.key,
    required this.deliveryId,
    required this.pickupAddress,
    required this.deliveryAddress,
  });
 
  @override
  State<DriverActiveScreen> createState() => _DriverActiveScreenState();
}
 
class _DriverActiveScreenState extends State<DriverActiveScreen> {
  Timer? _locationTimer;
  String _currentStatus = 'assigned';
  bool _updatingStatus = false;
  bool _isOnline = true;  // ignore: prefer_final_fields, unused_field
  bool _gpsError = false; // shown when location updates stop working
 
  static const _statusFlow = [
    'assigned',
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
  ];
 
  static const _statusLabels = {
    'assigned': 'Go to Pickup',
    'picked_up': 'Start Delivery',
    'in_transit': 'Almost There',
    'out_for_delivery': 'Mark Delivered',
    'delivered': 'Completed',
  };
 
  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }
 
  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
 
  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        // ignore: deprecated_member_use
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,  // ignore: deprecated_member_use
        );
        await DeliveryService.updateDriverLocation(
          deliveryId: widget.deliveryId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
        // Clear GPS error if it was previously set.
        if (_gpsError && mounted) setState(() => _gpsError = false);
      } catch (_) {
        // Surface the GPS failure so the driver knows sharing has stopped.
        if (mounted && !_gpsError) setState(() => _gpsError = true);
      }
    });
  }
 
  Future<void> _advanceStatus() async {
    final currentIndex = _statusFlow.indexOf(_currentStatus);
    if (currentIndex >= _statusFlow.length - 1) return;
 
    final nextStatus = _statusFlow[currentIndex + 1];
    setState(() => _updatingStatus = true);
 
    try {
      final res = await DeliveryService.updateDeliveryStatus(
        deliveryId: widget.deliveryId,
        status: nextStatus,
      );
      if (res['statusCode'] == 200) {
        setState(() => _currentStatus = nextStatus);
        if (nextStatus == 'delivered') {
          _locationTimer?.cancel();
          _showCompletionDialog();
        }
      } else {
        _showSnack('Failed to update status.', error: true);
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _updatingStatus = false);
    }
  }
 
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delivery Complete!',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Great job! The delivery has been marked as completed.',
          style: TextStyle(fontFamily: 'Satoshi'),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text(
              'Back to Home',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
 
  String get _nextActionLabel {
    final index = _statusFlow.indexOf(_currentStatus);
    if (index >= _statusFlow.length - 1) return 'Completed';
    final next = _statusFlow[index + 1];
    return _statusLabels[next] ?? 'Next';
  }
 
  @override
  Widget build(BuildContext context) {
    final isCompleted = _currentStatus == 'delivered';
 
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Active Delivery',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery ID
            Text('Delivery #${widget.deliveryId}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
 
            // Pickup
            _AddressCard(
              label: 'Pickup From',
              address: widget.pickupAddress,
              icon: Icons.store,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
 
            // Delivery
            _AddressCard(
              label: 'Deliver To',
              address: widget.deliveryAddress,
              icon: Icons.home,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
 
            // Status progress
            const Text('Delivery Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _StatusProgress(
              steps: _statusFlow,
              currentStatus: _currentStatus,
            ),
            const Spacer(),
 
            // GPS indicator — shows warning when location sharing fails
            Row(
              children: [
                Icon(
                  _gpsError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.location_fill,
                  color: _gpsError ? AppColors.warning : AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _gpsError
                      ? 'Location sharing paused — check GPS'
                      : 'Location sharing active',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: _gpsError
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontWeight: _gpsError
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleted || _updatingStatus ? null : _advanceStatus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      isCompleted ? AppColors.success : AppColors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _updatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompleted
                                ? CupertinoIcons.checkmark_circle
                                : CupertinoIcons.arrow_right,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _nextActionLabel,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _AddressCard extends StatelessWidget {
  final String label, address;
  final IconData icon;
  final Color color;
 
  const _AddressCard({
    required this.label, required this.address,
    required this.icon, required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color, fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text(address,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
class _StatusProgress extends StatelessWidget {
  final List<String> steps;
  final String currentStatus;
 
  const _StatusProgress({required this.steps, required this.currentStatus});
 
  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(currentStatus);
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= currentIndex;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 14,
                  color: done ? Colors.white : Colors.grey,
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: done && i < currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}