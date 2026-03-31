import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});
  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool    _loading = true;
  String  _filter  = 'pending'; // pending | approved | rejected | all
  String  _search  = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApi.getVendorApplications(
        status: _filter == 'all' ? null : _filter,
      );
      setState(() => _items = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AC.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((a) {
      final name  = (a['store_name'] ?? '').toString().toLowerCase();
      final owner = (a['profiles']?['full_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || owner.contains(q);
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
              title: 'Store Approvals',
              subtitle: 'Review vendor onboarding documents',
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                onPressed: _load,
              ),
            ),
            const SizedBox(height: 24),

            // Filter + search bar
            Row(
              children: [
                ..._filterBtn('Pending',  'pending'),
                const SizedBox(width: 8),
                ..._filterBtn('Approved', 'approved'),
                const SizedBox(width: 8),
                ..._filterBtn('Rejected', 'rejected'),
                const SizedBox(width: 8),
                ..._filterBtn('All',      'all'),
                const Spacer(),
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search store or owner…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                      child: Center(child: CircularProgressIndicator(color: AC.primary)),
                    )
                  : _filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                            child: Text('No applications found',
                                style: TextStyle(color: AC.textMuted)),
                          ),
                        )
                      : Column(
                          children: [
                            // Header
                            _TableHeader(cols: const [
                              ('Store Name', 0.22),
                              ('Owner', 0.18),
                              ('Type', 0.10),
                              ('Submitted', 0.14),
                              ('Status', 0.14),
                              ('', 0.10),
                            ]),
                            const Divider(height: 1, color: AC.border),
                            ..._filtered.map((a) => _VendorRow(
                              app: a,
                              onTap: () => context.go('/vendors/${a['id']}'),
                            )),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _filterBtn(String label, String value) {
    final active = _filter == value;
    return [
      InkWell(
        onTap: () {
          setState(() => _filter = value);
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

// ── Table helpers ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<(String, double)> cols;
  const _TableHeader({required this.cols});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: cols.map((c) {
          return Expanded(
            flex: (c.$2 * 100).round(),
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

class _VendorRow extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onTap;
  const _VendorRow({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final owner  = app['profiles'] as Map?;
    final status = app['status'] as String?;
    final date   = app['created_at'] != null
        ? DateFormat('d MMM yyyy').format(DateTime.parse(app['created_at']))
        : '—';
    final type   = (app['business_type'] ?? '').toString();

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 22,
                  child: Text(app['store_name'] ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                Expanded(
                  flex: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner?['full_name'] ?? '—',
                          style: const TextStyle(fontSize: 13)),
                      Text(owner?['email'] ?? '—',
                          style: const TextStyle(fontSize: 11, color: AC.textMuted)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: type == 'formal'
                          ? AC.info.withOpacity(0.1)
                          : AC.chart3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type == 'formal' ? 'Registered' : 'Informal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: type == 'formal' ? AC.info : AC.chart3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Text(date,
                      style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                ),
                Expanded(
                  flex: 14,
                  child: StatusBadge(status),
                ),
                Expanded(
                  flex: 10,
                  child: TextButton(
                    onPressed: onTap,
                    child: const Text('Review →',
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
