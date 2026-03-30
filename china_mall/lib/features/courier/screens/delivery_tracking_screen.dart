import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/theme/app_theme.dart';
 
class DeliveryTrackingScreen extends StatefulWidget {
  final int deliveryId;
  final String deliveryType;
 
  const DeliveryTrackingScreen({
    super.key,
    required this.deliveryId,
    required this.deliveryType,
  });
 
  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}
 
class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  Map<String, dynamic>? _delivery;
  Timer? _pollTimer;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};  // ignore: prefer_final_fields
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 10 seconds for app driver, every 30 for Courier Guy
    final interval = widget.deliveryType == 'app_driver' ? 10 : 30;
    _pollTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _load(),
    );
  }
 
  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
 
  Future<void> _load() async {
    try {
      final delivery = await DeliveryService.trackDelivery(widget.deliveryId);
      if (mounted) {
        setState(() {
          _delivery = delivery;
          _loading = false;
        });
        _updateMap(delivery);
      }
    } catch (_) {}
  }
 
  void _updateMap(Map<String, dynamic> delivery) {
    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];  // ignore: unused_local_variable
 
    // Pickup marker
    if (delivery['pickup_lat'] != null && delivery['pickup_lng'] != null) {
      final pickupPos = LatLng(
        double.parse(delivery['pickup_lat'].toString()),
        double.parse(delivery['pickup_lng'].toString()),
      );
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ));
    }
 
    // Delivery marker
    if (delivery['delivery_lat'] != null && delivery['delivery_lng'] != null) {
      final deliveryPos = LatLng(
        double.parse(delivery['delivery_lat'].toString()),
        double.parse(delivery['delivery_lng'].toString()),
      );
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: deliveryPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery'),
      ));
    }
 
    // Driver location (app driver only)
    final latest = delivery['latest_location'];
    if (latest != null && widget.deliveryType == 'app_driver') {
      final driverPos = LatLng(
        double.parse(latest['lat'].toString()),
        double.parse(latest['lng'].toString()),
      );
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver'),
      ));
 
      // Move camera to driver
      _mapController?.animateCamera(CameraUpdate.newLatLng(driverPos));
    }
 
    setState(() {
      _markers = markers;
    });
  }
 
  String _formatEta() {
    if (_delivery == null) return '';
    final eta = _delivery!['estimated_delivery_time'];
    if (eta == null) return 'Estimating...';
    try {
      final dt = DateTime.parse(eta).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
 
  Color _statusColor(String? s) {
    switch (s) {
      case 'delivered': return Colors.green;
      case 'in_transit':
      case 'out_for_delivery': return Colors.blue;
      case 'picked_up': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final status = _delivery?['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final isAppDriver = widget.deliveryType == 'app_driver';
 
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isAppDriver ? 'Track Driver' : 'Track Shipment',
          style: const TextStyle(
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
              context.go('/orders');
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: statusColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: statusColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 16),
                          ),
                          if (_formatEta().isNotEmpty)
                            Text('ETA: ${_formatEta()}',
                                style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
 
                // Map
                Expanded(
                  flex: 3,
                  child: isAppDriver
                      ? GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(-26.2041, 28.0473), // Joburg default
                            zoom: 13,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          onMapCreated: (c) => _mapController = c,
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                        )
                      : _CourierGuyTrackingPanel(delivery: _delivery),
                ),
 
                // Status timeline
                Expanded(
                  flex: 2,
                  child: _StatusTimeline(currentStatus: status),
                ),
 
                // Courier Guy waybill link
                if (_delivery?['courier_guy_tracking_url'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      icon: const Icon(CupertinoIcons.globe,
                          color: AppColors.primary),
                      label: const Text(
                        'Track on Courier Guy Website',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final url = Uri.parse(
                            _delivery!['courier_guy_tracking_url']);
                        final launched = await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                        if (!mounted) return;
                        if (!launched) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Could not open tracking URL.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
 
// ── Courier Guy panel (no GPS, just status) ───────────────────────────────────
 
class _CourierGuyTrackingPanel extends StatelessWidget {
  final Map<String, dynamic>? delivery;
  const _CourierGuyTrackingPanel({this.delivery});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_shipping, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('The Courier Guy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (delivery?['courier_guy_waybill'] != null)
            Text('Waybill: ${delivery!['courier_guy_waybill']}',
                style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Track using the link below or on their website.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
 
// ── Status timeline widget ────────────────────────────────────────────────────
 
class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
 
  const _StatusTimeline({required this.currentStatus});
 
  static const _steps = [
    ('pending', 'Order Placed', Icons.receipt),
    ('assigned', 'Driver Assigned', Icons.person),
    ('picked_up', 'Picked Up', Icons.inventory),
    ('in_transit', 'In Transit', Icons.local_shipping),
    ('out_for_delivery', 'Out for Delivery', Icons.near_me),
    ('delivered', 'Delivered', Icons.check_circle),
  ];
 
  int get _currentIndex {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == currentStatus) return i;
    }
    return 0;
  }
 
  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _steps.length,
      itemBuilder: (_, i) {
        final done = i <= current;
        final active = i == current;
        return Row(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  child: Icon(_steps[i].$3,
                      size: 14,
                      color: done ? Colors.white : Colors.grey),
                ),
                if (i < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 20,
                    color: done
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              _steps[i].$2,
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : done
                        ? Colors.black
                        : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}