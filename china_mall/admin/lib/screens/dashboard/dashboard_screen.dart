import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/stat_card.dart';
import '../_widgets/section_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await AdminApi.getStats();
      setState(() => _stats = s);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(num? v) => v == null ? '—' : NumberFormat.compact().format(v);
  String _money(num? v) => v == null ? '—' : 'R ${NumberFormat('#,##0').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AC.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Dashboard',
                        subtitle: 'Platform overview · ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                          onPressed: _load,
                          tooltip: 'Refresh',
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Attention needed row ───────────────────────────
                      _AttentionBanner(
                        pendingVendors : (_stats?['pending_vendor_apps'] as num?)?.toInt() ?? 0,
                        pendingProducts: (_stats?['pending_products'] as num?)?.toInt() ?? 0,
                        openTickets:     (_stats?['open_tickets'] as num?)?.toInt() ?? 0,
                        lowStockItems:   (_stats?['low_stock_items'] as num?)?.toInt() ?? 0,
                        pendingPayouts:  (_stats?['pending_payouts'] as num?)?.toInt() ?? 0,
                        onVendors: () => context.go('/vendors'),
                        onProducts: () => context.go('/products'),
                        onTickets: () => context.go('/helpdesk'),
                        onInventory: () => context.go('/inventory'),
                        onPayouts: () => context.go('/payments'),
                      ),
                      const SizedBox(height: 24),

                      // ── Stats grid ────────────────────────────────────
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          StatCard(
                            label: 'Revenue Today',
                            value: _money(_stats?['revenue_today']),
                            icon: Icons.payments_rounded,
                            color: AC.success,
                          ),
                          StatCard(
                            label: 'Revenue (30d)',
                            value: _money(_stats?['revenue_30d']),
                            icon: Icons.trending_up_rounded,
                            color: AC.primary,
                          ),
                          StatCard(
                            label: 'Orders Today',
                            value: _fmt(_stats?['total_orders_today']),
                            icon: Icons.receipt_long_rounded,
                            color: AC.info,
                          ),
                          StatCard(
                            label: 'Active Stores',
                            value: _fmt(_stats?['total_stores']),
                            icon: Icons.store_rounded,
                            color: AC.chart3,
                          ),
                          StatCard(
                            label: 'Live Products',
                            value: _fmt(_stats?['total_products']),
                            icon: Icons.inventory_2_rounded,
                            color: AC.chart5,
                          ),
                          StatCard(
                            label: 'Total Users',
                            value: _fmt(_stats?['total_users']),
                            icon: Icons.people_rounded,
                            color: AC.chart2,
                          ),
                          StatCard(
                            label: 'Open Tickets',
                            value: _fmt(_stats?['open_tickets']),
                            icon: Icons.support_agent_rounded,
                            color: AC.warning,
                          ),
                          StatCard(
                            label: 'Low Stock Alerts',
                            value: _fmt(_stats?['low_stock_items']),
                            icon: Icons.inventory_rounded,
                            color: AC.error,
                          ),
                          StatCard(
                            label: 'Pending Payouts',
                            value: _money(_stats?['pending_payout_total']),
                            icon: Icons.payments_rounded,
                            color: AC.chart3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Quick links ───────────────────────────────────
                      SectionCard(
                        title: 'Quick Actions',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _QuickAction(
                              label: 'Review Vendor Applications',
                              icon: Icons.store_rounded,
                              color: AC.warning,
                              onTap: () => context.go('/vendors'),
                            ),
                            _QuickAction(
                              label: 'Review Product Listings',
                              icon: Icons.inventory_2_rounded,
                              color: AC.info,
                              onTap: () => context.go('/products'),
                            ),
                            _QuickAction(
                              label: 'View Analytics',
                              icon: Icons.bar_chart_rounded,
                              color: AC.primary,
                              onTap: () => context.go('/analytics'),
                            ),
                            _QuickAction(
                              label: 'Manage Payments',
                              icon: Icons.payments_rounded,
                              color: AC.chart3,
                              onTap: () => context.go('/payments'),
                            ),
                            _QuickAction(
                              label: 'Help Desk',
                              icon: Icons.support_agent_rounded,
                              color: AC.chart5,
                              onTap: () => context.go('/helpdesk'),
                            ),
                            _QuickAction(
                              label: 'Stock Oversight',
                              icon: Icons.inventory_rounded,
                              color: AC.error,
                              onTap: () => context.go('/inventory'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Attention banner ──────────────────────────────────────────────────────────

class _AttentionBanner extends StatelessWidget {
  final int pendingVendors;
  final int pendingProducts;
  final int openTickets;
  final int lowStockItems;
  final int pendingPayouts;
  final VoidCallback onVendors;
  final VoidCallback onProducts;
  final VoidCallback onTickets;
  final VoidCallback onInventory;
  final VoidCallback onPayouts;

  const _AttentionBanner({
    required this.pendingVendors,
    required this.pendingProducts,
    required this.openTickets,
    required this.lowStockItems,
    required this.pendingPayouts,
    required this.onVendors,
    required this.onProducts,
    required this.onTickets,
    required this.onInventory,
    required this.onPayouts,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = pendingVendors + pendingProducts + openTickets + lowStockItems + pendingPayouts > 0;
    if (!hasAny) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AC.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: AC.warning, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Action required:',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AC.textPrimary)),
                if (pendingVendors > 0)
                  _AttentionChip(
                    label: '$pendingVendors store app${pendingVendors == 1 ? '' : 's'}',
                    onTap: onVendors,
                  ),
                if (pendingProducts > 0)
                  _AttentionChip(
                    label: '$pendingProducts product${pendingProducts == 1 ? '' : 's'} to review',
                    onTap: onProducts,
                  ),
                if (openTickets > 0)
                  _AttentionChip(
                    label: '$openTickets open ticket${openTickets == 1 ? '' : 's'}',
                    onTap: onTickets,
                  ),
                if (lowStockItems > 0)
                  _AttentionChip(
                    label: '$lowStockItems low stock alert${lowStockItems == 1 ? '' : 's'}',
                    onTap: onInventory,
                  ),
                if (pendingPayouts > 0)
                  _AttentionChip(
                    label: '$pendingPayouts payout${pendingPayouts == 1 ? '' : 's'} pending',
                    onTap: onPayouts,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AttentionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AC.warning.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
              color: AC.warning,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
      ),
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
          ],
        ),
      ),
    );
  }
}
