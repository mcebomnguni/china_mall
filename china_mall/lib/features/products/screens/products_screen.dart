import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_constants.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategory;
  const ProductsScreen({super.key, this.initialCategory});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _products    = [];
  bool _loading     = true;
  String? _selectedCategory;
  String _sort      = '-created_at';
  int  _page        = 1;
  bool _hasMore     = true;
  bool _loadingMore = false;
  final _scroll     = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
            _scroll.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page    = 1;
      _hasMore = true;
    });

    final res = await ApiService.getProducts(
      category: _selectedCategory,
      ordering: _sort,
      page:     1,
    );
    if (!mounted) return;

    final data  = res.isSuccess ? res.data : null;
    final items = _extractItems(data);

    setState(() {
      _products = items;
      _hasMore  = _hasNextPage(data);
      _loading  = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _page++;
    });

    final res = await ApiService.getProducts(
      category: _selectedCategory,
      ordering: _sort,
      page:     _page,
    );
    if (!mounted) return;

    final data  = res.isSuccess ? res.data : null;
    final items = _extractItems(data);

    setState(() {
      _products.addAll(items);
      _hasMore     = _hasNextPage(data);
      _loadingMore = false;
    });
  }

  List _extractItems(dynamic data) {
    if (data == null) return [];
    if (data is Map) return (data['results'] ?? data) as List? ?? [];
    return data as List? ?? [];
  }

  bool _hasNextPage(dynamic data) =>
      data is Map && data['next'] != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Shop',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  _IconBtn(
                    icon: LucideIcons.search,
                    onTap: () => context.go('/search'),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: LucideIcons.slidersHorizontal,
                    onTap: _showSortSheet,
                  ),
                ],
              ),
            ),

            // ── Category chips ────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                itemCount: AppConstants.categories.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final sel = _selectedCategory == null;
                    return _CategoryChip(
                      label: 'All',
                      icon: LucideIcons.layoutGrid,
                      selected: sel,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        _load();
                      },
                    );
                  }
                  final cat = AppConstants.categories[i - 1];
                  final sel = _selectedCategory == cat['slug'];
                  return _CategoryChip(
                    label: cat['label']!,
                    icon: AppConstants.categoryIcon(cat['slug']!),
                    selected: sel,
                    onTap: () {
                      setState(() => _selectedCategory = cat['slug']);
                      _load();
                    },
                  );
                },
              ),
            ),

            // ── Grid ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? _buildSkeletons()
                  : _products.isEmpty
                      ? const EmptyState(
                          icon: CupertinoIcons.cube_box,
                          title: 'No Products',
                          subtitle:
                              'No products found in this category.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: MasonryGridView.count(
                            controller: _scroll,
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            padding: const EdgeInsets.fromLTRB(
                                20, 8, 20, 20),
                            itemCount: _products.length +
                                (_loadingMore ? 2 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _products.length) {
                                return ShimmerBox(
                                  width: double.infinity,
                                  height: 180,
                                  radius: 20,
                                );
                              }
                              final p = _products[i];
                              return _ProductTile(
                                product: p,
                                onTap: () =>
                                    context.go('/products/${p['id']}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: 6,
      itemBuilder: (_, i) => ShimmerBox(
        width: double.infinity,
        height: i.isEven ? 200 : 160,
        radius: 20,
      ),
    );
  }

  void _showSortSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: [
          _sortAction('Newest First',       '-created_at'),
          _sortAction('Price: Low to High', 'price'),
          _sortAction('Price: High to Low', '-price'),
          _sortAction('Most Popular',       '-sales_count'),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _sortAction(String label, String value) {
    return CupertinoActionSheetAction(
      child: Text(label),
      onPressed: () {
        Navigator.pop(context);
        setState(() => _sort = value);
        _load();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.white : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.white
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Map product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                    url: product['image'], fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'R ${double.tryParse(product['price'].toString())?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product['rating'] != null) ...[
                    const SizedBox(height: 4),
                    StarRating(
                      rating:
                          (product['rating'] as num).toDouble(),
                      size: 11,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
