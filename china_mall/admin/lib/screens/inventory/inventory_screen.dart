import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';
import '../_widgets/stat_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Data
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _overview = [];
  List<Map<String, dynamic>> _lowStock = [];

  bool _loading = true;
  String? _error;

  // Search (Low Stock tab)
  String _lowStockSearch = '';

  // Track which products have been notified
  final Set<int> _notifiedIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApi.getInventoryStats(),
        AdminApi.getInventoryOverview(),
        AdminApi.getLowStockItems(threshold: 3),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _overview = results[1] as List<Map<String, dynamic>>;
        _lowStock = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLowStock {
    if (_lowStockSearch.isEmpty) return _lowStock;
    final q = _lowStockSearch.toLowerCase();
    return _lowStock.where((p) {
      return (p['product_name'] ?? '').toString().toLowerCase().contains(q) ||
          (p['store_name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _handleNotify(int productId) async {
    try {
      await AdminApi.notifyRestock(productId);
      if (!mounted) return;
      setState(() => _notifiedIds.add(productId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restock notification sent successfully'),
          backgroundColor: AC.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to notify: $e'),
          backgroundColor: AC.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  title: 'Inventory & Stock',
                  subtitle: 'Monitor stock levels across all stores',
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: AC.textSecond),
                    onPressed: _loadAll,
                    tooltip: 'Refresh',
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: AC.primary,
                  unselectedLabelColor: AC.textMuted,
                  indicatorColor: AC.primary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Low Stock Alerts'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.border),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AC.primary))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AC.error)))
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _OverviewTab(
                            stats: _stats,
                            overview: _overview,
                          ),
                          _LowStockTab(
                            stats: _stats,
                            items: _filteredLowStock,
                            search: _lowStockSearch,
                            onSearch: (v) =>
                                setState(() => _lowStockSearch = v),
                            notifiedIds: _notifiedIds,
                            onNotify: _handleNotify,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> overview;
  const _OverviewTab({required this.stats, required this.overview});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                label: 'Total Products',
                value: '${stats['total_products'] ?? 0}',
                icon: Icons.inventory_2_rounded,
                color: AC.primary,
              ),
              StatCard(
                label: 'Total Stock Units',
                value: NumberFormat('#,##0')
                    .format(stats['total_stock_units'] ?? 0),
                icon: Icons.warehouse_rounded,
                color: AC.info,
              ),
              StatCard(
                label: 'Low Stock Items',
                value: '${stats['low_stock_items'] ?? 0}',
                icon: Icons.warning_amber_rounded,
                color: AC.warning,
              ),
              StatCard(
                label: 'Out of Stock',
                value: '${stats['out_of_stock'] ?? 0}',
                icon: Icons.remove_shopping_cart_rounded,
                color: AC.error,
              ),
              StatCard(
                label: 'Stores with Low Stock',
                value: '${stats['stores_with_low_stock'] ?? 0}',
                icon: Icons.store_rounded,
                color: AC.chart5,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Store inventory table
          SectionCard(
            title: 'Store Inventory Overview',
            child: overview.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No store inventory data',
                          style: TextStyle(color: AC.textMuted)),
                    ),
                  )
                : Column(
                    children: [
                      // Header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _Hdr('STORE')),
                            Expanded(flex: 2, child: _Hdr('OWNER')),
                            Expanded(flex: 1, child: _Hdr('PRODUCTS')),
                            Expanded(flex: 1, child: _Hdr('TOTAL STOCK')),
                            Expanded(flex: 1, child: _Hdr('LOW STOCK')),
                            Expanded(flex: 1, child: _Hdr('OUT OF STOCK')),
                            Expanded(flex: 1, child: _Hdr('STATUS')),
                          ],
                        ),
                      ),
                      const Divider(color: AC.border),
                      ...overview.map((s) {
                        final lowCount =
                            (s['low_stock_count'] as num?)?.toInt() ?? 0;
                        final outCount =
                            (s['out_of_stock'] as num?)?.toInt() ?? 0;
                        final active = s['is_active'] as bool? ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  s['store_name'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  s['owner_name'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AC.textSecond,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${s['total_products'] ?? 0}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  NumberFormat('#,##0')
                                      .format(s['total_stock'] ?? 0),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$lowCount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        lowCount > 0 ? AC.warning : AC.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$outCount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        outCount > 0 ? AC.error : AC.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: _StatusBadge(active: active),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Low Stock Alerts tab ─────────────────────────────────────────────────────

class _LowStockTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> items;
  final String search;
  final ValueChanged<String> onSearch;
  final Set<int> notifiedIds;
  final Future<void> Function(int productId) onNotify;

  const _LowStockTab({
    required this.stats,
    required this.items,
    required this.search,
    required this.onSearch,
    required this.notifiedIds,
    required this.onNotify,
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
              Text('${items.length} items',
                  style: const TextStyle(color: AC.textMuted, fontSize: 12)),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search product or store...',
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
              Expanded(flex: 3, child: _Hdr('PRODUCT')),
              Expanded(flex: 2, child: _Hdr('STORE')),
              Expanded(flex: 2, child: _Hdr('CATEGORY')),
              Expanded(flex: 1, child: _Hdr('STOCK')),
              Expanded(flex: 1, child: _Hdr('PRICE')),
              Expanded(flex: 2, child: _Hdr('ACTION')),
            ],
          ),
        ),

        // Table body
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AC.border),
            ),
            child: items.isEmpty
                ? const Center(
                    child: Text('No low stock items',
                        style: TextStyle(color: AC.textMuted)),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AC.border),
                    itemBuilder: (_, i) {
                      final p = items[i];
                      final productId =
                          (p['product_id'] as num?)?.toInt() ?? 0;
                      final stock =
                          (p['stock_quantity'] as num?)?.toInt() ?? 0;
                      final price =
                          (p['price'] as num?)?.toDouble() ?? 0;
                      final notified = notifiedIds.contains(productId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                p['product_name'] ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                p['store_name'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AC.textSecond,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                p['category_label'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AC.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _StockBadge(quantity: stock),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'R ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AC.textSecond,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: notified
                                  ? const Text(
                                      'Notified \u2713',
                                      style: TextStyle(
                                        color: AC.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : SizedBox(
                                      height: 32,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                            Icons.notifications_active_rounded,
                                            size: 14),
                                        label: const Text('Notify Store',
                                            style: TextStyle(fontSize: 12)),
                                        onPressed: () => onNotify(productId),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AC.warning,
                                          side:
                                              const BorderSide(color: AC.warning),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
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
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────

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

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AC.success : AC.textMuted;
    final label = active ? 'Active' : 'Inactive';
    return Container(
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
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int quantity;
  const _StockBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AC.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: AC.error,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AC.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$quantity',
        style: const TextStyle(
          color: AC.warning,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
