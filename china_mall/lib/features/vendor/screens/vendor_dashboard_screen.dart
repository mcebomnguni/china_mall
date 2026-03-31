import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/store_product_service.dart';
 
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
 
  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}
 
class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  // From ApiService
  Map? _store;
 
  // From StoreProductService
  Map<String, dynamic>? _dashboard;
  List<dynamic> _earnings = [];
  List<dynamic> _disputes = [];
 
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getMyStore(),
        StoreProductService.getOwnerDashboard(),
        StoreProductService.getOwnerEarnings(),
        StoreProductService.getOwnerDisputes(),
      ]);
      if (!mounted) return;
      final storeRes = results[0] as ApiResponse?;
      setState(() {
        _store = storeRes?.isSuccess == true ? storeRes!.data : null;
        _dashboard = results[1] as Map<String, dynamic>?;
        _earnings = results[2] as List<dynamic>? ?? [];
        _disputes = results[3] as List<dynamic>? ?? [];
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
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Store Dashboard',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Earnings'),
            Tab(text: 'Disputes'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  store: _store,
                  dashboard: _dashboard,
                  onAddProduct: () => context.push('/vendor/products/add'),
                  onViewOrders: () => context.go('/vendor/orders'),
                  onMyAds: () => context.go('/vendor/ads'),
                  onAnalytics: () => context.go('/vendor/analytics'),
                  onRefresh: _loadData,
                ),
                _EarningsTab(earnings: _earnings),
                _DisputesTab(disputes: _disputes),
              ],
            ),
    );
  }
}
 
// ── Overview Tab ──────────────────────────────────────────────────────────────
 
class _OverviewTab extends StatelessWidget {
  final Map? store;
  final Map<String, dynamic>? dashboard;
  final VoidCallback onAddProduct;
  final VoidCallback onViewOrders;
  final VoidCallback onMyAds;
  final VoidCallback onAnalytics;
  final Future<void> Function() onRefresh;

  const _OverviewTab({
    required this.store,
    required this.dashboard,
    required this.onAddProduct,
    required this.onViewOrders,
    required this.onMyAds,
    required this.onAnalytics,
    required this.onRefresh,
  });
 
  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store banner
            if (store != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: store!['logo'],
                      width: 56,
                      height: 56,
                      radius: 14,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store!['name'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            store!['status'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
 
            if (d != null) ...[
              const SizedBox(height: 16),
 
              // Status banner
              _StatusBanner(
                status: d['status'] ?? store?['status'] ?? 'pending',
                reason: d['rejection_reason'] ?? d['suspension_reason'],
              ),
 
              const SizedBox(height: 20),
 
              Text('Overview',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
 
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard('Total Earnings',
                      'R ${d['total_earnings'] ?? d['total_revenue'] ?? 0}',
                      Icons.payments, Colors.green),
                  _StatCard('Total Sales',
                      '${d['total_sales_count'] ?? d['total_orders'] ?? 0}',
                      Icons.shopping_bag, Colors.blue),
                  _StatCard('Rating', '${d['average_rating'] ?? 0} ⭐',
                      Icons.star, Colors.amber),
                  _StatCard('Reviews', '${d['rating_count'] ?? 0}',
                      Icons.reviews, Colors.purple),
                  _StatCard(
                      'Pending Products',
                      '${d['pending_products'] ?? d['pending_orders'] ?? 0}',
                      Icons.pending, Colors.orange),
                  _StatCard(
                      'Approved Products',
                      '${d['approved_products'] ?? d['total_products'] ?? 0}',
                      Icons.check_circle, Colors.green),
                  _StatCard('Suspended Products',
                      '${d['suspended_products'] ?? 0}',
                      Icons.block, Colors.red),
                ],
              ),
            ],
 
            const SizedBox(height: 24),
 
            // Quick actions
            Text('Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Product',
                    icon: CupertinoIcons.plus,
                    onTap: onAddProduct,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Orders',
                    outline: true,
                    icon: CupertinoIcons.list_bullet,
                    onTap: onViewOrders,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'My Ads',
                    outline: true,
                    icon: CupertinoIcons.rocket,
                    onTap: onMyAds,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Analytics',
                    outline: true,
                    icon: Icons.bar_chart_rounded,
                    onTap: onAnalytics,
                  ),
                ),
              ],
            ),
 
            // Recent orders
            if (d?['recent_orders'] != null &&
                (d!['recent_orders'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recent Orders',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ...(d['recent_orders'] as List).take(5).map(
                    (order) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['order_number'] ??
                                      '#${order['id']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                Text(
                                  order['buyer_name'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusChip(status: order['status'] ?? ''),
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
 
// ── Status Banner ─────────────────────────────────────────────────────────────
 
class _StatusBanner extends StatelessWidget {
  final String status;
  final String? reason;
  const _StatusBanner({required this.status, this.reason});
 
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
 
    switch (status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Store Active';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_top;
        label = 'Pending Review';
        break;
      case 'suspended':
        color = Colors.red;
        icon = Icons.block;
        label = 'Store Suspended';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        label = status;
    }
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
                        fontWeight: FontWeight.bold, color: color)),
                if (reason != null && reason!.isNotEmpty)
                  Text(reason!,
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Stat Card ─────────────────────────────────────────────────────────────────
 
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
 
  const _StatCard(this.label, this.value, this.icon, this.color);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
 
// ── Earnings Tab ──────────────────────────────────────────────────────────────
 
class _EarningsTab extends StatelessWidget {
  final List<dynamic> earnings;
  const _EarningsTab({required this.earnings});
 
  @override
  Widget build(BuildContext context) {
    if (earnings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.money_dollar_circle,
                size: 48, color: AppColors.textTertiary),
            SizedBox(height: 14),
            Text(
              'No earnings records yet.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: earnings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = earnings[i];
        return Card(
          child: ListTile(
            title: Text(
              '${e['year']}/${e['month'].toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gross: R${e['gross_revenue']}'),
                Text('Platform fee: R${e['platform_fee']}'),
                Text('Refunds: R${e['refunds']}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R${e['net_payout']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16),
                ),
                _PayoutBadge(status: e['payout_status'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }
}
 
class _PayoutBadge extends StatelessWidget {
  final String status;
  const _PayoutBadge({required this.status});
 
  @override
  Widget build(BuildContext context) {
    final color = status == 'paid'
        ? Colors.green
        : status == 'held'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
 
// ── Disputes Tab ──────────────────────────────────────────────────────────────
 
class _DisputesTab extends StatelessWidget {
  final List<dynamic> disputes;
  const _DisputesTab({required this.disputes});
 
  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_bubble,
                size: 48, color: AppColors.textTertiary),
            SizedBox(height: 14),
            Text(
              'No disputes.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: disputes.length,
      itemBuilder: (_, i) {
        final d = disputes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text('Dispute #${d['id']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text('R${d['amount_disputed']} — ${d['status']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason: ${d['reason']}'),
                    if (d['admin_recommendation'] != null)
                      Text(
                        'Admin recommendation: ${d['admin_recommendation']}',
                        style:
                            const TextStyle(color: Colors.blue),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}