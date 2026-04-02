import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/mock_trends.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _heroPageController;
  int _currentHeroPage = 0;
  int _selectedHashtagIndex = 0;

  // Animation controllers
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _chipSlideController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _heroPageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _chipSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController.forward();
    _chipSlideController.forward();

    // Auto-scroll hero banner
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final nextPage =
          (_currentHeroPage + 1) % trendingCollections.length;
      _heroPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroPageController.dispose();
    _fadeController.dispose();
    _chipSlideController.dispose();
    super.dispose();
  }

  List<TrendingProduct> get _filteredProducts {
    if (_selectedHashtagIndex == 0) return trendingProducts;
    final tag = trendHashtags[_selectedHashtagIndex];
    return trendingProducts
        .where((p) => p.hashtag.toLowerCase() == tag.toLowerCase() ||
            '#${p.brandName}'.toLowerCase() == tag.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) => [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHeroBanner()),
            SliverToBoxAdapter(child: _buildTabBar()),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTrendingPicksTab(),
              _buildTrendingStoresTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Trends',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: LucideIcons.search,
            onTap: () => context.go('/search'),
          ),
          const SizedBox(width: 10),
          _HeaderIconButton(
            icon: LucideIcons.heart,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _heroPageController,
              itemCount: trendingCollections.length,
              onPageChanged: (i) => setState(() => _currentHeroPage = i),
              itemBuilder: (context, index) {
                final collection = trendingCollections[index];
                return _buildHeroCard(collection);
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildDotIndicators(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeroCard(TrendCollection collection) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: collection.heroImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.border),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.border),
            ),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: NEW badge + countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (collection.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${collection.countdownDays}',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'DAYS',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Hashtag title
                  Text(
                    collection.hashtag,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Featured product thumbnails
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: collection.featuredProducts
                          .map((p) => _buildFeaturedThumb(p))
                          .toList(),
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

  Widget _buildFeaturedThumb(TrendProduct product) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.image,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerBox(
                  width: 50, height: 50, radius: 8),
              errorWidget: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'R${product.price.toInt()}',
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            product.store,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(trendingCollections.length, (i) {
        final isActive = i == _currentHeroPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Trending Picks'),
          Tab(text: 'Trending Stores'),
        ],
      ),
    );
  }

  // ── Trending Picks Tab ──────────────────────────────────────────────────────

  Widget _buildTrendingPicksTab() {
    final products = _filteredProducts;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHashtagChips()),
        products.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.searchX,
                          size: 40, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text(
                        'No products found for this tag',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.48,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _AnimatedProductCard(
                        index: index,
                        product: products[index],
                        onTap: () =>
                            context.go('/products/$index'),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
      ],
    );
  }

  // ── Hashtag Chips ───────────────────────────────────────────────────────────

  Widget _buildHashtagChips() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _chipSlideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(top: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: trendHashtags.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isActive = index == _selectedHashtagIndex;
            final tag = trendHashtags[index];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedHashtagIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0 && isActive) ...[
                      Icon(LucideIcons.sparkles,
                          size: 12, color: AppColors.accent),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      tag,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Trending Stores Tab ─────────────────────────────────────────────────────

  Widget _buildTrendingStoresTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: mockStores.length,
      itemBuilder: (context, index) {
        final store = mockStores[index];
        return _buildStoreCard(store, index);
      },
    );
  }

  Widget _buildStoreCard(MockStoreDetail store, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => context.go('/stores/${store.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: AppNetworkImage(
                  url: store.bannerImage,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (store.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.badgeCheck,
                                    size: 12, color: AppColors.accent),
                                const SizedBox(width: 3),
                                const Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating + followers
                    Row(
                      children: [
                        StarRating(
                          rating: store.rating,
                          reviewCount: store.reviewCount,
                          size: 12,
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.users,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          _formatFollowers(store.followers),
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.package,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${store.productCount} items',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Location
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.location,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Visit Store button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () =>
                            context.go('/stores/${store.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Visit Store',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k followers';
    }
    return '$count followers';
  }
}

// ── Animated Product Card ───────────────────────────────────────────────────

class _AnimatedProductCard extends StatelessWidget {
  final int index;
  final TrendingProduct product;
  final VoidCallback onTap;

  const _AnimatedProductCard({
    required this.index,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _ProductCard(product: product, onTap: onTap),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final TrendingProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with overlays
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFF5F5F5),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.textTertiary),
                    ),
                  ),
                  // Bottom gradient for brand name
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
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Brand name overlay
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Text(
                      product.brandName.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // Color variant dots
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: product.colorVariants.map((color) {
                        return Container(
                          margin: const EdgeInsets.only(left: 3),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Trend tag row
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary, width: 1),
                      ),
                      child: const Text(
                        'trends',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${product.hashtag} >',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Discount + time left
                Text(
                  '${product.discount}% | Last ${product.hoursLeft} hrs',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE85D3A),
                  ),
                ),
                const SizedBox(height: 3),
                // Product name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Price row + cart button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'R${product.price.toInt()}',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Text(
                            'Estimated',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        LucideIcons.shoppingCart,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Icon Button ──────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
