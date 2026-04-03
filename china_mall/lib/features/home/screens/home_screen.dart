import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/mock_trends.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List _featured = [];
  List _trending = [];
  List _stores = [];
  bool _loading = true;

  // Banner carousel
  final PageController _bannerController = PageController();
  int _bannerIdx = 0;
  Timer? _bannerTimer;


  @override
  void initState() {
    super.initState();
    _load();
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIdx + 1) % 3;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final r = await Future.wait([
        ApiService.getFeaturedProducts(),
        ApiService.getTrendingProducts(),
        ApiService.getFeaturedStores(),
      ]);
      if (!mounted) return;

      setState(() {
        _featured = r[0].isSuccess
            ? (r[0].data is List
                ? List.from(r[0].data)
                : List.from(r[0].data['results'] ?? []))
            : [];

        _trending = r[1].isSuccess
            ? (r[1].data is List
                ? List.from(r[1].data)
                : List.from(r[1].data['results'] ?? []))
            : [];

        _stores = r[2].isSuccess
            ? (r[2].data is List
                ? List.from(r[2].data)
                : List.from(r[2].data['results'] ?? []))
            : [];

        // Fallback to mock data when API returns empty
        if (_featured.isEmpty) _featured = List.from(mockFeaturedProducts);
        if (_trending.isEmpty) _trending = List.from(mockTrendingProducts);
        if (_stores.isEmpty) {
          _stores = mockStores
              .map((s) => {
                    'id': s.id,
                    'name': s.name,
                    'location': s.location,
                    'rating': s.rating,
                    'review_count': s.reviewCount,
                    'is_verified': s.isVerified,
                    'description': s.description,
                    'logo': null,
                  })
              .toList();
        }

        _loading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // Use mock data on error as well
          if (_featured.isEmpty) _featured = List.from(mockFeaturedProducts);
          if (_trending.isEmpty) _trending = List.from(mockTrendingProducts);
          if (_stores.isEmpty) {
            _stores = mockStores
                .map((s) => {
                      'id': s.id,
                      'name': s.name,
                      'location': s.location,
                      'rating': s.rating,
                      'review_count': s.reviewCount,
                      'is_verified': s.isVerified,
                      'description': s.description,
                      'logo': null,
                    })
                .toList();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load content. Pull down to retry.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName =
        auth.user?['first_name'] ?? auth.user?['username'] ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // -- Header: avatar + greeting + bell --
              SliverToBoxAdapter(child: _buildHeader(firstName)),

              // -- Search bar --
              SliverToBoxAdapter(child: _buildSearchBar()),

              // -- Banner carousel --
              SliverToBoxAdapter(child: _buildBannerCarousel()),

              // -- Categories --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: SectionLabel(
                    title: 'Categories',
                    actionLabel: 'All',
                    onAction: () => context.go('/products'),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategories()),

              // -- Featured --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: SectionLabel(
                    title: 'Featured',
                    actionLabel: 'See all',
                    onAction: () => context.go('/products'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _loading
                    ? _buildProductShimmer()
                    : _buildProductRow(_featured),
              ),

              // -- Trending --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: SectionLabel(
                    title: 'Trending',
                    actionLabel: 'See all',
                    onAction: () =>
                        context.go('/products?ordering=-sales_count'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _loading
                    ? _buildProductShimmer()
                    : _buildProductRow(_trending),
              ),

              // -- Top Stores --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: SectionLabel(
                    title: 'Top Stores',
                    actionLabel: 'All stores',
                    onAction: () => context.go('/stores'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _loading
                    ? _buildStoreShimmer()
                    : _buildStoreRow(),
              ),

              // -- Bottom padding for floating nav bar --
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(String firstName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back,',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(LucideIcons.bell, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(LucideIcons.search, size: 16, color: AppColors.textTertiary),
              SizedBox(width: 10),
              Text(
                'Search products & stores...',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner carousel ─────────────────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    final banners = [
      _BannerData(
        title: 'China Mall\nMega Deals',
        subtitle: 'Up to 70% Off',
        gradient: AppColors.promoBannerGradient,
        buttonLabel: 'Shop Now',
      ),
      _BannerData(
        title: 'New Arrivals',
        subtitle: 'Fresh Styles from Top Stores',
        gradient: AppColors.gradientBlack,
        buttonLabel: 'Explore',
      ),
      _BannerData(
        title: 'Free Delivery\nOver R750',
        subtitle: 'All Malls',
        gradient: AppColors.primaryGradient,
        buttonLabel: 'Order Now',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _bannerIdx = i),
              itemCount: banners.length,
              itemBuilder: (_, i) {
                final b = banners[i];
                return GestureDetector(
                  onTap: () => context.go('/products'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: b.gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                b.title,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b.subtitle,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  b.buttonLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
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
              },
            ),
          ),
          const SizedBox(height: 12),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final isActive = i == _bannerIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: isActive ? 24 : 8,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Categories ──────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.categories.length,
        itemBuilder: (_, i) {
          final cat = AppConstants.categories[i];
          final iconData = AppConstants.categoryIcon(cat['slug']!);
          return Pressable(
            scaleFactor: 0.95,
            onTap: () => context.go('/products?category=${cat['slug']}'),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(iconData, size: 28, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label']!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: 40 * i))
              .fadeIn(duration: 250.ms, curve: Curves.easeOutCubic)
              .slideX(begin: 0.15, end: 0, duration: 250.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  // ── Product shimmer placeholder ─────────────────────────────────────────────
  Widget _buildProductShimmer() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ShimmerBox(width: 150, height: 210, radius: 12),
        ),
      ),
    );
  }

  // ── Store shimmer placeholder ───────────────────────────────────────────────
  Widget _buildStoreShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ShimmerBox(width: 120, height: 130, radius: 12),
        ),
      ),
    );
  }

  // ── Horizontal product row with staggered fade-in ───────────────────────────
  Widget _buildProductRow(List products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        itemBuilder: (_, i) {
          return Pressable(
            scaleFactor: 0.97,
            onTap: () => context.go('/products/${products[i]['id']}'),
            child: _ProductCard(
              product: products[i],
              onTap: () => context.go('/products/${products[i]['id']}'),
            ),
          )
              .animate(delay: Duration(milliseconds: 50 * i))
              .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
              .scaleXY(begin: 0.96, end: 1.0, duration: 350.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  // ── Horizontal store row ────────────────────────────────────────────────────
  Widget _buildStoreRow() {
    if (_stores.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _stores.length,
        itemBuilder: (_, i) {
          final s = _stores[i];
          return Pressable(
            scaleFactor: 0.97,
            onTap: () => context.go('/stores/${s['id']}'),
            child: _StoreCard(
              store: s,
              onTap: () => context.go('/stores/${s['id']}'),
            ),
          )
              .animate(delay: Duration(milliseconds: 50 * i))
              .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
              .slideX(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

// ── Banner data ──────────────────────────────────────────────────────────────
class _BannerData {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final String buttonLabel;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.buttonLabel,
  });
}

// ── Product card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final discount = (product['discount'] ?? 0) as num;
    final price = (product['price'] ?? 0);
    final imageUrl = product['image'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge + Hero animation
            Stack(
              children: [
                Hero(
                  tag: 'product-image-${product['id']}',
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl != null && imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 150,
                            height: 130,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 150,
                              height: 130,
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(CupertinoIcons.photo,
                                    color: Color(0xFFCCCCCC)),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 150,
                              height: 130,
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(CupertinoIcons.photo,
                                    color: Color(0xFFCCCCCC)),
                              ),
                            ),
                          )
                        : Container(
                            width: 150,
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: AssetImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null
                                ? const Center(
                                    child: Icon(CupertinoIcons.photo,
                                        color: Color(0xFFCCCCCC)))
                                : null,
                          ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${discount.toInt()}%',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R${price is double ? price.toStringAsFixed(0) : price.toString()}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.primary,
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
}

// ── Store card ───────────────────────────────────────────────────────────────
class _StoreCard extends StatelessWidget {
  final Map store;
  final VoidCallback onTap;
  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = store['name'] ?? 'Store';
    final location = store['location'] ?? 'China Mall';
    final rating = (store['rating'] ?? 4.5) as num;
    // Extract short location from full address
    String shortLocation = 'China Mall';
    if (location is String && location.contains('-')) {
      final parts = location.split('-');
      if (parts.length >= 2) {
        shortLocation = parts.last.trim();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Store initial circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              shortLocation,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.star, size: 12, color: AppColors.starRating),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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
