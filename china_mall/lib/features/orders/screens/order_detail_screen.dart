import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/write_review_sheet.dart';
 
class OrderDetailScreen extends StatefulWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});
 
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}
 
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map?   _order;
  bool   _loading    = true;
  bool   _cancelling = false;
  bool   _loadError  = false; // distinguish network error from "not found"
  bool   _reviewDismissed = false;
 
  @override
  void initState() {
    super.initState();
    _load();
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
 
  // ── Load ───────────────────────────────────────────────────────────────────
 
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = false; });
    final res = await ApiService.getOrder(widget.id);
    if (!mounted) return;
    setState(() {
      _order     = res.isSuccess ? res.data : null;
      _loadError = !res.isSuccess;
      _loading   = false;
    });
  }
 
  // ── Cancel ─────────────────────────────────────────────────────────────────
 
  Future<void> _cancelOrder() async {
    setState(() => _cancelling = true);
    final res = await ApiService.cancelOrder(widget.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
 
    if (res.isSuccess) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
 
    // Network error — show retry instead of "Order not found".
    if (_loadError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: _safePop,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.wifi_slash,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text(
                'Could not load order',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
 
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: _safePop,
          ),
        ),
        body: EmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Order not found',
          subtitle: 'This order may have been removed.',
        ),
      );
    }
 
    final status    = _order!['status'] ?? '';
    final items     = _order!['items'] as List? ?? [];
    final canCancel = status == 'pending_payment' ||
        status == 'payment_confirmed';
    // Fixed: 'awaiting_pickup' was missing — matched order_model.dart
    final canTrack = ['in_transit', 'out_for_delivery',
        'picked_up', 'awaiting_pickup'].contains(status);
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _order!['order_number'] ?? 'Order Detail',
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
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Review prompt (delivered orders) ──────────────────
            if (status == 'delivered' && !_reviewDismissed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.star, size: 22, color: const Color(0xFFD97706)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How was your experience?',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Leave a review to help other shoppers',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final firstItem = (items.isNotEmpty) ? items.first : null;
                                    final productId = firstItem?['product']?['id'];
                                    if (productId != null) {
                                      WriteReviewSheet.show(
                                        context,
                                        targetId: productId,
                                        type: ReviewType.product,
                                        targetName: firstItem?['product']?['name'] ?? 'Product',
                                        onSubmitted: () => setState(() => _reviewDismissed = true),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  child: const Text('Write a Review'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 32,
                                child: TextButton(
                                  onPressed: () => setState(() => _reviewDismissed = true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textTertiary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  child: const Text('Maybe Later'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Status card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Status',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall),
                        const SizedBox(height: 4),
                        StatusChip(status: status),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall),
                      const SizedBox(height: 4),
                      PriceText(
                        price: (_order!['total_amount'] ?? 0)
                            .toDouble(),
                        large: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
 
            // ── Actions ────────────────────────────────────────────
            if (canTrack) ...[
              AppButton(
                label: 'Track Order',
                icon: CupertinoIcons.location_fill,
                onTap: () => context.go(
                    '/orders/${widget.id}/track'),
              ),
              const SizedBox(height: 12),
            ],
            if (canCancel) ...[
              AppButton(
                label: 'Cancel Order',
                outline: true,
                color: AppColors.error,
                loading: _cancelling,
                onTap: _showCancelDialog,
              ),
              const SizedBox(height: 24),
            ],
 
            // ── Delivery address ───────────────────────────────────
            Text('Delivery Address',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.location_fill,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      [
                        _order!['delivery_address'],
                        _order!['delivery_city'],
                        _order!['delivery_province'],
                        _order!['delivery_postal_code'],
                      ]
                          .where((v) => v != null && v != '')
                          .join(', '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
 
            // ── Items ──────────────────────────────────────────────
            Text('Items (${items.length})',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: item['product']?['image'],
                      width: 56,
                      height: 56,
                      radius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product']?['name'] ??
                                'Product',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Qty: ${item['quantity']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                      ),
                    ),
                    PriceText(
                      price:
                          (item['unit_price'] ?? 0).toDouble(),
                    ),
                  ],
                ),
              ),
            ),
 
            // ── Buyer notes ────────────────────────────────────────
            if (_order!['buyer_notes'] != null &&
                (_order!['buyer_notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes',
                  style:
                      Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_order!['buyer_notes'],
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
 
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
 
  // ── Cancel dialog ──────────────────────────────────────────────────────────
 
  void _showCancelDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? '
            'A 5% fee applies.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Keep Order'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder();
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}