import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _statuses = ['all', 'pending', 'processing', 'in_transit', 'delivered', 'cancelled'];
  final _labels   = ['All', 'Pending', 'Processing', 'In Transit', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('My Orders', style: TextStyle(fontFamily: 'Satoshi', fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/orders/returns'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: const Text('Returns', style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Status tabs ───────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: _statuses.length,
                itemBuilder: (_, i) => _TabChip(
                  label: _labels[i],
                  selected: _tabs.index == i,
                  onTap: () => setState(() => _tabs.animateTo(i)),
                ),
              ),
            ),

            // ── Orders list ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: _statuses.map((s) => _OrdersList(status: s == 'all' ? null : s)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.black : AppColors.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _OrdersList extends StatefulWidget {
  final String? status;
  const _OrdersList({this.status});

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getOrders(status: widget.status);
    if (!mounted) return;
    final items = res.isSuccess ? ((res.data is Map ? res.data['results'] : res.data) as List? ?? []) : [];
    setState(() { _orders = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return ListView.builder(padding: const EdgeInsets.all(20), itemCount: 4, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ShimmerBox(width: double.infinity, height: 90, radius: 20)));
    if (_orders.isEmpty) return const EmptyState(icon: CupertinoIcons.cube_box, title: 'No Orders', subtitle: 'Your orders will appear here.');
    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final id       = order['order_number'] ?? order['id'] ?? '';
    final status   = order['status'] ?? 'pending';
    final total    = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final items    = (order['items'] as List?)?.length ?? 0;
    final date     = order['created_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(order['created_at']) ?? DateTime.now())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OsCard(
        onTap: () => context.go('/orders/${order['id']}'),
        child: Row(
          children: [
            // Order icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
              child: const Icon(CupertinoIcons.cube_box_fill, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('ORD-$id', style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w900, fontSize: 13)),
                      const Spacer(),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('$items item${items != 1 ? 's' : ''} · $date',
                    style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(height: 3),
                  Text('R ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 13, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
