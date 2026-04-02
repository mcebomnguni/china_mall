import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/providers/auth_provider.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  List _featured = [];
  List _trending = [];
  List _stores   = [];
  bool _loading  = true;
  int _bannerIdx = 0;
 
  @override
  void initState() { super.initState(); _load(); }
 
  Future<void> _load() async {
  setState(() => _loading = true);
  try {
    final r = await Future.wait([
      ApiService.getFeaturedProducts(),
      ApiService.getTrendingProducts(),
      ApiService.getFeaturedStores(),
    ]);
    if (!mounted) return;
 
    setState(() {
      // Handle both Map with results or direct List
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
 
      _loading = false;
    });
  } catch (e) {
    if (mounted) {
      setState(() => _loading = false);
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
    final auth      = context.watch<AuthProvider>();
    final firstName = auth.user?['first_name'] ?? auth.user?['username'] ?? 'there';
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.black,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── Top bar with avatar + greeting + notification ─────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      // Avatar circle
                      Container(
                        width: 40, height: 40,
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
                                fontFamily: 'Satoshi', fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              firstName,
                              style: const TextStyle(
                                fontFamily: 'Satoshi', fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notifications
                      GestureDetector(
                        onTap: () => context.go('/notifications'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(LucideIcons.bell, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              // ── Search bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: const [
                          Icon(CupertinoIcons.search, size: 16, color: AppColors.textTertiary),
                          SizedBox(width: 10),
                          Text(
                            'Search products & stores...',
                            style: TextStyle(
                              fontFamily: 'Satoshi', fontSize: 13,
                              fontWeight: FontWeight.w500, color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
 
              // ── Banner carousel ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 150,
                          viewportFraction: 0.88,
                          enableInfiniteScroll: true,
                          autoPlay: true,
                          onPageChanged: (i, _) => setState(() => _bannerIdx = i),
                        ),
                        items: [
  _BannerCard(
    title: 'New Arrivals',
    subtitle: 'Fresh styles from top stores',
    gradient: AppColors.gradientBlack,
    onTap: () => context.go('/products'),
  ),
  _BannerCard(
    title: 'Top Deals',
    subtitle: 'Save big on trending items',
    gradient: AppColors.gradientStore,
    onTap: () => context.go('/products'),
  ),
  _BannerCard(
    title: 'Free Delivery',
    subtitle: 'On orders over R750',
    gradient: AppColors.gradientAdmin,
    onTap: () => context.go('/products'),
  ),
],
                      ),
                      const SizedBox(height: 10),
                      AnimatedSmoothIndicator(
                        activeIndex: _bannerIdx,
                        count: 3,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.black,
                          dotColor: Color(0xFFDDDDDD),
                          dotHeight: 5, dotWidth: 5,
                          expansionFactor: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              // ── Categories ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: SectionLabel(
                    title: 'Categories',
                    actionLabel: 'All',
                    onAction: () => context.go('/products'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppConstants.categories.length,
                    itemBuilder: (_, i) {
                      final cat = AppConstants.categories[i];
                      final iconData = AppConstants.categoryIcon(cat['slug']!);
                      return GestureDetector(
                        onTap: () => context.go('/products?category=${cat['slug']}'),
                        child: Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 56, height: 56,
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
                                  fontFamily: 'Satoshi', fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
 
              // ── Activity log (featured products) ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: SectionLabel(
                    title: 'Featured',
                    actionLabel: 'See all',
                    onAction: () => context.go('/products'),
                  ),
                ),
              ),
 
              if (_loading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 3,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ShimmerBox(width: 150, height: 200, radius: 20),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _featured.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: _featured[i],
                        onTap: () => context.go('/products/${_featured[i]['id']}'),
                      ),
                    ),
                  ),
                ),
 
              // ── Trending ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: SectionLabel(
                    title: 'Trending',
                    actionLabel: 'See all',
                    onAction: () => context.go('/products?ordering=-sales_count'),
                  ),
                ),
              ),
              if (!_loading && _trending.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _trending.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: _trending[i],
                        onTap: () => context.go('/products/${_trending[i]['id']}'),
                      ),
                    ),
                  ),
                ),
 
              // ── Top Stores ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: SectionLabel(
                    title: 'Top Stores',
                    actionLabel: 'All stores',
                    onAction: () => context.go('/stores'),
                  ),
                ),
              ),
              if (!_loading && _stores.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final s = _stores[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: OsCard(
                          onTap: () => context.go('/stores/${s['id']}'),
                          child: Row(
                            children: [
                              AppNetworkImage(url: s['logo'], width: 48, height: 48, radius: 14),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['name'] ?? '', style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 14)),
                                    if (s['description'] != null)
                                      Text(s['description'], style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _stores.take(5).length,
                  ),
                ),
 
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ── Banner card ───────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final String title, subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _BannerCard({required this.title, required this.subtitle, required this.gradient, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Shop Now',
                      style: TextStyle(fontFamily: 'Satoshi', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
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
 
// ── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AppNetworkImage(url: product['image'], width: 150, height: 130),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? '', style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('R ${(product['price'] ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
