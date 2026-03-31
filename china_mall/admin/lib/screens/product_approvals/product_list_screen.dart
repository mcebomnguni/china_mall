import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool   _loading = true;
  String _filter  = 'pending';
  String _search  = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApi.getProducts(
        status: _filter == 'all' ? null : _filter,
      );
      setState(() => _items = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AC.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((p) {
      final name  = (p['name'] ?? '').toString().toLowerCase();
      final store = (p['stores']?['name'] ?? '').toString().toLowerCase();
      return name.contains(q) || store.contains(q);
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
              title: 'Product Approvals',
              subtitle: 'Review product listings before they go live',
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AC.textSecond),
                onPressed: _load,
              ),
            ),
            const SizedBox(height: 24),

            // Filters
            Row(
              children: [
                ..._fb('Pending',         'pending'),
                const SizedBox(width: 8),
                ..._fb('Needs Changes',   'needs_changes'),
                const SizedBox(width: 8),
                ..._fb('Active',          'active'),
                const SizedBox(width: 8),
                ..._fb('Rejected',        'rejected'),
                const SizedBox(width: 8),
                ..._fb('All',             'all'),
                const Spacer(),
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search product or store…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                            child: Text('No products found',
                                style: TextStyle(color: AC.textMuted)),
                          ),
                        )
                      : Column(
                          children: [
                            _TableHeader(cols: const [
                              ('', 0.06),
                              ('Product', 0.24),
                              ('Store', 0.18),
                              ('Price', 0.10),
                              ('Category', 0.12),
                              ('Added', 0.12),
                              ('Status', 0.12),
                              ('', 0.06),
                            ]),
                            const Divider(height: 1, color: AC.border),
                            ..._filtered.map((p) => _ProductRow(
                              product: p,
                              onTap: () => context.go('/products/${p['id']}'),
                            )),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fb(String label, String value) {
    final active = _filter == value;
    return [
      InkWell(
        onTap: () { setState(() => _filter = value); _load(); },
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

class _ProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final images  = (product['product_images'] as List?)?.cast<Map>() ?? [];
    final thumbUrl = images.isEmpty ? null
        : (images..sort((a, b) => (a['ordinal'] ?? 0).compareTo(b['ordinal'] ?? 0)))
            .first['url'] as String?;
    final store   = product['stores'] as Map?;
    final cat     = product['categories'] as Map?;
    final status  = product['status'] as String?;
    final price   = (product['price'] as num?)?.toDouble() ?? 0;
    final date    = product['created_at'] != null
        ? DateFormat('d MMM yy').format(DateTime.parse(product['created_at']))
        : '—';

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Thumbnail
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbUrl != null
                        ? Image.network(thumbUrl, width: 44, height: 44,
                            fit: BoxFit.cover)
                        : Container(
                            width: 44, height: 44,
                            color: AC.bg,
                            child: const Icon(Icons.image_not_supported_rounded,
                                color: AC.textMuted, size: 18)),
                  ),
                ),
                // Name
                Expanded(
                  flex: 24,
                  child: Text(product['name'] ?? '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                // Store
                Expanded(
                  flex: 18,
                  child: Text(store?['name'] ?? '—',
                      style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                ),
                // Price
                Expanded(
                  flex: 10,
                  child: Text('R ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AC.success)),
                ),
                // Category
                Expanded(
                  flex: 12,
                  child: Text(cat?['label'] ?? '—',
                      style: const TextStyle(fontSize: 12, color: AC.textSecond)),
                ),
                // Date
                Expanded(
                  flex: 12,
                  child: Text(date,
                      style: const TextStyle(fontSize: 12, color: AC.textMuted)),
                ),
                // Status
                Expanded(
                  flex: 12,
                  child: StatusBadge(status),
                ),
                // Action
                Expanded(
                  flex: 6,
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
