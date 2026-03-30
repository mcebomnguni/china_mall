import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/admin_service.dart';
 
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
 
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
 
class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  // Overview & analytics
  Map<String, dynamic>? _overview;
  List<dynamic> _topStores = [];
  List<dynamic> _topProducts = [];
 
  // Pending approvals (legacy API)
  Map? _dashboard;
  List _pendingStores = [];
  List _pendingProducts = [];
 
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminService.getPlatformOverview(),
        AdminService.getTopStores(),
        AdminService.getTopProducts(),
        ApiService.getStaffDashboard(),
        ApiService.getPendingStores(),
        ApiService.getPendingProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, dynamic>?;
        _topStores = results[1] as List<dynamic>? ?? [];
        _topProducts = results[2] as List<dynamic>? ?? [];
        final dashResult = results[3] as dynamic;
        _dashboard = dashResult?.isSuccess == true ? dashResult.data : null;
        final storesResult = results[4] as dynamic;
        _pendingStores =
            storesResult?.isSuccess == true ? (storesResult.data as List? ?? []) : [];
        final productsResult = results[5] as dynamic;
        _pendingProducts =
            productsResult?.isSuccess == true ? (productsResult.data as List? ?? []) : [];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dashboard.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
 
  // ── Approve / reject with reason dialog ───────────────────────────────────
 
  Future<void> _approveStore(int id, String action) async {
    if (action == 'reject') {
      await _showRejectReasonDialog(
          (reason) => ApiService.approveStore(id, action));
    } else {
      await ApiService.approveStore(id, action);
    }
    _loadAll();
  }
 
  Future<void> _approveProduct(int id, String action) async {
    if (action == 'reject') {
      await _showRejectReasonDialog(
          (reason) => ApiService.approveProduct(id, action));
    } else {
      await ApiService.approveProduct(id, action);
    }
    _loadAll();
  }
 
  Future<void> _showRejectReasonDialog(
      Future<void> Function(String reason) onConfirm) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Reject — Enter Reason',
          style: TextStyle(
              fontFamily: 'Satoshi', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Why is this being rejected?',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm(ctrl.text.trim());
            },
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Super Admin',
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
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Stores (${_pendingStores.length})'),
            Tab(text: 'Products (${_pendingProducts.length})'),
            const Tab(text: 'Top Stores'),
            const Tab(text: 'Top Products'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Overview ──────────────────────────────────────────────
                _OverviewTab(
                  dashboard: _dashboard,
                  overview: _overview,
                  onRefresh: _loadAll,
                ),
 
                // ── Pending Stores ────────────────────────────────────────
                _pendingStores.isEmpty
                    ? EmptyState(
                        icon: CupertinoIcons.house_fill,
                        title: 'No pending stores',
                        subtitle: 'All store applications are processed.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingStores.length,
                        itemBuilder: (_, i) {
                          final store = _pendingStores[i];
                          return _PendingStoreCard(
                            store: store,
                            onApprove: () =>
                                _approveStore(store['id'], 'approve'),
                            onReject: () =>
                                _approveStore(store['id'], 'reject'),
                          );
                        },
                      ),
 
                // ── Pending Products ──────────────────────────────────────
                _pendingProducts.isEmpty
                    ? EmptyState(
                        icon: CupertinoIcons.bag,
                        title: 'No pending products',
                        subtitle: 'All products are reviewed.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingProducts.length,
                        itemBuilder: (_, i) {
                          final product = _pendingProducts[i];
                          return _PendingProductCard(
                            product: product,
                            onApprove: () =>
                                _approveProduct(product['id'], 'approve'),
                            onReject: () =>
                                _approveProduct(product['id'], 'reject'),
                          );
                        },
                      ),
 
                // ── Top Stores ────────────────────────────────────────────
                _TopStoresTab(stores: _topStores),
 
                // ── Top Products ──────────────────────────────────────────
                _TopProductsTab(products: _topProducts),
              ],
            ),
    );
  }
}
 
// ── Overview Tab ──────────────────────────────────────────────────────────────
 
class _OverviewTab extends StatelessWidget {
  final Map? dashboard;
  final Map<String, dynamic>? overview;
  final Future<void> Function() onRefresh;
 
  const _OverviewTab({
    required this.dashboard,
    required this.overview,
    required this.onRefresh,
  });
 
  @override
  Widget build(BuildContext context) {
    final o = overview;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legacy stat cards
            if (dashboard != null) ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _AdminStat(
                    label: 'Total Users',
                    value: '${dashboard!['total_users'] ?? 0}',
                    icon: CupertinoIcons.person_2_fill,
                    color: AppColors.info,
                  ),
                  _AdminStat(
                    label: 'Total Revenue',
                    value:
                        'R ${(dashboard!['total_revenue'] ?? 0).toStringAsFixed(0)}',
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    color: AppColors.success,
                  ),
                  _AdminStat(
                    label: 'Active Stores',
                    value: '${dashboard!['active_stores'] ?? 0}',
                    icon: CupertinoIcons.house_fill,
                    color: AppColors.accent,
                  ),
                  _AdminStat(
                    label: 'Total Orders',
                    value: '${dashboard!['total_orders'] ?? 0}',
                    icon: CupertinoIcons.cube_box_fill,
                    color: AppColors.primary,
                  ),
                  _AdminStat(
                    label: 'Pending Stores',
                    value: '${dashboard!['pending_stores'] ?? 0}',
                    icon: CupertinoIcons.clock_fill,
                    color: AppColors.warning,
                  ),
                  _AdminStat(
                    label: 'Disputed Orders',
                    value: '${dashboard!['disputed_orders'] ?? 0}',
                    icon: CupertinoIcons.exclamationmark_circle_fill,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'View All Orders',
                outline: true,
                icon: CupertinoIcons.list_bullet,
                onTap: () => context.go('/orders'),
              ),
            ],
 
