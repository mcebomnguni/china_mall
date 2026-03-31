import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class StoreDetailScreen extends StatefulWidget {
  final int id;
  const StoreDetailScreen({super.key, required this.id});
 
  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}
 
class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  Map? _store;
  List _products    = [];
  List _reviews     = [];
  bool _loading     = true;
  bool _loadError   = false;
  late TabController _tabCtrl;

  // S7 — category filter (null = show all)
  String? _selectedParent;

  List get _filteredProducts {
    if (_selectedParent == null) return _products;
    return _products.where((p) {
      final slug = p['category']?['slug']?.toString() ?? '';
      return AppConstants.categoryParent(slug) == _selectedParent;
    }).toList();
  }

  /// Unique parent groups that actually appear in this store's products.
  List<Map<String, String>> get _availableGroups {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final p in _products) {
      final slug = p['category']?['slug']?.toString() ?? '';
      final parent = AppConstants.categoryParent(slug);
      if (parent != null && seen.add(parent)) {
        final group = AppConstants.categoryGroups
            .firstWhere((g) => g['slug'] == parent,
                orElse: () => {'slug': parent, 'label': parent, 'icon': ''});
        result.add(group);
      }
    }
    return result;
  }
 
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }
 
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = false; });
    try {
      final results = await Future.wait([
        ApiService.getStore(widget.id),
        ApiService.getProductsByStore(widget.id),
        ApiService.getStoreReviews(widget.id),
      ]);
 
      if (!mounted) return;
 
      setState(() {
        // Store
        _store = results[0].isSuccess ? results[0].data : null;
        if (!results[0].isSuccess) _loadError = true;
 
        // Products — handle both paginated Map and direct List
        if (results[1].isSuccess) {
          final data = results[1].data;
          _products = data is Map
              ? (data['results'] as List? ?? [])
              : (data as List? ?? []);
        }
 
        // Reviews — same shape handling
        if (results[2].isSuccess) {
          final data = results[2].data;
          _reviews = data is Map
              ? (data['results'] as List? ?? [])
              : (data as List? ?? []);
        }
 
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _loadError = true; });
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Network error — show retry screen instead of "Store not found".
    if (_loadError && _store == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back,
                color: AppColors.textPrimary),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/stores'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.wifi_slash,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text(
                'Could not load store',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_store == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back,
                color: AppColors.textPrimary),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/stores'),
          ),
        ),
        body: const EmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Store not found',
          subtitle: 'This store may no longer be available.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go('/'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(CupertinoIcons.back,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: _store!['banner'] ?? '',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.border, width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AppNetworkImage(
                          url: _store!['logo'] ?? '',
                          width: 60,
                          height: 60,
                          radius: 12,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _store!['name'] ?? 'Unnamed Store',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            StarRating(
                              rating: double.tryParse(
                                      _store!['average_rating']
                                              ?.toString() ??
                                          '0') ??
                                  0.0,
                              reviewCount:
                                  _store!['review_count'] ?? 0,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_store!['description'] != null) ...[
                    const SizedBox(height: 10),
                    Text(_store!['description'],
                        style:
                            Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: 'Products (${_products.length})'),
                      Tab(text: 'Reviews (${_reviews.length})'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [

            // ── Products tab ─────────────────────────────────────
            _products.isEmpty
                ? const EmptyState(
                    icon: CupertinoIcons.bag,
                    title: 'No products yet',
                    subtitle: "This store hasn't listed any products.",
                  )
                : Column(
                    children: [
                      // ── S7: Category filter chips ──────────────
                      if (_availableGroups.length > 1)
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            children: [
                              _CategoryChip(
                                label: 'All',
                                icon: '',
                                selected: _selectedParent == null,
                                onTap: () =>
                                    setState(() => _selectedParent = null),
                              ),
                              ...(_availableGroups.map((g) => _CategoryChip(
                                    label: g['label'] ?? '',
                                    icon: g['icon'] ?? '',
                                    selected: _selectedParent == g['slug'],
                                    onTap: () => setState(
                                        () => _selectedParent = g['slug']),
                                  ))),
                            ],
                          ),
                        ),
                      // ── Products grid ──────────────────────────
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? EmptyState(
                                icon: CupertinoIcons.bag,
                                title: 'No products in this category',
                                subtitle:
                                    'Try selecting a different category.',
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.primary,
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (_, i) {
                                    final p = _filteredProducts[i];
                        return GestureDetector(
                          onTap: () =>
                              context.go('/products/${p['id']}'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Stack(children: [
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                    child: AppNetworkImage(
                                      url: p['image'] ?? '',
                                      height: 140,
                                      width: double.infinity,
                                    ),
                                  ),
                                  if (p['is_on_sale'] == true)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (p['discount_percent'] as num? ?? 0) > 0
                                              ? '${(p['discount_percent'] as num).toStringAsFixed(0)}% OFF'
                                              : 'SALE',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Satoshi',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name'] ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (p['is_on_sale'] == true &&
                                          p['sale_price'] != null) ...[
                                        Text(
                                          'R${(p['price'] as num? ?? 0).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        Text(
                                          'R${(p['sale_price'] as num).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ] else
                                        PriceText(
                                          price: double.tryParse(
                                                  p['price']?.toString() ??
                                                      '0') ??
                                              0.0,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                                  },
                                ),
                              ),
                        ),
                    ],
                  ),

            // ── Reviews tab ──────────────────────────────────────
            _reviews.isEmpty
                ? const EmptyState(
                    icon: CupertinoIcons.star,
                    title: 'No reviews yet',
                    subtitle: 'Be the first to review this store.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      itemBuilder: (_, i) {
                        final r = _reviews[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r['buyer_name'] ?? 'User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  const Spacer(),
                                  StarRating(
                                    rating: double.tryParse(
                                            r['rating']?.toString() ??
                                                '0') ??
                                        0.0,
                                  ),
                                ],
                              ),
                              if (r['comment'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  r['comment'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Category filter chip ──────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
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
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          icon.isNotEmpty ? '$icon $label' : label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
