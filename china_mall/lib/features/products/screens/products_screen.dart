import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../constants/product_images.dart';
import '../../../data/mock_trends.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategory;
  const ProductsScreen({super.key, this.initialCategory});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _products = [];
  bool _loading = true;
  String? _selectedCategory;
  String _sort = '-created_at';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scroll = ScrollController();
  final _searchController = TextEditingController();

  bool get _isBrowseMode => _selectedCategory == null;

  static final categoryPhotos = [
    {'label': 'Women', 'image': ProductImages.catWomen, 'slug': 'clothing'},
    {'label': 'Men', 'image': ProductImages.catMen, 'slug': 'clothing'},
    {'label': 'Shoes', 'image': ProductImages.catShoes, 'slug': 'shoes'},
    {
      'label': 'Home & Living',
      'image': ProductImages.catHome,
      'slug': 'furniture'
    },
    {'label': 'Kids', 'image': ProductImages.catKids, 'slug': 'toys'},
    {
      'label': 'Beauty',
      'image': ProductImages.catBeauty,
      'slug': 'accessories'
    },
    {
      'label': 'Jewellery',
      'image': ProductImages.catJewelry,
      'slug': 'accessories'
    },
    {
      'label': 'Electronics',
      'image': ProductImages.catElectronics,
      'slug': 'electronics'
    },
  ];

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
    _searchController.dispose();
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
      _page = 1;
      _hasMore = true;
    });

    final res = await ApiService.getProducts(
      category: _selectedCategory,
      ordering: _sort,
      page: 1,
    );
    if (!mounted) return;

    final data = res.isSuccess ? res.data : null;
    final items = _extractItems(data);

    setState(() {
      _products = items;
      _hasMore = _hasNextPage(data);
      _loading = false;
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
      page: _page,
    );
    if (!mounted) return;

    final data = res.isSuccess ? res.data : null;
    final items = _extractItems(data);

    setState(() {
      _products.addAll(items);
      _hasMore = _hasNextPage(data);
      _loadingMore = false;
    });
  }

  List _extractItems(dynamic data) {
    if (data == null) return [];
    if (data is Map) return (data['results'] ?? data) as List? ?? [];
    return data as List? ?? [];
  }

  bool _hasNextPage(dynamic data) => data is Map && data['next'] != null;

  void _selectCategory(String slug) {
    setState(() => _selectedCategory = slug);
    _load();
  }

  void _clearCategory() {
    setState(() => _selectedCategory = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBrowseMode) {
      return _buildCategoryMode();
    }
    return _buildBrowseMode();
  }

  // ── Browse mode: full shop experience ───────────────────────────────────────
  Widget _buildBrowseMode() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Shop',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: LucideIcons.slidersHorizontal,
                      onTap: _showSortSheet,
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search,
                            size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search products or stores...',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.scanLine,
                            size: 18, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Photo category grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: categoryPhotos.length,
                  itemBuilder: (_, i) {
                    final cat = categoryPhotos[i];
                    return Pressable(
                      scaleFactor: 0.97,
                      onTap: () => _selectCategory(cat['slug']!),
                      child: _PhotoCategoryCard(
                        label: cat['label']!,
                        imageUrl: cat['image']!,
                        onTap: () => _selectCategory(cat['slug']!),
                      ),
                    ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 350.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic);
                  },
                ),
              ),
            ),

            // Deals / Brands highlight cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _HighlightCard(
                        label: 'Deals',
                        icon: LucideIcons.sparkles,
                        gradient: AppColors.gradientRed,
                        onTap: () {
                          // Navigate to deals/filtered products
                          _selectCategory('clothing');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightCard(
                        label: 'Brands',
                        icon: LucideIcons.crown,
                        gradient: AppColors.gradientGold,
                        onTap: () {
                          // Navigate to brands/filtered products
                          _selectCategory('accessories');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shop our stores section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Shop our stores',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: mockStores.length,
                  itemBuilder: (_, i) {
                    final store = mockStores[i];
                    return _StoreCard(
                      name: store.name,
                      onTap: () => context.go('/stores/${store.id}'),
                    );
                  },
                ),
              ),
            ),

            // Category chips (horizontal scroll)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 250.ms).slideX(begin: 0.15, end: 0);
                    }
                    final cat = AppConstants.categories[i - 1];
                    final sel = _selectedCategory == cat['slug'];
                    return _CategoryChip(
                      label: cat['label']!,
                      icon: AppConstants.categoryIcon(cat['slug']!),
                      selected: sel,
                      onTap: () => _selectCategory(cat['slug']!),
                    ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 250.ms).slideX(begin: 0.15, end: 0);
                  },
                ),
              ),
            ),

            // Product grid
            _loading
                ? SliverToBoxAdapter(child: _buildSkeletons())
                : _products.isEmpty
                    ? const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: CupertinoIcons.cube_box,
                          title: 'No Products',
                          subtitle: 'No products found in this category.',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childCount:
                              _products.length + (_loadingMore ? 2 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _products.length) {
                              return ShimmerBox(
                                width: double.infinity,
                                height: 180,
                                radius: 20,
                              );
                            }
                            final p = _products[i];
                            return Pressable(
                              scaleFactor: 0.97,
                              onTap: () =>
                                  context.go('/products/${p['id']}'),
                              child: _ProductTile(
                                product: p,
                                onTap: () =>
                                    context.go('/products/${p['id']}'),
                              ),
                            ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 350.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // ── Category mode: filtered view ────────────────────────────────────────────
  Widget _buildCategoryMode() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _clearCategory,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(LucideIcons.arrowLeft,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _categoryLabel(),
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
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

            // Category chips
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: AppConstants.categories.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final sel = _selectedCategory == null;
                    return _CategoryChip(
                      label: 'All',
                      icon: LucideIcons.layoutGrid,
                      selected: sel,
                      onTap: _clearCategory,
                    ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 250.ms).slideX(begin: 0.15, end: 0);
                  }
                  final cat = AppConstants.categories[i - 1];
                  final sel = _selectedCategory == cat['slug'];
                  return _CategoryChip(
                    label: cat['label']!,
                    icon: AppConstants.categoryIcon(cat['slug']!),
                    selected: sel,
                    onTap: () => _selectCategory(cat['slug']!),
                  ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 250.ms).slideX(begin: 0.15, end: 0);
                },
              ),
            ),

            // Product grid
            Expanded(
              child: _loading
                  ? _buildSkeletons()
                  : _products.isEmpty
                      ? const EmptyState(
                          icon: CupertinoIcons.cube_box,
                          title: 'No Products',
                          subtitle: 'No products found in this category.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: MasonryGridView.count(
                            controller: _scroll,
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount:
                                _products.length + (_loadingMore ? 2 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _products.length) {
                                return ShimmerBox(
                                  width: double.infinity,
                                  height: 180,
                                  radius: 20,
                                );
                              }
                              final p = _products[i];
                              return Pressable(
                                scaleFactor: 0.97,
                                onTap: () =>
                                    context.go('/products/${p['id']}'),
                                child: _ProductTile(
                                  product: p,
                                  onTap: () =>
                                      context.go('/products/${p['id']}'),
                                ),
                              ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 350.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel() {
    if (_selectedCategory == null) return 'Shop';
    // Try to find from photo categories first
    for (final cat in categoryPhotos) {
      if (cat['slug'] == _selectedCategory) return cat['label']!;
    }
    // Fall back to AppConstants
    for (final cat in AppConstants.categories) {
      if (cat['slug'] == _selectedCategory) return cat['label']!;
    }
    return 'Shop';
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
          _sortAction('Newest First', '-created_at'),
          _sortAction('Price: Low to High', 'price'),
          _sortAction('Price: High to Low', '-price'),
          _sortAction('Most Popular', '-sales_count'),
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

class _PhotoCategoryCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;
  const _PhotoCategoryCard({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.border,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.border,
                child: const Icon(LucideIcons.image,
                    color: AppColors.textTertiary),
              ),
            ),
            // Dark gradient overlay on bottom 40%
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Category name
            Positioned(
              left: 12,
              bottom: 10,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _HighlightCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _StoreCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.mapPin, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'China Mall',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                color: selected ? AppColors.white : AppColors.textPrimary,
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
            Hero(
              tag: 'product-image-${product['id']}',
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(
                      url: product['image'], fit: BoxFit.cover),
                ),
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
                      rating: (product['rating'] as num).toDouble(),
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
