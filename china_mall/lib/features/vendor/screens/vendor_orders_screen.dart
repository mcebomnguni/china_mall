import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  // All loaded orders — filtered in-memory per tab
  List _allOrders = [];
  bool _loading = true;

  late TabController _tabCtrl;

  // Tab definitions: (label, status filter or null for all)
  static const _tabs = [
    _Tab('All', null),
    _Tab('New', 'payment_confirmed'),
    _Tab('Confirmed', 'processing'),
    _Tab('Ready', 'awaiting_pickup'),
    _Tab('Done', 'delivered'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getVendorOrdersSupabase();
    if (!mounted) return;
    setState(() {
      _allOrders = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }

  List get _filteredOrders {
    final statusFilter = _tabs[_tabCtrl.index].status;
    if (statusFilter == null) return _allOrders;
    return _allOrders
        .where((o) => o['status'] == statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Store Orders (${_allOrders.length})'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: _tabs
              .map((t) {
                final count = t.status == null
                    ? _allOrders.length
                    : _allOrders
                        .where((o) => o['status'] == t.status)
                        .length;
                return Tab(
                    text: count > 0 ? '${t.label} ($count)' : t.label);
              })
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: List.generate(
                _tabs.length,
                (_) => _OrderList(
                  orders: _filteredOrders,
                  onRefresh: _load,
                  onTap: (id) => context.go('/vendor/orders/$id'),
                ),
              ),
            ),
    );
  }
}

// ── Tab definition ────────────────────────────────────────────────────────────
class _Tab {
  final String label;
  final String? status;
  const _Tab(this.label, this.status);
}

// ── Order List ────────────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List orders;
  final Future<void> Function() onRefresh;
  final void Function(int id) onTap;
  const _OrderList(
      {required this.orders,
      required this.onRefresh,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.cube_box,
        title: 'No orders here',
        subtitle: 'Orders will appear here as customers buy.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final order = orders[i];
          return _OrderCard(
            order: order,
            onTap: () => onTap(order['id'] as int),
          );
        },
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? '';
    final isNew = status == 'payment_confirmed';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: isNew ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isNew)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    order['order_number'] ?? '#${order['id']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(status: status),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right,
                    size: 14, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.person_fill,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order['buyer_name'] ?? 'Customer',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PriceText(
                    price: ((order['total_amount'] ?? 0) as num)
                        .toDouble()),
                Text(
                  '${order['item_count'] ?? 0} item(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (order['created_at'] != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(order['created_at']),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    final dt = raw is String ? DateTime.tryParse(raw) : null;
    if (dt == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
