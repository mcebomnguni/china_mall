import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';
import '../_widgets/stat_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Data
  List<Map<String, dynamic>> _orders = [];

  bool    _loading = true;
  String? _error;

  // Filters
  int    _days   = 30;
  String _status = 'all';
  String _search = '';

  // ── Status definitions ──────────────────────────────────────────────────────

  static const _statusFilters = <String, String>{
    'all':               'All',
    'pending_payment':   'Pending Payment',
    'payment_confirmed': 'Payment Confirmed',
    'processing':        'Processing',
    'awaiting_pickup':   'Awaiting Pickup',
    'picked_up':         'Picked Up',
    'in_transit':        'In Transit',
    'out_for_delivery':  'Out for Delivery',
    'delivered':         'Delivered',
    'cancelled':         'Cancelled',
    'return_requested':  'Return Requested',
    'returned':          'Returned',
    'disputed':          'Disputed',
  };

  static Color _orderStatusColor(String? s) {
    switch (s) {
      case 'pending_payment':                     return AC.textMuted;
      case 'payment_confirmed':                   return AC.info;
      case 'processing':                          return AC.warning;
      case 'awaiting_pickup': case 'picked_up':   return AC.chart3;
      case 'in_transit': case 'out_for_delivery': return AC.primary;
      case 'delivered':                           return AC.success;
      case 'cancelled':                           return AC.error;
      case 'return_requested': case 'returned':   return AC.chart5;
      case 'disputed':                            return AC.error;
      default:                                    return AC.textMuted;
    }
  }

  static String _orderStatusLabel(String? s) {
    switch (s) {
      case 'pending_payment':   return 'Pending Payment';
      case 'payment_confirmed': return 'Payment Confirmed';
      case 'processing':        return 'Processing';
      case 'awaiting_pickup':   return 'Awaiting Pickup';
      case 'picked_up':         return 'Picked Up';
      case 'in_transit':        return 'In Transit';
      case 'out_for_delivery':  return 'Out for Delivery';
      case 'delivered':         return 'Delivered';
      case 'cancelled':         return 'Cancelled';
      case 'return_requested':  return 'Return Requested';
      case 'returned':          return 'Returned';
      case 'disputed':          return 'Disputed';
      default:                  return s ?? 'Unknown';
    }
  }

  static String _handoffLabel(String? stage) {
    switch (stage) {
      case 'store_packed':       return 'Packed';
      case 'courier_picked_up':  return 'Picked Up';
      case 'in_transit':         return 'In Transit';
      case 'delivered':          return 'Delivered';
      default:                   return stage ?? '-';
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminApi.getOrdersOverview(
        status: _status == 'all' ? null : _status,
        days: _days,
      );
      setState(() => _orders = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _orders;
    final q = _search.toLowerCase();
    return _orders.where((o) {
      return (o['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
          (o['order_id'] ?? '').toString().contains(q);
    }).toList();
  }

  // ── Stat helpers ────────────────────────────────────────────────────────────

  int _countByStatus(String s) =>
      _orders.where((o) => o['order_status'] == s).length;

  double get _totalRevenue => _orders.fold<double>(
      0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));

  // ── Track dialog ────────────────────────────────────────────────────────────

  Future<void> _showHandoffTrail(Map<String, dynamic> order) async {
    final orderId = (order['order_id'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (_) => _HandoffTrailDialog(orderId: orderId),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // Top bar
          Container(
            color: AC.surface,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Orders',
                  subtitle: 'Monitor all platform orders and delivery chain',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Period selector
                      _PeriodChip(
                        label: '7d',
                        selected: _days == 7,
                        onTap: () { setState(() => _days = 7); _loadOrders(); },
                      ),
                      const SizedBox(width: 6),
                      _PeriodChip(
                        label: '30d',
                        selected: _days == 30,
                        onTap: () { setState(() => _days = 30); _loadOrders(); },
                      ),
                      const SizedBox(width: 6),
                      _PeriodChip(
                        label: '90d',
                        selected: _days == 90,
                        onTap: () { setState(() => _days = 90); _loadOrders(); },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                        onPressed: _loadOrders,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stat cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    StatCard(
                      label: 'Total Orders',
                      value: '${_orders.length}',
                      icon: Icons.receipt_long_rounded,
                      color: AC.primary,
                    ),
                    StatCard(
                      label: 'Total Revenue',
                      value: 'R ${_totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AC.success,
                    ),
                    StatCard(
                      label: 'Processing',
                      value: '${_countByStatus('processing')}',
                      icon: Icons.hourglass_top_rounded,
                      color: AC.warning,
                    ),
                    StatCard(
                      label: 'In Transit',
                      value: '${_countByStatus('in_transit') + _countByStatus('out_for_delivery')}',
                      icon: Icons.local_shipping_rounded,
                      color: AC.info,
                    ),
                    StatCard(
                      label: 'Delivered',
                      value: '${_countByStatus('delivered')}',
                      icon: Icons.check_circle_rounded,
                      color: AC.chart1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status filter row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.entries.map((e) {
                      final active = _status == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(e.value,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AC.textSecond,
                              )),
                          selected: active,
                          onSelected: (_) {
                            setState(() => _status = e.key);
                            _loadOrders();
                          },
                          selectedColor: AC.primary,
                          backgroundColor: AC.surface,
                          side: BorderSide(color: active ? AC.primary : AC.border),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.border),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Row(
              children: [
                Text('${filtered.length} orders',
                    style: const TextStyle(color: AC.textMuted, fontSize: 12)),
                const Spacer(),
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by customer name or order ID...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      fillColor: AC.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AC.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Table header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AC.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                top: BorderSide(color: AC.border),
                left: BorderSide(color: AC.border),
                right: BorderSide(color: AC.border),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: _Hdr('ORDER #')),
                Expanded(flex: 2, child: _Hdr('CUSTOMER')),
                Expanded(flex: 1, child: _Hdr('AMOUNT')),
                Expanded(flex: 1, child: _Hdr('ITEMS')),
                Expanded(flex: 2, child: _Hdr('STORE(S)')),
                Expanded(flex: 2, child: _Hdr('STATUS')),
                Expanded(flex: 1, child: _Hdr('DELIVERY')),
                Expanded(flex: 1, child: _Hdr('LAST HANDOFF')),
                Expanded(flex: 1, child: _Hdr('COURIER')),
                Expanded(flex: 2, child: _Hdr('DATE')),
                Expanded(flex: 1, child: _Hdr('ACTION')),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AC.primary))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AC.error)))
                    : Container(
                        margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                        decoration: BoxDecoration(
                          color: AC.surface,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12)),
                          border: Border.all(color: AC.border),
                        ),
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No orders found',
                                    style: TextStyle(color: AC.textMuted)),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, color: AC.border),
                                itemBuilder: (_, i) {
                                  final o = filtered[i];
                                  final orderId =
                                      (o['order_id'] as num?)?.toInt() ?? 0;
                                  final amount =
                                      (o['total_amount'] as num?)?.toDouble() ??
                                          0;
                                  final itemCount =
                                      (o['item_count'] as num?)?.toInt() ?? 0;
                                  final status =
                                      o['order_status'] as String?;
                                  final delivery =
                                      o['delivery_status'] as String?;
                                  final lastHandoff =
                                      o['last_handoff'] as String?;
                                  final courier =
                                      o['courier_name'] as String?;

                                  DateTime? createdAt;
                                  try {
                                    createdAt = DateTime.parse(
                                        o['created_at'].toString());
                                  } catch (_) {}

                                  final statusColor = _orderStatusColor(status);
                                  final deliveryColor =
                                      _orderStatusColor(delivery);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '#$orderId',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AC.primary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                o['customer_name'] ?? '-',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                o['customer_email'] ?? '',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AC.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'R ${amount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '$itemCount',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AC.textSecond,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            o['store_names'] ?? '-',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AC.textSecond,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _OrderBadge(
                                            label:
                                                _orderStatusLabel(status),
                                            color: statusColor,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: delivery != null
                                              ? _OrderBadge(
                                                  label: _orderStatusLabel(
                                                      delivery),
                                                  color: deliveryColor,
                                                )
                                              : const Text('-',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AC.textMuted)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            _handoffLabel(lastHandoff),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AC.textSecond,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            courier ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AC.textSecond,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            createdAt != null
                                                ? dateFmt.format(createdAt)
                                                : '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AC.textMuted,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(
                                            height: 30,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _showHandoffTrail(o),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AC.primary,
                                                side: const BorderSide(
                                                    color: AC.primary),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                              ),
                                              child: const Text('Track',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Handoff Trail Dialog ────────────────────────────────────────────────────

class _HandoffTrailDialog extends StatefulWidget {
  final int orderId;
  const _HandoffTrailDialog({required this.orderId});

  @override
  State<_HandoffTrailDialog> createState() => _HandoffTrailDialogState();
}

class _HandoffTrailDialogState extends State<_HandoffTrailDialog> {
  List<Map<String, dynamic>> _handoffs = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await AdminApi.getOrderHandoffs(widget.orderId);
      if (mounted) setState(() { _handoffs = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static IconData _stageIcon(String? stage) {
    switch (stage) {
      case 'store_packed':       return Icons.inventory_2_rounded;
      case 'courier_picked_up':  return Icons.local_shipping_rounded;
      case 'in_transit':         return Icons.route_rounded;
      case 'out_for_delivery':   return Icons.delivery_dining_rounded;
      case 'delivered':          return Icons.check_circle_rounded;
      default:                   return Icons.circle_outlined;
    }
  }

  static String _stageLabel(String? stage) {
    switch (stage) {
      case 'store_packed':       return 'Store Packed';
      case 'courier_picked_up':  return 'Courier Picked Up';
      case 'in_transit':         return 'In Transit';
      case 'out_for_delivery':   return 'Out for Delivery';
      case 'delivered':          return 'Delivered';
      default:                   return stage ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Dialog(
      backgroundColor: AC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Icon(Icons.route_rounded, color: AC.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Handoff Trail  \u2014  Order #${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AC.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(color: AC.border),
            const SizedBox(height: 12),

            // Content
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: CircularProgressIndicator(color: AC.primary)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: Text(_error!,
                        style: const TextStyle(color: AC.error))),
              )
            else if (_handoffs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: Text('No handoff events yet',
                        style: TextStyle(color: AC.textMuted, fontSize: 13))),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_handoffs.length, (i) {
                      final h = _handoffs[i];
                      final stage = h['stage'] as String?;
                      final code = h['confirmation_code'] as String?;
                      final confirmedBy = h['confirmed_by_name'] as String?;
                      final isConfirmed = confirmedBy != null &&
                          confirmedBy.isNotEmpty;

                      DateTime? confirmedAt;
                      try {
                        confirmedAt = DateTime.parse(
                            h['confirmed_at'].toString());
                      } catch (_) {}

                      DateTime? createdAt;
                      try {
                        createdAt =
                            DateTime.parse(h['created_at'].toString());
                      } catch (_) {}

                      final isLast = i == _handoffs.length - 1;
                      final stageColor = isConfirmed ? AC.success : AC.textMuted;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline column
                            SizedBox(
                              width: 36,
                              child: Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: stageColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: stageColor.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _stageIcon(stage),
                                      size: 16,
                                      color: stageColor,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        margin:
                                            const EdgeInsets.symmetric(vertical: 4),
                                        color: AC.border,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Detail column
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _stageLabel(stage),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isConfirmed
                                            ? AC.textPrimary
                                            : AC.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Confirmation code
                                    if (code != null && code.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.qr_code_rounded,
                                              size: 13, color: AC.textMuted),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Code: $code',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AC.textSecond,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 2),
                                    // Confirmed by
                                    Row(
                                      children: [
                                        const Icon(Icons.person_rounded,
                                            size: 13, color: AC.textMuted),
                                        const SizedBox(width: 6),
                                        Text(
                                          isConfirmed
                                              ? confirmedBy!
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isConfirmed
                                                ? AC.textSecond
                                                : AC.textMuted,
                                            fontStyle: isConfirmed
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    // Timestamp
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded,
                                            size: 13, color: AC.textMuted),
                                        const SizedBox(width: 6),
                                        Text(
                                          confirmedAt != null
                                              ? dateFmt.format(confirmedAt)
                                              : 'Awaiting confirmation',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: confirmedAt != null
                                                ? AC.textMuted
                                                : AC.textMuted,
                                            fontStyle: confirmedAt != null
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _Hdr extends StatelessWidget {
  final String t;
  const _Hdr(this.t);
  @override
  Widget build(BuildContext context) {
    return Text(t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AC.textMuted,
          letterSpacing: 0.8,
        ));
  }
}

class _OrderBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _OrderBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AC.primary : AC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AC.primary : AC.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AC.textSecond,
          ),
        ),
      ),
    );
  }
}
