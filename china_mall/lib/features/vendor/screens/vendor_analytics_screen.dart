import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class VendorAnalyticsScreen extends StatefulWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  State<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends State<VendorAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _checkingSubscription = true;
  bool _hasSubscription = false;
  bool _loading = false;

  late TabController _tabCtrl;

  String _period = 'monthly';
  Map? _analytics;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _checkSub();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSub() async {
    setState(() => _checkingSubscription = true);
    final active = await ApiService.checkAnalyticsSubscription();
    if (!mounted) return;
    setState(() {
      _hasSubscription = active;
      _checkingSubscription = false;
    });
    if (active) _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    final res = await ApiService.getVendorAnalytics(period: _period);
    if (!mounted) return;
    setState(() {
      _analytics = res.isSuccess ? res.data as Map : null;
      _loading = false;
    });
  }

  Future<void> _subscribe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Subscribe to Analytics', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800)),
        content: const Text('R250/month gives you full access to sales history, product performance, and revenue insights.\n\nProceed?',
            style: TextStyle(fontFamily: 'Satoshi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Subscribe — R250', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final res = await ApiService.subscribeToAnalytics();
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Subscribed! Analytics now unlocked for 30 days.'),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        ));
        setState(() => _hasSubscription = true);
        _loadAnalytics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.errorMessage),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Analytics'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
        bottom: _hasSubscription
            ? TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Sales History'),
                  Tab(text: 'Product Performance'),
                ],
              )
            : null,
      ),
      body: _checkingSubscription
          ? const Center(child: CircularProgressIndicator())
          : !_hasSubscription
              ? _SubscriptionGate(onSubscribe: _subscribe)
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Period filter
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Text('Period:',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(width: 12),
                              ...[
                                ('daily', 'Today'),
                                ('weekly', 'This Week'),
                                ('monthly', 'This Month'),
                              ].map((entry) {
                                final isSelected = _period == entry.$1;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _period = entry.$1);
                                      _loadAnalytics();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        entry.$2,
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        // Summary row
                        if (_analytics != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    label: 'Revenue',
                                    value:
                                        'R${(_analytics!['total_revenue'] as num? ?? 0).toStringAsFixed(2)}',
                                    icon: Icons.payments,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SummaryCard(
                                    label: 'Orders',
                                    value:
                                        '${_analytics!['total_orders'] ?? 0}',
                                    icon: CupertinoIcons.cube_box,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabCtrl,
                            children: [
                              _SalesHistoryTab(
                                sales: (_analytics?['sales'] as List?) ?? [],
                                onRefresh: _loadAnalytics,
                              ),
                              _ProductPerformanceTab(
                                products:
                                    (_analytics?['products'] as List?) ?? [],
                                onRefresh: _loadAnalytics,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ── Subscription Gate ─────────────────────────────────────────────────────────

class _SubscriptionGate extends StatelessWidget {
  final VoidCallback onSubscribe;
  const _SubscriptionGate({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Store Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Premium feature — R250/month',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Feature list
          ...[
            (Icons.history, 'Sales history with dates, quantities, and revenue'),
            (Icons.emoji_events, 'Best-selling products ranked by revenue'),
            (Icons.show_chart, 'Revenue timeline filtered by day, week, or month'),
            (Icons.trending_up, 'Conversion insights to optimise your listings'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$1,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(item.$2,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onSubscribe,
              child: const Text(
                'Subscribe — R250/month',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '30-day subscription. Cancel anytime.',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Sales History Tab ─────────────────────────────────────────────────────────

class _SalesHistoryTab extends StatelessWidget {
  final List sales;
  final Future<void> Function() onRefresh;
  const _SalesHistoryTab({required this.sales, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.chart_bar,
        title: 'No sales yet',
        subtitle: 'Sales data will appear once you start receiving orders.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        itemBuilder: (_, i) {
          final s = sales[i];
          final revenue = (s['revenue'] as num? ?? 0).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today,
                      size: 18, color: Colors.green),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    s['period']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'R${revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Product Performance Tab ───────────────────────────────────────────────────

class _ProductPerformanceTab extends StatelessWidget {
  final List products;
  final Future<void> Function() onRefresh;
  const _ProductPerformanceTab(
      {required this.products, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.chart_bar_alt_fill,
        title: 'No data yet',
        subtitle: 'Product performance will show after your first sales.',
      );
    }

    final maxRevenue = products.isEmpty
        ? 1.0
        : (products.first['revenue'] as num? ?? 1).toDouble();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          final revenue = (p['revenue'] as num? ?? 0).toDouble();
          final units = (p['units_sold'] as num? ?? 0).toInt();
          final barWidth = maxRevenue > 0 ? revenue / maxRevenue : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? Colors.amber.withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: i == 0
                                ? Colors.amber.shade700
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['name']?.toString() ?? '',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'R${revenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Revenue bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barWidth,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      i == 0 ? Colors.amber.shade600 : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$units unit${units != 1 ? 's' : ''} sold',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
