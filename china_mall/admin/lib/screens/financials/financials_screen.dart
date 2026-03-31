import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';
import '../_widgets/stat_card.dart';

// ── Financial Dashboard (super_admin only) ──────────────────────────────────

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});
  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Access
  bool _accessChecked = false;
  bool _isSuperAdmin = false;

  // Period selector for tabs 1-4
  int _days = 30;

  // Tab 1 — Store payouts
  List<Map<String, dynamic>> _storeData = [];

  // Tab 2 — Courier payouts
  List<Map<String, dynamic>> _courierData = [];

  // Tab 3 — Refunds
  List<Map<String, dynamic>> _refundData = [];

  // Tab 4 — Geographic demand
  List<Map<String, dynamic>> _geoData = [];

  // Tab 5 — Books (loaded on demand)
  Map<String, dynamic>? _incomeStatement;
  List<Map<String, dynamic>> _trialBalance = [];
  List<Map<String, dynamic>> _journalEntries = [];
  bool _booksLoading = false;

  // Income statement date range
  late DateTime _isFrom;
  late DateTime _isTo;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    final now = DateTime.now();
    _isFrom = DateTime(now.year, now.month, 1);
    _isTo = now;
    _checkAccessAndLoad();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _checkAccessAndLoad() async {
    try {
      final isSuper = await AdminApi.isSuperAdmin();
      setState(() {
        _isSuperAdmin = isSuper;
        _accessChecked = true;
      });
      if (isSuper) _loadPeriodData();
    } catch (e) {
      setState(() {
        _accessChecked = true;
        _isSuperAdmin = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPeriodData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApi.getFinancialByStore(days: _days),
        AdminApi.getFinancialByCourier(days: _days),
        AdminApi.getRefundSummary(days: _days),
        AdminApi.getGeographicDemand(days: _days),
      ]);
      setState(() {
        _storeData = results[0] as List<Map<String, dynamic>>;
        _courierData = results[1] as List<Map<String, dynamic>>;
        _refundData = results[2] as List<Map<String, dynamic>>;
        _geoData = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _booksLoading = true;
    });
    try {
      final from = DateFormat('yyyy-MM-dd').format(_isFrom);
      final to = DateFormat('yyyy-MM-dd').format(_isTo);
      final results = await Future.wait([
        AdminApi.getIncomeStatement(from, to),
        AdminApi.getTrialBalance(),
        AdminApi.getFinancialEntries(limit: 100),
      ]);
      setState(() {
        _incomeStatement = results[0] as Map<String, dynamic>;
        _trialBalance = results[1] as List<Map<String, dynamic>>;
        _journalEntries = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load books: $e'), backgroundColor: AC.error),
        );
      }
    } finally {
      if (mounted) setState(() => _booksLoading = false);
    }
  }

  String _r(dynamic amount) {
    final v = (amount as num?)?.toDouble() ?? 0;
    return 'R ${NumberFormat('#,##0.00').format(v)}';
  }

  @override
  Widget build(BuildContext context) {
    // Access gate
    if (!_accessChecked) {
      return const Scaffold(
        backgroundColor: AC.bg,
        body: Center(child: CircularProgressIndicator(color: AC.primary)),
      );
    }

    if (!_isSuperAdmin) {
      return Scaffold(
        backgroundColor: AC.bg,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AC.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AC.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.lock_rounded, color: AC.error, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AC.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Financial data is restricted to super administrators only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AC.textSecond),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          Container(
            color: AC.surface,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Financials',
                  subtitle: 'Revenue, payouts, refunds & books',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...[7, 30, 90].map((d) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _days = d);
                                _loadPeriodData();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _days == d ? AC.primary : AC.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          _days == d ? AC.primary : AC.border),
                                ),
                                child: Text(
                                  d == 7
                                      ? '7d'
                                      : d == 30
                                          ? '30d'
                                          : '90d',
                                  style: TextStyle(
                                    color: _days == d
                                        ? Colors.white
                                        : AC.textSecond,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AC.textSecond),
                        onPressed: _loadPeriodData,
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
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Couriers'),
                    Tab(text: 'Refunds'),
                    Tab(text: 'Geographic'),
                    Tab(text: 'Books'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.border),

          // ── Content ──────────────────────────────────────────────────
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
                          _buildOverviewTab(),
                          _buildCouriersTab(),
                          _buildRefundsTab(),
                          _buildGeographicTab(),
                          _buildBooksTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: Overview — Store Payouts
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    final totalGross = _storeData.fold<double>(
        0, (s, r) => s + ((r['gross_sales'] as num?)?.toDouble() ?? 0));
    final totalComm = _storeData.fold<double>(
        0, (s, r) => s + ((r['commission'] as num?)?.toDouble() ?? 0));
    final totalNet = _storeData.fold<double>(
        0, (s, r) => s + ((r['net_to_store'] as num?)?.toDouble() ?? 0));
    final totalOrders = _storeData.fold<int>(
        0, (s, r) => s + ((r['order_count'] as num?)?.toInt() ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                label: 'Gross Sales (${_days}d)',
                value: _r(totalGross),
                icon: Icons.point_of_sale_rounded,
                color: AC.primary,
              ),
              StatCard(
                label: 'Commission Earned',
                value: _r(totalComm),
                icon: Icons.percent_rounded,
                color: AC.chart2,
              ),
              StatCard(
                label: 'Net to Stores',
                value: _r(totalNet),
                icon: Icons.store_rounded,
                color: AC.success,
              ),
              StatCard(
                label: 'Total Orders',
                value: NumberFormat('#,##0').format(totalOrders),
                icon: Icons.receipt_long_rounded,
                color: AC.chart3,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Store table
          SectionCard(
            title: 'Store Payouts',
            child: _storeData.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No store data for this period',
                        style: TextStyle(color: AC.textMuted)),
                  ))
                : Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(flex: 3, child: _Hdr('STORE NAME')),
                          Expanded(flex: 2, child: _Hdr('PROVINCE')),
                          Expanded(flex: 2, child: _Hdr('CITY')),
                          Expanded(flex: 2, child: _Hdr('GROSS SALES')),
                          Expanded(flex: 2, child: _Hdr('COMMISSION')),
                          Expanded(flex: 2, child: _Hdr('NET PAYOUT')),
                          Expanded(flex: 1, child: _Hdr('ORDERS')),
                        ]),
                      ),
                      const Divider(color: AC.border),
                      ..._storeData.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    s['store_name'] ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(s['province'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AC.textSecond)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(s['city'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AC.textSecond)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(s['gross_sales']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(s['commission']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AC.chart2,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(s['net_to_store']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AC.success,
                                          fontWeight: FontWeight.w700)),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                      '${(s['order_count'] as num?)?.toInt() ?? 0}',
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: Couriers — Courier Payouts
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCouriersTab() {
    final totalDeliveries = _courierData.fold<int>(
        0, (s, r) => s + ((r['deliveries_done'] as num?)?.toInt() ?? 0));
    final totalGross = _courierData.fold<double>(
        0, (s, r) => s + ((r['gross_earnings'] as num?)?.toDouble() ?? 0));
    final totalComm = _courierData.fold<double>(
        0, (s, r) => s + ((r['commission'] as num?)?.toDouble() ?? 0));
    final totalNet = _courierData.fold<double>(
        0, (s, r) => s + ((r['net_to_courier'] as num?)?.toDouble() ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                label: 'Total Deliveries (${_days}d)',
                value: NumberFormat('#,##0').format(totalDeliveries),
                icon: Icons.local_shipping_rounded,
                color: AC.primary,
              ),
              StatCard(
                label: 'Gross Earnings',
                value: _r(totalGross),
                icon: Icons.payments_rounded,
                color: AC.chart2,
              ),
              StatCard(
                label: 'Commission',
                value: _r(totalComm),
                icon: Icons.percent_rounded,
                color: AC.chart3,
              ),
              StatCard(
                label: 'Net to Couriers',
                value: _r(totalNet),
                icon: Icons.account_balance_wallet_rounded,
                color: AC.success,
              ),
            ],
          ),
          const SizedBox(height: 24),

          SectionCard(
            title: 'Courier Payouts',
            child: _courierData.isEmpty
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
                          Expanded(flex: 3, child: _Hdr('COURIER NAME')),
                          Expanded(flex: 2, child: _Hdr('DELIVERIES')),
                          Expanded(flex: 2, child: _Hdr('GROSS EARNINGS')),
                          Expanded(flex: 2, child: _Hdr('COMMISSION')),
                          Expanded(flex: 2, child: _Hdr('NET PAYOUT')),
                        ]),
                      ),
                      const Divider(color: AC.border),
                      ..._courierData.map((c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    c['courier_name'] ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                      '${(c['deliveries_done'] as num?)?.toInt() ?? 0}',
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(c['gross_earnings']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(c['commission']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AC.chart2,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(_r(c['net_to_courier']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AC.success,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: Refunds
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRefundsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: SectionCard(
        title: 'Refund Requests',
        child: _refundData.isEmpty
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No refund data for this period',
                    style: TextStyle(color: AC.textMuted)),
              ))
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 50, child: _Hdr('ID')),
                      Expanded(flex: 2, child: _Hdr('CUSTOMER')),
                      Expanded(flex: 2, child: _Hdr('EMAIL')),
                      SizedBox(width: 70, child: _Hdr('ORDER #')),
                      Expanded(flex: 1, child: _Hdr('AMOUNT')),
                      Expanded(flex: 2, child: _Hdr('REASON')),
                      SizedBox(width: 80, child: _Hdr('STATUS')),
                      Expanded(flex: 1, child: _Hdr('DATE')),
                      SizedBox(width: 160, child: _Hdr('ACTION')),
                    ]),
                  ),
                  const Divider(color: AC.border),
                  ..._refundData.map((r) {
                    final status = r['status'] as String? ?? '';
                    final isPending = status == 'pending';
                    final refundId = (r['refund_id'] as num?)?.toInt() ?? 0;
                    final createdAt = r['created_at'] != null
                        ? DateFormat('dd MMM yyyy')
                            .format(DateTime.parse(r['created_at']))
                        : '-';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text('#$refundId',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AC.textMuted)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(r['customer_name'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(r['customer_email'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 12, color: AC.textSecond)),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                                '#${(r['order_id'] as num?)?.toInt() ?? 0}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(_r(r['amount']),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AC.error)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(r['reason'] ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AC.textSecond)),
                          ),
                          SizedBox(
                            width: 80,
                            child: StatusBadge(status),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(createdAt,
                                style: const TextStyle(
                                    fontSize: 11, color: AC.textMuted)),
                          ),
                          SizedBox(
                            width: 160,
                            child: isPending
                                ? Row(
                                    children: [
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _handleRefund(refundId, 'approved'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AC.success,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            textStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _handleRefund(refundId, 'rejected'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AC.error,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            textStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
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

  Future<void> _handleRefund(int refundId, String action) async {
    try {
      await AdminApi.processRefund(refundId, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Refund #$refundId ${action == 'approved' ? 'approved' : 'rejected'} successfully'),
            backgroundColor: action == 'approved' ? AC.success : AC.error,
          ),
        );
        _loadPeriodData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AC.error),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: Geographic Demand
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGeographicTab() {
    // Sort by revenue descending
    final sorted = List<Map<String, dynamic>>.from(_geoData)
      ..sort((a, b) {
        final ra = (a['revenue'] as num?)?.toDouble() ?? 0;
        final rb = (b['revenue'] as num?)?.toDouble() ?? 0;
        return rb.compareTo(ra);
      });

    // Group by province
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final row in sorted) {
      final prov = row['province'] as String? ?? 'Unknown';
      grouped.putIfAbsent(prov, () => []);
      grouped[prov]!.add(row);
    }

    // Rank provinces by total revenue
    final provRanking = grouped.entries.toList()
      ..sort((a, b) {
        final ra = a.value.fold<double>(
            0, (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0));
        final rb = b.value.fold<double>(
            0, (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0));
        return rb.compareTo(ra);
      });

    Color _provinceColor(int rank) {
      if (rank == 0) return AC.chart1;
      if (rank == 1) return AC.chart2;
      if (rank == 2) return AC.chart3;
      return AC.textPrimary;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SA Provinces summary bar
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: provRanking.asMap().entries.map((entry) {
              final rank = entry.key;
              final prov = entry.value.key;
              final rows = entry.value.value;
              final provRevenue = rows.fold<double>(
                  0, (s, r) => s + ((r['revenue'] as num?)?.toDouble() ?? 0));
              final provOrders = rows.fold<int>(
                  0, (s, r) => s + ((r['order_count'] as num?)?.toInt() ?? 0));
              final color = _provinceColor(rank);

              return Container(
                width: 170,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AC.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: rank < 3 ? color.withOpacity(0.4) : AC.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (rank < 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('#${rank + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: color)),
                          ),
                        Text(prov,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_r(provRevenue),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    const SizedBox(height: 2),
                    Text('$provOrders orders',
                        style:
                            const TextStyle(fontSize: 11, color: AC.textMuted)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Detail table grouped by province
          ...provRanking.asMap().entries.map((entry) {
            final rank = entry.key;
            final prov = entry.value.key;
            final rows = entry.value.value;
            final color = _provinceColor(rank);

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SectionCard(
                title: prov,
                action: rank < 3
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Top ${rank + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      )
                    : null,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: _Hdr('CITY')),
                        Expanded(flex: 2, child: _Hdr('ORDERS')),
                        Expanded(flex: 2, child: _Hdr('REVENUE')),
                        Expanded(flex: 1, child: _Hdr('STORES')),
                      ]),
                    ),
                    const Divider(color: AC.border),
                    ...rows.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(r['city'] ?? '-',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '${(r['order_count'] as num?)?.toInt() ?? 0}',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_r(r['revenue']),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                    '${(r['store_count'] as num?)?.toInt() ?? 0}',
                                    style: const TextStyle(
                                        fontSize: 13, color: AC.textSecond)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: Books — Income Statement, Trial Balance, Journal Entries
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBooksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Income Statement ───────────────────────────────────────
          SectionCard(
            title: 'Income Statement',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DatePickerChip(
                  label: 'From: ${DateFormat('dd MMM yyyy').format(_isFrom)}',
                  onPicked: (d) => setState(() => _isFrom = d),
                  initial: _isFrom,
                ),
                const SizedBox(width: 8),
                _DatePickerChip(
                  label: 'To: ${DateFormat('dd MMM yyyy').format(_isTo)}',
                  onPicked: (d) => setState(() => _isTo = d),
                  initial: _isTo,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _booksLoading ? null : _loadBooks,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    child: _booksLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Load'),
                  ),
                ),
              ],
            ),
            child: _incomeStatement == null
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                        'Select a date range and click Load to view the income statement.',
                        style: TextStyle(color: AC.textMuted)),
                  ))
                : _buildIncomeStatementBody(),
          ),
          const SizedBox(height: 24),

          // ── Trial Balance ─────────────────────────────────────────
          SectionCard(
            title: 'Trial Balance',
            action: _trialBalance.isEmpty
                ? SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: _booksLoading ? null : _loadBooks,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Load'),
                    ),
                  )
                : null,
            child: _trialBalance.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Click Load above to fetch trial balance.',
                        style: TextStyle(color: AC.textMuted)),
                  ))
                : _buildTrialBalanceBody(),
          ),
          const SizedBox(height: 24),

          // ── Journal Entries ────────────────────────────────────────
          SectionCard(
            title: 'Journal Entries',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_journalEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: _booksLoading ? null : _loadBooks,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Load'),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Entry'),
                    onPressed: () => _showAddEntryDialog(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            child: _journalEntries.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No journal entries loaded.',
                        style: TextStyle(color: AC.textMuted)),
                  ))
                : _buildJournalEntriesBody(),
          ),
        ],
      ),
    );
  }

  // ── Income Statement body ─────────────────────────────────────────────────

  Widget _buildIncomeStatementBody() {
    final is_ = _incomeStatement!;

    // Revenue items (credits)
    final revenueItems = <_ISLine>[
      _ISLine('Revenue', (is_['revenue'] as num?)?.toDouble() ?? 0),
      _ISLine('Commission Income',
          (is_['commission_income'] as num?)?.toDouble() ?? 0),
      _ISLine('Delivery Fee Income',
          (is_['delivery_fee_income'] as num?)?.toDouble() ?? 0),
      _ISLine(
          'Other Income', (is_['other_income'] as num?)?.toDouble() ?? 0),
    ];

    // Expense items (debits)
    final expenseItems = <_ISLine>[
      _ISLine('Cost of Goods',
          (is_['cost_of_goods'] as num?)?.toDouble() ?? 0),
      _ISLine('Operating Expense',
          (is_['operating_expense'] as num?)?.toDouble() ?? 0),
      _ISLine('Payout Expense',
          (is_['payout_expense'] as num?)?.toDouble() ?? 0),
      _ISLine('Refund Expense',
          (is_['refund_expense'] as num?)?.toDouble() ?? 0),
      _ISLine(
          'Other Expense', (is_['other_expense'] as num?)?.toDouble() ?? 0),
    ];

    final totalCredits =
        revenueItems.fold<double>(0, (s, r) => s + r.amount);
    final totalDebits =
        expenseItems.fold<double>(0, (s, r) => s + r.amount);
    final netIncome = totalCredits - totalDebits;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('REVENUE (Credits)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AC.success,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ...revenueItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.label,
                                style: const TextStyle(
                                    fontSize: 13, color: AC.textSecond)),
                            Text(_r(item.amount),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AC.success)),
                          ],
                        ),
                      )),
                  const Divider(color: AC.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Credits',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(_r(totalCredits),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AC.success)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Expense column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EXPENSES (Debits)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AC.error,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ...expenseItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.label,
                                style: const TextStyle(
                                    fontSize: 13, color: AC.textSecond)),
                            Text(_r(item.amount),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AC.error)),
                          ],
                        ),
                      )),
                  const Divider(color: AC.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Debits',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(_r(totalDebits),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AC.error)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: AC.border, thickness: 2),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Net Income: ',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              _r(netIncome),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: netIncome >= 0 ? AC.success : AC.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Trial Balance body ────────────────────────────────────────────────────

  Widget _buildTrialBalanceBody() {
    final totalDebits = _trialBalance.fold<double>(
        0, (s, r) => s + ((r['total_debits'] as num?)?.toDouble() ?? 0));
    final totalCredits = _trialBalance.fold<double>(
        0, (s, r) => s + ((r['total_credits'] as num?)?.toDouble() ?? 0));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(flex: 3, child: _Hdr('CATEGORY')),
            Expanded(flex: 2, child: _Hdr('DEBITS')),
            Expanded(flex: 2, child: _Hdr('CREDITS')),
            Expanded(flex: 2, child: _Hdr('BALANCE')),
          ]),
        ),
        const Divider(color: AC.border),
        ..._trialBalance.map((r) {
          final bal = (r['balance'] as num?)?.toDouble() ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatCategory(r['category'] as String? ?? ''),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_r(r['total_debits']),
                      style: const TextStyle(
                          fontSize: 13, color: AC.error)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_r(r['total_credits']),
                      style: const TextStyle(
                          fontSize: 13, color: AC.success)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _r(bal.abs()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: bal >= 0 ? AC.success : AC.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(color: AC.border, thickness: 2),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('TOTALS',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
              Expanded(
                flex: 2,
                child: Text(_r(totalDebits),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AC.error)),
              ),
              Expanded(
                flex: 2,
                child: Text(_r(totalCredits),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AC.success)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _r((totalCredits - totalDebits).abs()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: totalCredits >= totalDebits
                        ? AC.success
                        : AC.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Journal Entries body ──────────────────────────────────────────────────

  Widget _buildJournalEntriesBody() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(flex: 1, child: _Hdr('DATE')),
            Expanded(flex: 2, child: _Hdr('CATEGORY')),
            Expanded(flex: 3, child: _Hdr('DESCRIPTION')),
            Expanded(flex: 1, child: _Hdr('DEBIT')),
            Expanded(flex: 1, child: _Hdr('CREDIT')),
            Expanded(flex: 2, child: _Hdr('CREATED BY')),
          ]),
        ),
        const Divider(color: AC.border),
        ..._journalEntries.map((e) {
          final date = e['entry_date'] != null
              ? DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(e['entry_date']))
              : '-';
          final profiles = e['profiles'] as Map<String, dynamic>?;
          final createdBy = profiles?['full_name'] ?? '-';
          final debit = (e['debit'] as num?)?.toDouble() ?? 0;
          final credit = (e['credit'] as num?)?.toDouble() ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(date,
                      style: const TextStyle(
                          fontSize: 12, color: AC.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                      _formatCategory(e['category'] as String? ?? ''),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(e['description'] ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AC.textSecond)),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    debit > 0 ? _r(debit) : '-',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: debit > 0 ? AC.error : AC.textMuted),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    credit > 0 ? _r(credit) : '-',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: credit > 0 ? AC.success : AC.textMuted),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(createdBy,
                      style: const TextStyle(
                          fontSize: 12, color: AC.textSecond)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Add Entry dialog ──────────────────────────────────────────────────────

  static const _categories = [
    'revenue',
    'cost_of_goods',
    'operating_expense',
    'commission_income',
    'payout_expense',
    'refund_expense',
    'delivery_fee_income',
    'other_income',
    'other_expense',
  ];

  void _showAddEntryDialog() {
    final dateCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String selectedCategory = _categories.first;
    final descCtrl = TextEditingController();
    final debitCtrl = TextEditingController(text: '0');
    final creditCtrl = TextEditingController(text: '0');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AC.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Add Financial Entry',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date (yyyy-MM-dd)',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AC.primary,
                            onPrimary: Colors.white,
                            surface: AC.surface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_formatCategory(c),
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedCategory = v);
                  },
                ),
                const SizedBox(height: 14),

                // Description
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                // Debit / Credit
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: debitCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Debit (R)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: creditCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Credit (R)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: AC.textSecond)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final desc = descCtrl.text.trim();
                      if (desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Description is required'),
                              backgroundColor: AC.warning),
                        );
                        return;
                      }
                      setDlgState(() => saving = true);
                      try {
                        await AdminApi.addFinancialEntry(
                          date: dateCtrl.text,
                          category: selectedCategory,
                          description: desc,
                          debit:
                              double.tryParse(debitCtrl.text) ?? 0,
                          credit:
                              double.tryParse(creditCtrl.text) ?? 0,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Entry added successfully'),
                                backgroundColor: AC.success),
                          );
                          _loadBooks();
                        }
                      } catch (e) {
                        setDlgState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AC.error),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatCategory(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ── Shared table header widget ──────────────────────────────────────────────

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
            letterSpacing: 0.8));
  }
}

// ── Date picker chip ────────────────────────────────────────────────────────

class _DatePickerChip extends StatelessWidget {
  final String label;
  final DateTime initial;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerChip({
    required this.label,
    required this.initial,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: ColorScheme.light(
                primary: AC.primary,
                onPrimary: Colors.white,
                surface: AC.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AC.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 13, color: AC.textSecond),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AC.textSecond)),
          ],
        ),
      ),
    );
  }
}

// ── Income statement line model ─────────────────────────────────────────────

class _ISLine {
  final String label;
  final double amount;
  const _ISLine(this.label, this.amount);
}
