import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Period
  int _days = 30;

  // Data
  List<Map<String, dynamic>> _topProducts     = [];
  List<Map<String, dynamic>> _timeline        = [];
  List<Map<String, dynamic>> _storePerf       = [];
  List<Map<String, dynamic>> _courierPerf     = [];
  List<Map<String, dynamic>> _categoryStats   = [];

  bool _loading = true;
  String? _error;

  // Search
  String _productSearch = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        AdminApi.getTopProducts(days: _days, limit: 100),
        AdminApi.getRevenueTimeline(period: _days <= 14 ? 'day' : 'day', days: _days),
        AdminApi.getStorePerformance(days: _days),
        AdminApi.getCourierPerformance(days: _days),
        AdminApi.getCategoryStats(days: _days),
      ]);
      setState(() {
        _topProducts   = results[0] as List<Map<String, dynamic>>;
        _timeline      = results[1] as List<Map<String, dynamic>>;
        _storePerf     = results[2] as List<Map<String, dynamic>>;
        _courierPerf   = results[3] as List<Map<String, dynamic>>;
        _categoryStats = results[4] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_productSearch.isEmpty) return _topProducts;
    final q = _productSearch.toLowerCase();
    return _topProducts.where((p) {
      return (p['product_name'] ?? '').toString().toLowerCase().contains(q) ||
             (p['store_name']   ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Analytics',
                  subtitle: 'Platform performance insights',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...[7, 30, 90].map((d) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InkWell(
                          onTap: () { setState(() => _days = d); _loadAll(); },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _days == d ? AC.primary : AC.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _days == d ? AC.primary : AC.border),
                            ),
                            child: Text(
                              d == 7 ? '7d' : d == 30 ? '30d' : '90d',
                              style: TextStyle(
                                color: _days == d ? Colors.white : AC.textSecond,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                        onPressed: _loadAll,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: AC.primary,
                  unselectedLabelColor: AC.textMuted,
                  indicatorColor: AC.primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Revenue'),
                    Tab(text: 'Top Products'),
                    Tab(text: 'Store Performance'),
                    Tab(text: 'Couriers'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.border),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AC.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AC.error)))
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _RevenueTab(timeline: _timeline, categories: _categoryStats, days: _days),
                          _TopProductsTab(
                            products: _filteredProducts,
                            search: _productSearch,
                            onSearch: (v) => setState(() => _productSearch = v),
                          ),
                          _StorePerformanceTab(stores: _storePerf),
                          _CourierTab(couriers: _courierPerf),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue tab ───────────────────────────────────────────────────────────────

class _RevenueTab extends StatelessWidget {
  final List<Map<String, dynamic>> timeline;
  final List<Map<String, dynamic>> categories;
  final int days;
  const _RevenueTab({required this.timeline, required this.categories, required this.days});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = timeline.fold<double>(
        0, (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0));
    final totalOrders = timeline.fold<int>(
        0, (s, r) => s + ((r['order_count'] as num?)?.toInt() ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              _SummaryTile(
                label: 'Total Revenue (${days}d)',
                value: 'R ${NumberFormat('#,##0.00').format(totalRevenue)}',
                icon: Icons.payments_rounded,
                color: AC.success,
              ),
              const SizedBox(width: 16),
              _SummaryTile(
                label: 'Total Orders (${days}d)',
                value: '$totalOrders',
                icon: Icons.receipt_long_rounded,
                color: AC.primary,
              ),
              const SizedBox(width: 16),
              _SummaryTile(
                label: 'Avg Order Value',
                value: totalOrders == 0
                    ? '—'
                    : 'R ${(totalRevenue / totalOrders).toStringAsFixed(0)}',
                icon: Icons.shopping_bag_rounded,
                color: AC.chart3,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue chart
          SectionCard(
            title: 'Daily Revenue',
            child: _RevenueChart(timeline: timeline),
          ),
          const SizedBox(height: 24),

          // Category breakdown
          if (categories.isNotEmpty)
            SectionCard(
              title: 'Revenue by Category',
              child: _CategoryChart(categories: categories),
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryTile({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AC.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AC.textSecond)),
          ],
        ),
      ),
    );
  }
}

// ── Revenue bar chart (manual, no extra package) ──────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> timeline;
  const _RevenueChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No revenue data for this period',
            style: TextStyle(color: AC.textMuted))),
      );
    }

    final values = timeline
        .map((r) => (r['revenue'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxVal = values.reduce(max);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: timeline.asMap().entries.map((e) {
              final i   = e.key;
              final row = e.value;
              final rev = (row['revenue'] as num?)?.toDouble() ?? 0;
              final h   = maxVal == 0 ? 0.0 : (rev / maxVal);
              final date = row['bucket'] != null
                  ? DateFormat('d/M').format(DateTime.parse(row['bucket']))
                  : '';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message: 'R ${rev.toStringAsFixed(0)}\n$date',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: max(4, 180 * h),
                          decoration: BoxDecoration(
                            color: AC.primary.withOpacity(0.75 + 0.25 * h),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        if (timeline.length <= 14) ...[
                          const SizedBox(height: 4),
                          Text(date,
                              style: const TextStyle(
                                  fontSize: 9, color: AC.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('R 0',
                style: const TextStyle(fontSize: 10, color: AC.textMuted)),
            Text('R ${NumberFormat.compact().format(maxVal)}',
                style: const TextStyle(fontSize: 10, color: AC.textMuted)),
          ],
        ),
      ],
    );
  }
}

// ── Category bar chart ────────────────────────────────────────────────────────

class _CategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _CategoryChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    final maxRev = categories
        .map((c) => (c['revenue'] as num?)?.toDouble() ?? 0)
        .fold(0.0, max);

    return Column(
      children: categories.take(8).map((c) {
        final label = c['category_label'] as String? ?? '—';
        final rev   = (c['revenue'] as num?)?.toDouble() ?? 0;
        final sold  = c['total_sold'] as int? ?? 0;
        final frac  = maxRev == 0 ? 0.0 : rev / maxRev;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(label,
                    style: const TextStyle(fontSize: 12, color: AC.textSecond),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    backgroundColor: AC.bg,
                    valueColor: const AlwaysStoppedAnimation(AC.primary),
                    minHeight: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  'R ${NumberFormat.compact().format(rev)} · $sold sold',
                  style: const TextStyle(fontSize: 11, color: AC.textSecond),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Top 100 products tab ──────────────────────────────────────────────────────

class _TopProductsTab extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String search;
  final ValueChanged<String> onSearch;
  const _TopProductsTab({
    required this.products,
    required this.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Row(
            children: [
              Text('${products.length} products',
                  style: const TextStyle(color: AC.textMuted, fontSize: 12)),
              const Spacer(),
              SizedBox(
                width: 260,
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search product or store…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    fillColor: AC.surface, filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AC.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AC.border)),
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
          decoration: BoxDecoration(
            color: AC.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: const Border(
              top: BorderSide(color: AC.border),
              left: BorderSide(color: AC.border),
              right: BorderSide(color: AC.border),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 36, child: Text('#',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 3, child: Text('PRODUCT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 2, child: Text('STORE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 1, child: Text('CATEGORY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 1, child: Text('SOLD',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 1, child: Text('REVENUE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
              Expanded(flex: 1, child: Text('PRICE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted))),
            ],
          ),
        ),

        // Table body
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AC.border),
            ),
            child: products.isEmpty
                ? const Center(child: Text('No data',
                    style: TextStyle(color: AC.textMuted)))
                : ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      final rev = (p['total_revenue'] as num?)?.toDouble() ?? 0;
                      final sold = (p['total_sold'] as num?)?.toInt() ?? 0;
                      final price = (p['price'] as num?)?.toDouble() ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: i < 3 ? AC.warning : AC.textMuted,
                                  )),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(p['product_name'] ?? '—',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(p['store_name'] ?? '—',
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(p['category_label'] ?? '—',
                                  style: const TextStyle(fontSize: 12, color: AC.textMuted)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('$sold',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'R ${NumberFormat('#,##0').format(rev)}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: AC.success),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('R ${price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Store performance tab ─────────────────────────────────────────────────────

class _StorePerformanceTab extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  const _StorePerformanceTab({required this.stores});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: SectionCard(
        title: 'Store Performance',
        child: stores.isEmpty
            ? const Center(child: Text('No data', style: TextStyle(color: AC.textMuted)))
            : Column(
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(flex: 3, child: _Hdr('STORE')),
                      Expanded(flex: 2, child: _Hdr('OWNER')),
                      Expanded(flex: 1, child: _Hdr('PRODUCTS')),
                      Expanded(flex: 1, child: _Hdr('ORDERS')),
                      Expanded(flex: 2, child: _Hdr('REVENUE')),
                      Expanded(flex: 1, child: _Hdr('STATUS')),
                    ]),
                  ),
                  const Divider(color: AC.border),
                  ...stores.asMap().entries.map((e) {
                    final s   = e.value;
                    final rev = (s['revenue'] as num?)?.toDouble() ?? 0;
                    final active = s['is_active'] as bool? ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AC.primary.withOpacity(0.1),
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          fontSize: 11, color: AC.primary,
                                          fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(s['store_name'] ?? '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(s['owner_name'] ?? '—',
                                style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${s['product_count'] ?? 0}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${s['order_count'] ?? 0}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'R ${NumberFormat('#,##0').format(rev)}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AC.success),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: StatusBadge(active ? 'approved' : 'pending'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String t;
  const _Hdr(this.t);
  @override
  Widget build(BuildContext context) {
    return Text(t,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AC.textMuted, letterSpacing: 0.8));
  }
}

// ── Courier tab ───────────────────────────────────────────────────────────────

class _CourierTab extends StatelessWidget {
  final List<Map<String, dynamic>> couriers;
  const _CourierTab({required this.couriers});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: SectionCard(
        title: 'Courier Performance',
        child: couriers.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No courier data for this period',
                      style: TextStyle(color: AC.textMuted)),
                ))
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(flex: 3, child: _Hdr('COURIER')),
                      Expanded(flex: 2, child: _Hdr('EMAIL')),
                      Expanded(flex: 1, child: _Hdr('TOTAL')),
                      Expanded(flex: 1, child: _Hdr('COMPLETED')),
                      Expanded(flex: 1, child: _Hdr('CANCELLED')),
                      Expanded(flex: 2, child: _Hdr('ON-TIME RATE')),
                    ]),
                  ),
                  const Divider(color: AC.border),
                  ...couriers.map((c) {
                    final rate = (c['on_time_rate_pct'] as num?)?.toDouble() ?? 0;
                    final rateColor = rate >= 80
                        ? AC.success
                        : rate >= 50
                            ? AC.warning
                            : AC.error;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(c['courier_name'] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(c['courier_email'] ?? '—',
                                style: const TextStyle(
                                    fontSize: 12, color: AC.textSecond)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${c['total_deliveries'] ?? 0}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${c['completed'] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 13, color: AC.success,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${c['cancelled_count'] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 13, color: AC.error)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: rate / 100,
                                      backgroundColor: AC.bg,
                                      valueColor: AlwaysStoppedAnimation(rateColor),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${rate.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: rateColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