            // Extended analytics from AdminService
            if (o != null) ...[
              const SizedBox(height: 24),
              _SectionHeader('Revenue (30d)'),
              _MetricGrid([
                _Metric(
                    'All Time',
                    'R ${o['revenue']?['total_all_time'] ?? 0}',
                    Icons.payments,
                    Colors.green),
                _Metric(
                    'Last 30 Days',
                    'R ${o['revenue']?['last_30_days'] ?? 0}',
                    Icons.trending_up,
                    Colors.teal),
              ]),
              const SizedBox(height: 20),
              _SectionHeader('Users'),
              _MetricGrid([
                _Metric('Total', '${o['users']?['total'] ?? 0}',
                    Icons.people, Colors.blue),
                _Metric(
                    'New (30d)',
                    '${o['users']?['new_last_30_days'] ?? 0}',
                    Icons.person_add,
                    Colors.indigo),
                _Metric(
                    'Customers',
                    '${o['users']?['by_role']?['customer'] ?? 0}',
                    Icons.shopping_bag,
                    Colors.purple),
                _Metric(
                    'Drivers',
                    '${o['users']?['by_role']?['courier'] ?? 0}',
                    Icons.directions_car,
                    Colors.orange),
              ]),
              const SizedBox(height: 20),
              _SectionHeader('Orders & Deliveries'),
              _MetricGrid([
                _Metric('Total Orders', '${o['orders']?['total'] ?? 0}',
                    Icons.receipt, Colors.blue),
                _Metric(
                    'Orders (30d)',
                    '${o['orders']?['last_30_days'] ?? 0}',
                    Icons.receipt_long,
                    Colors.teal),
                _Metric(
                    'Active Deliveries',
                    '${o['deliveries']?['active'] ?? 0}',
                    Icons.local_shipping,
                    Colors.orange),
                _Metric(
                    'Completed',
                    '${o['deliveries']?['completed'] ?? 0}',
                    Icons.done_all,
                    Colors.green),
              ]),
              const SizedBox(height: 20),
              _SectionHeader('Products'),
              _MetricGrid([
                _Metric('Total', '${o['products']?['total'] ?? 0}',
                    Icons.inventory, Colors.blue),
                _Metric(
                    'Pending Review',
                    '${o['products']?['pending_review'] ?? 0}',
                    Icons.pending,
                    Colors.orange),
                _Metric('Suspended', '${o['products']?['suspended'] ?? 0}',
                    Icons.block, Colors.red),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
 
// ── Shared stat card (legacy style) ──────────────────────────────────────────
 
class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
 
  const _AdminStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── Analytics helpers ─────────────────────────────────────────────────────────
 
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
 
class _Metric {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Metric(this.label, this.value, this.icon, this.color);
}
 
class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricGrid(this.metrics);
 
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: metrics.map((m) => _MetricCard(m)).toList(),
    );
  }
}
 
class _MetricCard extends StatelessWidget {
  final _Metric m;
  const _MetricCard(this.m);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: m.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(m.icon, color: m.color, size: 22),
          Text(m.value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: m.color)),
          Text(m.label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
 
// ── Pending Store Card ────────────────────────────────────────────────────────
 
class _PendingStoreCard extends StatelessWidget {
  final Map store;
  final VoidCallback onApprove;
  final VoidCallback onReject;
 
  const _PendingStoreCard({
    required this.store,
    required this.onApprove,
    required this.onReject,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppNetworkImage(
                  url: store['logo'], width: 48, height: 48, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(store['owner_name'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  onTap: onApprove,
                  icon: CupertinoIcons.checkmark,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  outline: true,
                  color: AppColors.error,
                  onTap: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── Pending Product Card ──────────────────────────────────────────────────────
 
class _PendingProductCard extends StatelessWidget {
  final Map product;
  final VoidCallback onApprove;
  final VoidCallback onReject;
 
  const _PendingProductCard({
    required this.product,
    required this.onApprove,
    required this.onReject,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppNetworkImage(
                  url: product['image'], width: 64, height: 64, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? '',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        'by ${product['store']?['name'] ?? 'Unknown Store'}',
                        style: Theme.of(context).textTheme.bodySmall),
                    PriceText(price: (product['price'] ?? 0).toDouble()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  onTap: onApprove,
                  icon: CupertinoIcons.checkmark,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  outline: true,
                  color: AppColors.error,
                  onTap: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── Top Stores Tab ────────────────────────────────────────────────────────────
 
class _TopStoresTab extends StatelessWidget {
  final List<dynamic> stores;
  const _TopStoresTab({required this.stores});
 
  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const Center(child: Text('No data'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stores.length,
      itemBuilder: (_, i) {
        final s = stores[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text('${i + 1}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          title: Text(s['name'] ?? ''),
          subtitle: Text(
              '${s['total_sales_count']} sales · ⭐${s['average_rating']}'),
          trailing: Text('R${s['total_earnings']}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        );
      },
    );
  }
}
 
// ── Top Products Tab ──────────────────────────────────────────────────────────
 
class _TopProductsTab extends StatelessWidget {
  final List<dynamic> products;
  const _TopProductsTab({required this.products});
 
  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const Center(child: Text('No data'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            child: Text('${i + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
          title: Text(p['name'] ?? ''),
          subtitle: Text('${p['store__name']} · ⭐${p['average_rating']}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${p['total_sold']} sold',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('R${p['price']}',
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
        );
      },
    );
  }
}