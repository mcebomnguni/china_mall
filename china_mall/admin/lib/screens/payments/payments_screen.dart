import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';
import '../_widgets/stat_card.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Data
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _payments  = [];
  List<Map<String, dynamic>> _payouts   = [];
  List<Map<String, dynamic>> _schedules = [];

  bool    _loading = true;
  String? _error;

  // Filters
  String _txFilter     = 'all'; // all | pending | complete | failed | refunded
  String _payoutFilter = 'all'; // all | pending | complete | failed

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        AdminApi.getPaymentStats(days: 30),
        AdminApi.getPayments(
          status: _txFilter == 'all' ? null : _txFilter,
          limit: 200,
        ),
        AdminApi.getPayouts(
          status: _payoutFilter == 'all' ? null : _payoutFilter,
        ),
        AdminApi.getPayoutSchedules(),
      ]);
      setState(() {
        _stats     = results[0] as Map<String, dynamic>;
        _payments  = results[1] as List<Map<String, dynamic>>;
        _payouts   = results[2] as List<Map<String, dynamic>>;
        _schedules = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPayments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminApi.getPayments(
        status: _txFilter == 'all' ? null : _txFilter,
        limit: 200,
      );
      setState(() => _payments = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPayouts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminApi.getPayouts(
        status: _payoutFilter == 'all' ? null : _payoutFilter,
      );
      setState(() => _payouts = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    final totalCollected  = (_stats['total_collected']  as num?)?.toDouble() ?? 0;
    final pendingAmount   = (_stats['pending_amount']   as num?)?.toDouble() ?? 0;
    final pendingPayouts  = (_stats['pending_payouts']  as num?)?.toDouble() ?? 0;
    final commissionEarned = (_stats['commission_earned'] as num?)?.toDouble() ?? 0;

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
                  title: 'Payment Management',
                  subtitle: 'Transactions, payouts & commission schedules',
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                    onPressed: _loadAll,
                    tooltip: 'Refresh',
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Collected',
                        value: 'R ${money.format(totalCollected)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AC.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'Pending Amount',
                        value: 'R ${money.format(pendingAmount)}',
                        icon: Icons.hourglass_top_rounded,
                        color: AC.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'Pending Payouts',
                        value: 'R ${money.format(pendingPayouts)}',
                        icon: Icons.send_rounded,
                        color: AC.chart2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'Commission Earned',
                        value: 'R ${money.format(commissionEarned)}',
                        icon: Icons.trending_up_rounded,
                        color: AC.chart5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: AC.primary,
                  unselectedLabelColor: AC.textMuted,
                  indicatorColor: AC.primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Transactions'),
                    Tab(text: 'Payouts'),
                    Tab(text: 'Schedules'),
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
                          _TransactionsTab(
                            payments: _payments,
                            filter: _txFilter,
                            onFilterChanged: (v) {
                              setState(() => _txFilter = v);
                              _loadPayments();
                            },
                          ),
                          _PayoutsTab(
                            payouts: _payouts,
                            filter: _payoutFilter,
                            onFilterChanged: (v) {
                              setState(() => _payoutFilter = v);
                              _loadPayouts();
                            },
                            onProcess: _handleProcessPayout,
                          ),
                          _SchedulesTab(
                            schedules: _schedules,
                            onUpdate: _handleUpdateSchedule,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Process payout dialog ──────────────────────────────────────────────────

  Future<void> _handleProcessPayout(Map<String, dynamic> payout) async {
    final referenceCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Payout',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entity: ${payout['entity_name'] ?? payout['entity_type'] ?? '—'}',
                style: const TextStyle(fontSize: 13, color: AC.textSecond),
              ),
              const SizedBox(height: 4),
              Text(
                'Net Amount: R ${(payout['net_amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.success),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceCtrl,
                decoration: InputDecoration(
                  labelText: 'Payment Reference (optional)',
                  hintText: 'e.g. EFT-2026-0330',
                  prefixIcon: const Icon(Icons.receipt_long_rounded, size: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AC.textSecond)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AC.success),
            child: const Text('Confirm & Process'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AdminApi.processPayout(
          payout['id'] as int,
          reference: referenceCtrl.text.trim().isEmpty ? null : referenceCtrl.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout processed successfully'), backgroundColor: AC.success),
          );
        }
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AC.error),
          );
        }
      }
    }
    referenceCtrl.dispose();
  }

  // ── Update schedule dialog ─────────────────────────────────────────────────

  Future<void> _handleUpdateSchedule(Map<String, dynamic> schedule) async {
    final freqOptions = ['weekly', 'biweekly', 'monthly'];
    String selectedFreq = (schedule['frequency'] as String?) ?? 'monthly';
    final commCtrl = TextEditingController(
      text: ((schedule['commission_pct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: const Text('Edit Payout Schedule',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_capitalize(schedule['entity_type'] ?? '')} #${schedule['entity_id'] ?? '—'}',
                    style: const TextStyle(fontSize: 13, color: AC.textSecond),
                  ),
                  const SizedBox(height: 16),
                  const Text('Frequency',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textSecond)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedFreq,
                    items: freqOptions.map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(_capitalize(f), style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setDlg(() => selectedFreq = v);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  const SizedBox(height: 16),
                  const Text('Commission %',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textSecond)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g. 10.0',
                      suffixText: '%',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AC.textSecond)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final pct = double.tryParse(commCtrl.text.trim());
        await AdminApi.updatePayoutSchedule(
          schedule['id'] as int,
          frequency: selectedFreq,
          commissionPct: pct,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule updated'), backgroundColor: AC.success),
          );
        }
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AC.error),
          );
        }
      }
    }
    commCtrl.dispose();
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRANSACTIONS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _TransactionsTab extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _TransactionsTab({
    required this.payments,
    required this.filter,
    required this.onFilterChanged,
  });

  static Color _statusColor(String? s) {
    switch (s) {
      case 'complete':  return AC.success;
      case 'pending':   return AC.warning;
      case 'failed':    return AC.error;
      case 'refunded':  return AC.info;
      default:          return AC.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Row(
            children: [
              ..._buildFilter('All',      'all'),
              const SizedBox(width: 8),
              ..._buildFilter('Pending',  'pending'),
              const SizedBox(width: 8),
              ..._buildFilter('Complete', 'complete'),
              const SizedBox(width: 8),
              ..._buildFilter('Failed',   'failed'),
              const SizedBox(width: 8),
              ..._buildFilter('Refunded', 'refunded'),
              const Spacer(),
              Text('${payments.length} transactions',
                  style: const TextStyle(color: AC.textMuted, fontSize: 12)),
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
              Expanded(flex: 2, child: _Hdr('DATE')),
              Expanded(flex: 2, child: _Hdr('CUSTOMER')),
              Expanded(flex: 1, child: _Hdr('ORDER')),
              Expanded(flex: 2, child: _Hdr('AMOUNT')),
              Expanded(flex: 2, child: _Hdr('METHOD')),
              Expanded(flex: 1, child: _Hdr('STATUS')),
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
            child: payments.isEmpty
                ? const Center(child: Text('No transactions found',
                    style: TextStyle(color: AC.textMuted)))
                : ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                    itemBuilder: (_, i) {
                      final p = payments[i];
                      final profile = p['profiles'] as Map<String, dynamic>?;
                      final order   = p['orders']   as Map<String, dynamic>?;
                      final amount  = (p['amount'] as num?)?.toDouble() ?? 0;
                      final status  = p['status'] as String?;
                      final method  = (p['method'] ?? '—').toString();
                      final date    = p['created_at'] != null
                          ? DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(p['created_at']))
                          : '—';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(date,
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile?['full_name'] ?? '—',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(profile?['email'] ?? '—',
                                      style: const TextStyle(fontSize: 11, color: AC.textMuted)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('#${order?['id'] ?? '—'}',
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('R ${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: AC.textPrimary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(method,
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _capitalize(status ?? 'unknown'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
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

  List<Widget> _buildFilter(String label, String value) {
    final active = filter == value;
    return [
      InkWell(
        onTap: () => onFilterChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AC.primary : AC.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AC.primary : AC.border),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? Colors.white : AC.textSecond,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              )),
        ),
      ),
    ];
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAYOUTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PayoutsTab extends StatelessWidget {
  final List<Map<String, dynamic>> payouts;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function(Map<String, dynamic>) onProcess;

  const _PayoutsTab({
    required this.payouts,
    required this.filter,
    required this.onFilterChanged,
    required this.onProcess,
  });

  static Color _statusColor(String? s) {
    switch (s) {
      case 'complete':  return AC.success;
      case 'pending':   return AC.warning;
      case 'failed':    return AC.error;
      default:          return AC.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Row(
            children: [
              ..._buildFilter('All',      'all'),
              const SizedBox(width: 8),
              ..._buildFilter('Pending',  'pending'),
              const SizedBox(width: 8),
              ..._buildFilter('Complete', 'complete'),
              const SizedBox(width: 8),
              ..._buildFilter('Failed',   'failed'),
              const Spacer(),
              Text('${payouts.length} payouts',
                  style: const TextStyle(color: AC.textMuted, fontSize: 12)),
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
              Expanded(flex: 3, child: _Hdr('ENTITY')),
              Expanded(flex: 2, child: _Hdr('PERIOD')),
              Expanded(flex: 2, child: _Hdr('GROSS')),
              Expanded(flex: 2, child: _Hdr('COMMISSION')),
              Expanded(flex: 2, child: _Hdr('NET')),
              Expanded(flex: 1, child: _Hdr('STATUS')),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AC.border),
            ),
            child: payouts.isEmpty
                ? const Center(child: Text('No payouts found',
                    style: TextStyle(color: AC.textMuted)))
                : ListView.separated(
                    itemCount: payouts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AC.border),
                    itemBuilder: (_, i) {
                      final p = payouts[i];
                      final entityName = (p['entity_name'] ?? p['entity_type'] ?? '—').toString();
                      final gross      = (p['gross_amount']      as num?)?.toDouble() ?? 0;
                      final commission = (p['commission_amount'] as num?)?.toDouble() ?? 0;
                      final net        = (p['net_amount']        as num?)?.toDouble() ?? 0;
                      final status     = p['status'] as String?;
                      final periodStart = p['period_start'] != null
                          ? DateFormat('d MMM').format(DateTime.parse(p['period_start']))
                          : '—';
                      final periodEnd = p['period_end'] != null
                          ? DateFormat('d MMM yyyy').format(DateTime.parse(p['period_end']))
                          : '—';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(entityName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('$periodStart – $periodEnd',
                                  style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('R ${money.format(gross)}',
                                  style: const TextStyle(fontSize: 13, color: AC.textPrimary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('R ${money.format(commission)}',
                                  style: const TextStyle(fontSize: 13, color: AC.chart5, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('R ${money.format(net)}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: AC.success)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                                ),
                                child: Text(
                                  _capitalize(status ?? 'unknown'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: status == 'pending'
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: ElevatedButton.icon(
                                          onPressed: () => onProcess(p),
                                          icon: const Icon(Icons.send_rounded, size: 14),
                                          label: const Text('Process', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AC.success,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
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

  List<Widget> _buildFilter(String label, String value) {
    final active = filter == value;
    return [
      InkWell(
        onTap: () => onFilterChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AC.primary : AC.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AC.primary : AC.border),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? Colors.white : AC.textSecond,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              )),
        ),
      ),
    ];
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHEDULES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SchedulesTab extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  final Future<void> Function(Map<String, dynamic>) onUpdate;

  const _SchedulesTab({required this.schedules, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: SectionCard(
        title: 'Payout Schedules',
        child: schedules.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No payout schedules configured',
                      style: TextStyle(color: AC.textMuted)),
                ))
            : Column(
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(flex: 2, child: _Hdr('ENTITY TYPE')),
                      Expanded(flex: 1, child: _Hdr('ENTITY ID')),
                      Expanded(flex: 2, child: _Hdr('FREQUENCY')),
                      Expanded(flex: 2, child: _Hdr('COMMISSION %')),
                      Expanded(flex: 1, child: _Hdr('ACTIVE')),
                      Expanded(flex: 1, child: _Hdr('')),
                    ]),
                  ),
                  const Divider(color: AC.border),
                  ...schedules.map((s) {
                    final entityType   = (s['entity_type'] ?? '—').toString();
                    final entityId     = s['entity_id']?.toString() ?? '—';
                    final frequency    = (s['frequency'] ?? '—').toString();
                    final commission   = (s['commission_pct'] as num?)?.toDouble() ?? 0;
                    final isActive     = s['is_active'] as bool? ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(
                                  entityType == 'store'
                                      ? Icons.storefront_rounded
                                      : Icons.delivery_dining_rounded,
                                  size: 16,
                                  color: entityType == 'store' ? AC.primary : AC.chart2,
                                ),
                                const SizedBox(width: 8),
                                Text(_capitalize(entityType),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('#$entityId',
                                style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AC.chart3.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_capitalize(frequency),
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: AC.chart3)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${commission.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: AC.chart5)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isActive ? AC.success : AC.textMuted).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: (isActive ? AC.success : AC.textMuted).withOpacity(0.3)),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isActive ? AC.success : AC.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => onUpdate(s),
                                icon: const Icon(Icons.edit_rounded, size: 16, color: AC.primary),
                                tooltip: 'Edit schedule',
                              ),
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

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED
// ═══════════════════════════════════════════════════════════════════════════════

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
