import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/section_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final int id;
  const ProductDetailScreen({super.key, required this.id});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  int    _imageIndex = 0;
  bool   _loading    = true;
  bool   _acting     = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await AdminApi.getProductDetail(widget.id);
      setState(() => _product = p);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _acting = true);
    try {
      await AdminApi.approveProduct(widget.id);
      if (mounted) { _showSuccess('Product approved and now live.'); context.go('/products'); }
    } catch (e) { _showError(e.toString()); }
    finally { if (mounted) setState(() => _acting = false); }
  }

  Future<void> _reject() => _notesDialog(
    title: 'Reject Product Listing',
    confirmLabel: 'Reject',
    confirmColor: AC.error,
    hint: 'Why is this listing being rejected?',
    onConfirm: (notes) async {
      await AdminApi.rejectProduct(widget.id, notes: notes);
      if (mounted) { _showSuccess('Product rejected.'); context.go('/products'); }
    },
  );

  Future<void> _requestChanges() => _notesDialog(
    title: 'Request Changes',
    confirmLabel: 'Send Request',
    confirmColor: AC.info,
    hint: 'What needs to be fixed or updated?',
    onConfirm: (notes) async {
      await AdminApi.productNeedsChanges(widget.id, notes: notes);
      if (mounted) { _showSuccess('Change request sent to vendor.'); await _load(); }
    },
  );

  Future<void> _notesDialog({
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required String hint,
    required Future<void> Function(String) onConfirm,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl, maxLines: 4, autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _acting = true);
      try { await onConfirm(ctrl.text.trim()); }
      catch (e) { _showError(e.toString()); }
      finally { if (mounted) setState(() => _acting = false); }
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AC.success,
        behavior: SnackBarBehavior.floating));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AC.error,
        behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(children: [
                        TextButton.icon(
                          onPressed: () => context.go('/products'),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Product Approvals'),
                        ),
                        const Text(' / ', style: TextStyle(color: AC.textMuted)),
                        Text(_product?['name'] ?? '',
                            style: const TextStyle(color: AC.textSecond)),
                      ]),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left — images + details
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _ImagesCard(
                                  product: _product!,
                                  index: _imageIndex,
                                  onIndexChange: (i) => setState(() => _imageIndex = i),
                                ),
                                const SizedBox(height: 16),
                                _DetailsCard(product: _product!),
                                if (_product!['admin_notes'] != null) ...[
                                  const SizedBox(height: 16),
                                  _NotesCard(notes: _product!['admin_notes']),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right — action panel
                          SizedBox(
                            width: 280,
                            child: _ActionPanel(
                              product: _product!,
                              acting: _acting,
                              onApprove: _approve,
                              onReject: _reject,
                              onChanges: _requestChanges,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Images card ───────────────────────────────────────────────────────────────

class _ImagesCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final ValueChanged<int> onIndexChange;
  const _ImagesCard({required this.product, required this.index, required this.onIndexChange});

  @override
  Widget build(BuildContext context) {
    final rawImages = (product['product_images'] as List?)?.cast<Map>() ?? [];
    final images = List<Map>.from(rawImages)
      ..sort((a, b) => (a['ordinal'] ?? 0).compareTo(b['ordinal'] ?? 0));

    return SectionCard(
      title: 'Product Images (${images.length})',
      child: Column(
        children: [
          // Main image
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[index]['url'] as String,
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AC.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('No images submitted',
                    style: TextStyle(color: AC.textMuted)),
              ),
            ),

          if (images.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => onIndexChange(i),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: i == index ? AC.primary : AC.border,
                        width: i == index ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        images[i]['url'] as String,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final store      = product['stores']     as Map?;
    final cat        = product['categories'] as Map?;
    final price      = (product['price'] as num?)?.toDouble() ?? 0;
    final vendorPrice = (product['vendor_price'] as num?)?.toDouble() ?? 0;
    final date       = product['created_at'] != null
        ? DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(product['created_at']))
        : '—';

    final colours  = (product['colours']  as List?)?.cast<String>() ?? [];
    final sizes    = (product['sizes']    as List?)?.cast<String>() ?? [];

    return SectionCard(
      title: 'Product Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Product Name',    product['name'] ?? '—'),
          _Row('Store',           store?['name'] ?? '—'),
          _Row('Category',        cat?['label'] ?? '—'),
          _Row('Vendor Price',    'R ${vendorPrice.toStringAsFixed(2)}'),
          _Row('Customer Price',  'R ${price.toStringAsFixed(2)}'),
          if (product['is_on_sale'] == true)
            _Row('Sale Price',
                'R ${(product['sale_price'] as num?)?.toStringAsFixed(2) ?? '—'}'),
          _Row('Stock',           '${product['stock_quantity'] ?? 0} units'),
          _Row('SKU / Ref',       product['product_ref_id'] ?? '—'),
          _Row('Fabric/Material', product['fabric_material'] ?? '—'),
          _Row('Submitted',       date),
          const SizedBox(height: 12),

          // Description
          const Text('Description',
              style: TextStyle(fontSize: 12, color: AC.textSecond,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(product['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 13, height: 1.6)),

          if (colours.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Colours',
                style: TextStyle(fontSize: 12, color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: colours
                  .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AC.bg,
                        side: const BorderSide(color: AC.border),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          if (sizes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Sizes',
                style: TextStyle(fontSize: 12, color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: sizes
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AC.bg,
                        side: const BorderSide(color: AC.border),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AC.textSecond, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AC.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded, color: AC.warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Notes',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        color: AC.warning, fontSize: 12)),
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action panel ──────────────────────────────────────────────────────────────

class _ActionPanel extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onChanges;
  const _ActionPanel({
    required this.product,
    required this.acting,
    required this.onApprove,
    required this.onReject,
    required this.onChanges,
  });

  @override
  Widget build(BuildContext context) {
    final status = product['status'] as String?;
    final isPending = status == 'pending' || status == 'needs_changes';

    return SectionCard(
      title: 'Decision',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBadge(status),
          const SizedBox(height: 16),

          if (isPending) ...[
            const Text(
              'Check for:\n'
              '• Accurate name & description\n'
              '• Clear, appropriate images (min 3)\n'
              '• No counterfeit branding\n'
              '• Correct pricing\n'
              '• No prohibited items',
              style: TextStyle(fontSize: 12, color: AC.textSecond, height: 1.8),
            ),
            const SizedBox(height: 20),

            if (acting) ...[
              const Center(child: CircularProgressIndicator(color: AC.primary)),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve & Go Live'),
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(backgroundColor: AC.success),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Request Changes'),
                onPressed: onChanges,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AC.info,
                  side: const BorderSide(color: AC.info),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject Listing'),
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AC.error,
                  side: const BorderSide(color: AC.error),
                ),
              ),
            ],
          ] else ...[
            Text(
              status == 'active'
                  ? 'This product is live on the marketplace.'
                  : 'This listing has been finalised.',
              style: const TextStyle(fontSize: 12, color: AC.textSecond),
            ),
          ],
        ],
      ),
    );
  }
}
