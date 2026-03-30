import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int id;
  const OrderTrackingScreen({super.key, required this.id});

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map? _tracking;
  bool _loading = true;
  Timer? _refreshTimer;

  // Statuses that benefit from auto-refresh (order is in motion).
  static const _liveStatuses = {
    'in_transit', 'out_for_delivery', 'picked_up', 'awaiting_pickup',
  };

  static const _statusOrder = [
    'pending_payment',
    'payment_confirmed',
    'processing',
    'awaiting_pickup',
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  // ── Load + auto-refresh ────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = _tracking == null);
    final res = await ApiService.trackOrder(widget.id);
    if (!mounted) return;
    setState(() {
      _tracking = res.isSuccess ? res.data : _tracking;
      _loading  = false;
    });

    // Start/stop 30-second auto-refresh based on whether the order is live.
    _updateRefreshTimer();
  }

 
  void _updateRefreshTimer() {
    _refreshTimer?.cancel();
    final status = _tracking?['status'] ?? '';
    if (_liveStatuses.contains(status)) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _load(),
      );
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
 
    final currentStatus = _tracking?['status'] ?? '';
    final timeline      = _tracking?['timeline'] as List? ?? [];
    final currentIdx    = _statusOrder.indexOf(currentStatus);
    final isLive        = _liveStatuses.contains(currentStatus);
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Track Order',
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
          onPressed: _safePop,
          tooltip: 'Back',
        ),
        actions: [
          // Live badge — tells user auto-refresh is active.
          if (isLive)
            Padding(
              padding:
                  const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Live',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ── Current status card ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.orderStatusLabels[currentStatus] ??
                        currentStatus,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_tracking?['estimated_delivery'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Est. delivery: ${_tracking!['estimated_delivery']}',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (isLive) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Auto-refreshing every 30 seconds',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
 
            // ── Progress steps ─────────────────────────────────────
            Text('Delivery Progress',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
 
            ...List.generate(_statusOrder.length, (i) {
              final s        = _statusOrder[i];
              if (s == 'pending_payment') {
                return const SizedBox.shrink();
              }
              final isDone    = currentIdx >= i;
              final isCurrent = currentIdx == i;
              final label = AppConstants.orderStatusLabels[s] ?? s;
 
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primary
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone
                              ? CupertinoIcons.checkmark
                              : CupertinoIcons.circle,
                          size: 14,
                          color: isDone
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (i < _statusOrder.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: isDone && currentIdx > i
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isDone
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        if (isCurrent)
                          const Text(
                            'In Progress',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
 
            // ── Courier info ───────────────────────────────────────
            if (_tracking?['courier'] != null) ...[
              const SizedBox(height: 24),
              Text('Your Courier',
                  style:
                      Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          CupertinoIcons.person_fill,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tracking!['courier']['name'] ??
                                'Courier',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          Text(
                            _tracking!['courier']['vehicle'] ??
                                '',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
 
            // ── Event log ──────────────────────────────────────────
            if (timeline.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Event Log',
                  style:
                      Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ...timeline.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['description'] ??
                                  event['status'] ??
                                  '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                            Text(
                              event['timestamp'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
 
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}