import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../constants/product_images.dart';
import '../../../data/mock_trends.dart';

class StoreDetailScreen extends StatefulWidget {
  final int id;
  const StoreDetailScreen({super.key, required this.id});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with TickerProviderStateMixin {
  Map? _store;
  List _products = [];
  List _reviews = [];
  bool _loading = true;
  bool _loadError = false;
  bool _isFollowed = false;
  bool _isLiked = false;
  String _activeFilter = 'All';
  final Set<int> _likedProducts = {};

  // Stats count-up animation
  late AnimationController _statsAnimCtrl;
  late Animation<double> _statsAnim;

  // Bottom bar button press states
  bool _followPressed = false;
  bool _messagePressed = false;

  MockStoreDetail? get _mockStore {
    try {
      return mockStores.firstWhere((s) => s.id == widget.id);
    } catch (_) {
      return mockStores.isNotEmpty ? mockStores.first : null;
    }
  }

  final List<String> _filterLabels = [
    'All',
    'New Arrivals',
    'On Sale',
    'Jackets',
    'Tops',
    'Dresses',
    'Shoes',
    'Accessories',
  ];

  List get _filteredProducts {
    if (_activeFilter == 'All') return _products;
    if (_activeFilter == 'New Arrivals') {
      return _products.where((p) => p['is_new'] == true).toList();
    }
    if (_activeFilter == 'On Sale') {
      return _products.where((p) => p['is_on_sale'] == true).toList();
    }
    // Filter by category name or parent group match
    return _products.where((p) {
      final catName =
          (p['category']?['name'] ?? p['category']?['slug'] ?? '')
              .toString()
              .toLowerCase();
      final slug = p['category']?['slug']?.toString() ?? '';
      final parent = AppConstants.categoryParent(slug);
      return catName.contains(_activeFilter.toLowerCase()) ||
          (parent != null && parent.toLowerCase().contains(_activeFilter.toLowerCase()));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _statsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _statsAnim = CurvedAnimation(
      parent: _statsAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _statsAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
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

        // Products
        if (results[1].isSuccess) {
          final data = results[1].data;
          _products = data is Map
              ? (data['results'] as List? ?? [])
              : (data as List? ?? []);
        }

        // Reviews
        if (results[2].isSuccess) {
          final data = results[2].data;
          _reviews = data is Map
              ? (data['results'] as List? ?? [])
              : (data as List? ?? []);
        }

        _loading = false;
      });

      _statsAnimCtrl.forward();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  // Helpers to get store data with mock fallback
  String get _storeName =>
      _store?['name'] ?? _mockStore?.name ?? 'Store';
  String get _storeLocation =>
      _store?['location'] ??
      _store?['address'] ??
      _mockStore?.location ??
      '';
  String get _storeBanner =>
      _store?['banner'] ?? _mockStore?.bannerImage ?? '';
  String get _storeDescription =>
      _store?['description'] ?? _mockStore?.description ?? '';
  double get _storeRating =>
      double.tryParse(_store?['average_rating']?.toString() ?? '') ??
      _mockStore?.rating ??
      0.0;
  int get _storeReviewCount =>
      _store?['review_count'] ?? _mockStore?.reviewCount ?? _reviews.length;
  bool get _storeIsVerified =>
      _store?['is_verified'] == true || (_mockStore?.isVerified ?? false);
  int get _storeFollowers => _mockStore?.followers ?? 0;
  int get _storeProductCount =>
      _products.isNotEmpty ? _products.length : (_mockStore?.productCount ?? 0);
  int get _storePositiveRate => _mockStore?.positiveRate ?? 95;

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000.0;
      return '${k.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildShimmer();

    if (_loadError && _store == null) return _buildError();

    if (_store == null && _mockStore == null) return _buildNotFound();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Banner with overlay header
              SliverToBoxAdapter(child: _buildBanner()),
              // Store info section
              SliverToBoxAdapter(child: _buildStoreInfo()),
              // Filter chips
              SliverToBoxAdapter(child: _buildFilterChips()),
              // Product grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                sliver: _filteredProducts.isEmpty
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: 300,
                          child: EmptyState(
                            icon: LucideIcons.package,
                            title: 'No products found',
                            subtitle: 'Try selecting a different filter.',
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) =>
                              _buildProductCard(_filteredProducts[i]),
                          childCount: _filteredProducts.length,
                        ),
                      ),
              ),
            ],
          ),
          // Sticky bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading ──────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: double.infinity, height: 220, radius: 0),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 200, height: 28),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: 260, height: 14),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: 180, height: 14),
                  const SizedBox(height: 20),
                  const ShimmerBox(width: double.infinity, height: 40),
                  const SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      3,
                      (_) => const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ShimmerBox(width: double.infinity, height: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ShimmerBox(width: 80, height: 34, radius: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: ShimmerBox(
                              width: double.infinity, height: 240)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ShimmerBox(
                              width: double.infinity, height: 240)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
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
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Not found state ──────────────────────────────────────────────────────────
  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: EmptyState(
        icon: LucideIcons.store,
        title: 'Store not found',
        subtitle: 'This store may no longer be available.',
      ),
    );
  }

  // ── Banner with header overlay ───────────────────────────────────────────────
  Widget _buildBanner() {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Banner image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: _storeBanner.isNotEmpty
                  ? _storeBanner
                  : 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.border),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.border,
                child: const Center(
                  child: Icon(LucideIcons.image, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          // Dark gradient overlay bottom 40%
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220 * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Header icons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _HeaderIconButton(
                  icon: LucideIcons.arrowLeft,
                  color: AppColors.primary,
                  bgColor: Colors.white,
                  shadow: true,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: LucideIcons.share2,
                      color: Colors.white,
                      bgColor: Colors.black.withValues(alpha: 0.4),
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconButton(
                      icon: LucideIcons.heart,
                      color: _isLiked ? AppColors.primary : Colors.white,
                      bgColor: Colors.black.withValues(alpha: 0.4),
                      onTap: () => setState(() => _isLiked = !_isLiked),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // "CS" branded badge
          Positioned(
            bottom: -1,
            left: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'CS',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Store info section ───────────────────────────────────────────────────────
  Widget _buildStoreInfo() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name
          Text(
            _storeName,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Location row
          if (_storeLocation.isNotEmpty)
            Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _storeLocation,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          // Rating row with verified badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Icon(LucideIcons.star,
                  size: 15, color: AppColors.warning),
              Text(
                _storeRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '($_storeReviewCount reviews)',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              if (_storeIsVerified)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.badgeCheck,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      const Text(
                        'Verified Store',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Description
          if (_storeDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _storeDescription,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Stats row
          AnimatedBuilder(
            animation: _statsAnim,
            builder: (context, _) {
              final t = _statsAnim.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildStat(
                      _formatCount((_storeFollowers * t).round()),
                      'Followers',
                    ),
                    _statDivider(),
                    _buildStat(
                      '${(_storeProductCount * t).round()}',
                      'Products',
                    ),
                    _statDivider(),
                    _buildStat(
                      '${(_storePositiveRate * t).round()}%',
                      'Positive',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: AppColors.surface,
      child: SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filterLabels.length + 1, // +1 for Sort chip
          itemBuilder: (context, i) {
            if (i == _filterLabels.length) {
              // Sort chip
              return GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.arrowUpDown,
                          size: 13, color: AppColors.textPrimary),
                      const SizedBox(width: 5),
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final label = _filterLabels[i];
            final isActive = _activeFilter == label;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = label),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Product card ─────────────────────────────────────────────────────────────
  Widget _buildProductCard(dynamic p) {
    final productId = p['id'];
    final isOnSale = p['is_on_sale'] == true;
    final isNew = p['is_new'] == true;
    final name = p['name'] ?? 'Product';
    final imageUrl = p['image'] ?? '';
    final price = (p['price'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (p['sale_price'] as num?)?.toDouble();
    final rating =
        double.tryParse(p['average_rating']?.toString() ?? '') ?? 4.7;
    final isProductLiked = _likedProducts.contains(productId);

    return GestureDetector(
      onTap: () => context.go('/products/$productId'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl.isNotEmpty
                          ? imageUrl
                          : ProductImages.leatherJacket,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFF5F5F5)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Center(
                          child: Icon(LucideIcons.image,
                              color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  // Badge: SALE or NEW
                  if (isOnSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  else if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  // Heart icon top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isProductLiked) {
                            _likedProducts.remove(productId);
                          } else {
                            _likedProducts.add(productId);
                          }
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          size: 15,
                          color: isProductLiked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Rating
                        Row(
                          children: [
                            Icon(LucideIcons.star,
                                size: 12, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Price row
                        Row(
                          children: [
                            if (isOnSale && salePrice != null) ...[
                              Text(
                                'R${salePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'R${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textTertiary,
                                ),
                              ),
                            ] else
                              Text(
                                'R${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Add to cart button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shoppingCart,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sticky bottom bar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Follow button - outlined, 40% width
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _followPressed = true),
              onTapUp: (_) {
                setState(() {
                  _followPressed = false;
                  _isFollowed = !_isFollowed;
                });
              },
              onTapCancel: () => setState(() => _followPressed = false),
              child: AnimatedScale(
                scale: _followPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isFollowed
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.heart,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFollowed ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Message Store button - solid red, 60% width
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _messagePressed = true),
              onTapUp: (_) => setState(() => _messagePressed = false),
              onTapCancel: () => setState(() => _messagePressed = false),
              child: AnimatedScale(
                scale: _messagePressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.messageCircle,
                          size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Message Store',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header icon button ─────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool shadow;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.shadow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
