import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';

const _categoryLabels = <String, String>{
  'order_issue': 'Order Issue',
  'delivery_problem': 'Delivery Problem',
  'product_complaint': 'Product Complaint',
  'account_issue': 'Account Issue',
  'payment_dispute': 'Payment Dispute',
};

const _categoryOptions = <String>[
  'all',
  'order_issue',
  'delivery_problem',
  'product_complaint',
  'account_issue',
  'payment_dispute',
];

Color _priorityColor(String? p) {
  switch (p) {
    case 'urgent':
      return AC.error;
    case 'high':
      return AC.warning;
    case 'medium':
      return AC.info;
    case 'low':
      return AC.textMuted;
    default:
      return AC.textMuted;
  }
}

String _capitalize(String? s) {
  if (s == null || s.isEmpty) return '—';
  return s[0].toUpperCase() + s.substring(1);
}

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});
  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String _statusFilter = 'open';
  String _categoryFilter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminApi.getTicketStats(),
        AdminApi.getTickets(
          status: _statusFilter == 'all' ? null : _statusFilter,
          category: _categoryFilter == 'all' ? null : _categoryFilter,
        ),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _tickets = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AC.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _tickets;
    final q = _search.toLowerCase();
    return _tickets.where((t) {
      final subject = (t['subject'] ?? '').toString().toLowerCase();
      final number = (t['ticket_number'] ?? '').toString().toLowerCase();
      final customer = (t['customer_name'] ?? '').toString().toLowerCase();
      return subject.contains(q) || number.contains(q) || customer.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Help Desk',
              subtitle: 'Support ticket management',
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                onPressed: _load,
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            _StatsRow(stats: _stats),
            const SizedBox(height: 24),

            // Filter + search
            Row(
              children: [
                ..._statusBtn('Open', 'open'),
                const SizedBox(width: 8),
                ..._statusBtn('In Progress', 'in_progress'),
                const SizedBox(width: 8),
                ..._statusBtn('Resolved', 'resolved'),
                const SizedBox(width: 8),
                ..._statusBtn('Closed', 'closed'),
                const SizedBox(width: 8),
                ..._statusBtn('All', 'all'),
                const SizedBox(width: 16),
                _buildCategoryDropdown(),
                const Spacer(),
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search tickets…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      isDense: true,
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
            const SizedBox(height: 20),

            // Table
            Container(
              decoration: BoxDecoration(
                color: AC.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AC.border),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                          child: CircularProgressIndicator(color: AC.primary)),
                    )
                  : _filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                            child: Text('No tickets found',
                                style: TextStyle(color: AC.textMuted)),
                          ),
                        )
                      : Column(
                          children: [
                            _TicketTableHeader(),
                            const Divider(height: 1, color: AC.border),
                            ..._filtered.map((t) => _TicketRow(
                                  ticket: t,
                                  onTap: () =>
                                      context.go('/helpdesk/${t['id']}'),
                                )),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AC.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _categoryFilter,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: AC.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AC.textSecond),
          items: _categoryOptions.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c == 'all'
                  ? 'All Categories'
                  : _categoryLabels[c] ?? _capitalize(c)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _categoryFilter = v);
              _load();
            }
          },
        ),
      ),
    );
  }

  List<Widget> _statusBtn(String label, String value) {
    final active = _statusFilter == value;
    return [
      InkWell(
        onTap: () {
          setState(() => _statusFilter = value);
          _load();
        },
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
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Open',
          value: '${stats['open'] ?? 0}',
          color: AC.warning,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'In Progress',
          value: '${stats['in_progress'] ?? 0}',
          color: AC.info,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Resolved',
          value: '${stats['resolved'] ?? 0}',
          color: AC.success,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Unassigned',
          value: '${stats['unassigned'] ?? 0}',
          color: AC.error,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              )),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

// ── Table helpers ────────────────────────────────────────────────────────────

class _TicketTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const cols = <(String, int)>[
      ('TICKET #', 10),
      ('SUBJECT', 20),
      ('CUSTOMER', 14),
      ('CATEGORY', 12),
      ('PRIORITY', 10),
      ('STATUS', 10),
      ('ASSIGNED TO', 12),
      ('CREATED', 10),
      ('', 8),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: cols.map((c) {
          return Expanded(
            flex: c.$2,
            child: Text(c.$1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AC.textMuted,
                  letterSpacing: 0.8,
                )),
          );
        }).toList(),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;
  const _TicketRow({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] as String?;
    final priority = ticket['priority'] as String?;
    final category = ticket['category'] as String?;
    final date = ticket['created_at'] != null
        ? DateFormat('d MMM yyyy').format(DateTime.parse(ticket['created_at']))
        : '—';
    final assignedTo = ticket['assigned_to_name'] as String?;
    final priorityColor = _priorityColor(priority);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Ticket #
                Expanded(
                  flex: 10,
                  child: Text(ticket['ticket_number'] ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AC.primary)),
                ),
                // Subject
                Expanded(
                  flex: 20,
                  child: Text(ticket['subject'] ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                // Customer
                Expanded(
                  flex: 14,
                  child: Text(ticket['customer_name'] ?? '—',
                      style:
                          const TextStyle(fontSize: 13, color: AC.textPrimary)),
                ),
                // Category
                Expanded(
                  flex: 12,
                  child: Text(
                      _categoryLabels[category] ?? _capitalize(category),
                      style: const TextStyle(
                          fontSize: 12, color: AC.textSecond)),
                ),
                // Priority
                Expanded(
                  flex: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_capitalize(priority),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            )),
                      ),
                    ],
                  ),
                ),
                // Status
                Expanded(
                  flex: 10,
                  child: StatusBadge(status),
                ),
                // Assigned To
                Expanded(
                  flex: 12,
                  child: Text(assignedTo ?? 'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: assignedTo != null ? AC.textPrimary : AC.textMuted,
                        fontStyle: assignedTo != null
                            ? FontStyle.normal
                            : FontStyle.italic,
                      )),
                ),
                // Created
                Expanded(
                  flex: 10,
                  child: Text(date,
                      style:
                          const TextStyle(fontSize: 12, color: AC.textSecond)),
                ),
                // Action
                Expanded(
                  flex: 8,
                  child: TextButton(
                    onPressed: onTap,
                    child: const Text('View \u2192',
                        style: TextStyle(fontSize: 12, color: AC.primary)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.border),
        ],
      ),
    );
  }
}
