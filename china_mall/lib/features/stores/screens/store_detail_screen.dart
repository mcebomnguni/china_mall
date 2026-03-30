import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
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
  List _products  = [];
  List _reviews   = [];
  bool _loading   = true;
  bool _loadError = false;
  late TabController _tabCtrl;
 
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
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
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
