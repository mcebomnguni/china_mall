import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});
 
  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}
 
class _VendorProductsScreenState extends State<VendorProductsScreen> {
  List _products = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getMyProducts();
    if (!mounted) return;
    setState(() {
      _products = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  Future<void> _restockProduct(int id, String name, int currentQty) async {
    final ctrl = TextEditingController(text: currentQty.toString());
    final newQty = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Update Stock',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
                decoration: InputDecoration(
                  labelText: 'New stock quantity',
                  suffixText: 'units',
                  helperText:
                      'Product hides automatically when stock reaches 0. Notified when below 3.',
                  helperMaxLines: 2,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontFamily: 'Satoshi')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final v = int.tryParse(ctrl.text.trim());
                        if (v != null && v >= 0) {
                          Navigator.pop(ctx, v);
                        }
                      },
                      child: const Text('Update',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();
    if (newQty == null) return;

    final res = await ApiService.updateProductStock(id, newQty);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newQty == 0
              ? '"$name" is now hidden from customers (stock 0).'
              : 'Stock updated to $newQty unit(s).'),
          backgroundColor:
              newQty == 0 ? Colors.orange : Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.errorMessage)),
      );
    }
  }

  Future<void> _deleteProduct(int id, String name) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Product'),
        content: Text('Remove "$name" from your store?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.deleteProduct(id);
    _load();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Products (${_products.length})'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => context.push('/vendor/products/add'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.bag,
                  title: 'No products yet',
                  subtitle: 'Add your first product to start selling',
                  buttonLabel: 'Add Product',
                  onButton: () => context.push('/vendor/products/add'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppNetworkImage(
                              url: p['image'],
                              width: 64,
                              height: 64,
                              radius: 10,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(p['name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (p['is_on_sale'] == true &&
                                          p['sale_price'] != null) ...[
                                        Text(
                                          'R${((p['price'] ?? 0) as num).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontSize: 12,
                                            color: AppColors.textTertiary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'R${(p['sale_price'] as num).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ] else
                                        PriceText(
                                            price: (p['price'] ?? 0)
                                                .toDouble()),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _restockProduct(
                                          p['id'] as int,
                                          p['name'] ?? '',
                                          (p['stock_quantity'] ?? 0) as int,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (p['stock_quantity'] ?? 0) == 0
                                                ? AppColors.error.withValues(alpha: 0.1)
                                                : (p['stock_quantity'] ?? 0) < 3
                                                    ? Colors.orange.withValues(alpha: 0.1)
                                                    : AppColors.background,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: (p['stock_quantity'] ?? 0) == 0
                                                  ? AppColors.error.withValues(alpha: 0.4)
                                                  : (p['stock_quantity'] ?? 0) < 3
                                                      ? Colors.orange.withValues(alpha: 0.4)
                                                      : AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Stock: ${p['stock_quantity'] ?? 0}',
                                                style: TextStyle(
                                                  fontFamily: 'Satoshi',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: (p['stock_quantity'] ?? 0) == 0
                                                      ? AppColors.error
                                                      : (p['stock_quantity'] ?? 0) < 3
                                                          ? Colors.orange.shade700
                                                          : AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Icon(
                                                CupertinoIcons.pencil,
                                                size: 10,
                                                color: AppColors.textTertiary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    StatusChip(
                                        status: p['status'] ?? 'pending'),
                                    if (p['is_on_sale'] == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('SALE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Satoshi',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            )),
                                      ),
                                    ],
                                  ]),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style: TextStyle(
                                          color: AppColors.error)),
                                ),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') {
                                  context.go('/vendor/products/${p["id"]}/edit');
                                } else if (v == 'delete') {
                                  _deleteProduct(
                                      p['id'], p['name'] ?? '');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendor/products/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}