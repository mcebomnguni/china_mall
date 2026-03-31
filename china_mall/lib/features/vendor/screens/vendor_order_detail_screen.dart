import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const VendorOrderDetailScreen({super.key, required this.orderId});

  @override
  State<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  Map? _order;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getVendorOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = res.isSuccess ? res.data as Map : null;
      _loading = false;
    });
  }

  // ── Confirm order (payment_confirmed → processing) ────────────────────────
  Future<void> _confirmOrder() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Confirm Order'),
        content: const Text(
            'Payment has been verified. Mark this order as confirmed and start processing?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _updateStatus('processing');
  }

  // ── Pack ready (processing → awaiting_pickup with checklist) ──────────────
  Future<void> _markReady() async {
    final items = (_order?['items'] as List?) ?? [];
    if (items.isEmpty) {
      await _packWithChecklist(items);
      return;
    }
    await _packWithChecklist(items);
  }

  Future<void> _packWithChecklist(List items) async {
    final checked = <int>{};
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final allChecked = checked.length == items.length;
          return Padding(
            padding:
                EdgeInsets.fromLTRB(24, 20, 24,
                    MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Pack & Verify Checklist',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Tick each item once you\'ve confirmed it is packed correctly.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Item checklist
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final isChecked = checked.contains(i);
                      return GestureDetector(
                        onTap: () => setSheet(() {
                          if (isChecked) {
                            checked.remove(i);
                          } else {
                            checked.add(i);
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? Colors.green.withValues(alpha: 0.08)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChecked
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              AppNetworkImage(
                                url: item['product_image'] ?? '',
                                width: 44,
                                height: 44,
                                radius: 8,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product_name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Qty: ${item['quantity'] ?? 1}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isChecked
                                    ? CupertinoIcons
                                        .checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isChecked
                                    ? Colors.green
                                    : AppColors.textTertiary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${checked.length} / ${items.length} items verified',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (allChecked)
                      const Text(
                        'All items verified ✓',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allChecked
                          ? Colors.green
                          : AppColors.textTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: allChecked
                        ? () => Navigator.pop(ctx, true)
                        : null,
                    child: const Text(
                      'Mark as Ready for Pickup',
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
          );
        },
      ),
    );

    if (confirmed != true) return;

    // Generate 6-digit handoff code
    final code = (Random().nextInt(900000) + 100000).toString();
    await _updateStatus('awaiting_pickup', handoffCode: code);
  }

  Future<void> _updateStatus(String status, {String? handoffCode}) async {
    setState(() => _actionLoading = true);
    final res = await ApiService.updateVendorOrderStatus(
        widget.orderId, status,
        handoffCode: handoffCode);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage(status)),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.errorMessage)),
      );
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'processing':
        return 'Order confirmed! Now processing.';
      case 'awaiting_pickup':
        return 'Order packed and ready for courier pickup!';
      default:
        return 'Order updated.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_order != null
            ? _order!['order_number'] ?? '#${widget.orderId}'
            : 'Order Detail'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendor/orders');
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const EmptyState(
                  icon: CupertinoIcons.exclamationmark_circle,
                  title: 'Order not found',
                  subtitle: 'This order may no longer be available.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status & Summary ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _order!['order_number'] ??
                                              '#${_order!['id']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(_order!['created_at']),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(
                                      status: _order!['status'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _InfoRow(
                                  icon: CupertinoIcons.person_fill,
                                  label: 'Customer',
                                  value: _order!['buyer_name'] ?? '—'),
                              if ((_order!['buyer_phone'] ?? '').isNotEmpty)
                                _InfoRow(
                                    icon: CupertinoIcons.phone_fill,
                                    label: 'Phone',
                                    value: _order!['buyer_phone']),
                              if (_order!['delivery_address'] != null)
                                _InfoRow(
                                    icon: CupertinoIcons.location_fill,
                                    label: 'Address',
                                    value: _order!['delivery_address']),
                              _InfoRow(
                                  icon: Icons.payments,
                                  label: 'Total',
                                  value:
                                      'R${((_order!['total_amount'] ?? 0) as num).toStringAsFixed(2)}'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Handoff code (when awaiting_pickup) ───────────
                        if (_order!['status'] == 'awaiting_pickup' &&
                            _order!['handoff_code'] != null)
                          _HandoffCodeCard(
                              code: _order!['handoff_code']),

                        const SizedBox(height: 4),

                        // ── Items ─────────────────────────────────────────
                        Text('Items',
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        ...(_order!['items'] as List? ?? []).map(
                          (item) => _OrderItemRow(item: item),
                        ),

                        const SizedBox(height: 24),

                        // ── Action button ─────────────────────────────────
                        _buildActionButton(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildActionButton() {
    final status = _order?['status'] ?? '';
    if (_actionLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (status == 'payment_confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(CupertinoIcons.checkmark_circle,
              color: Colors.white),
          label: const Text(
            'Confirm Order',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          onPressed: _confirmOrder,
        ),
      );
    }
    if (status == 'processing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(CupertinoIcons.cube_box_fill,
              color: Colors.white),
          label: const Text(
            'Mark as Packed & Ready',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          onPressed: _markReady,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatDate(dynamic raw) {
    final dt = raw is String ? DateTime.tryParse(raw) : null;
    if (dt == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

// ── Handoff Code Card ─────────────────────────────────────────────────────────

class _HandoffCodeCard extends StatelessWidget {
  final String code;
  const _HandoffCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.lock_open_fill,
                  color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text(
                'Courier Handoff Code',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w900,
              fontSize: 40,
              letterSpacing: 8,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(CupertinoIcons.doc_on_clipboard,
                size: 14, color: AppColors.textSecondary),
            label: const Text(
              'Copy code',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Give this code to the courier when they collect the parcel.',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Order Item Row ────────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final Map item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = (item['quantity'] as num? ?? 1).toInt();
    final price = (item['price'] as num? ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: item['product_image'] ?? '',
            width: 56,
            height: 56,
            radius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? '',
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('Qty: $qty',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          PriceText(price: price),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
