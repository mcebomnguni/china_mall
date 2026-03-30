import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/skeleton_widgets.dart';
import '../../cart/providers/cart_provider.dart';
 
class ProductDetailScreen extends StatefulWidget {
  final int id;
  const ProductDetailScreen({super.key, required this.id});
 
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}
 
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map?  _product;
  List  _reviews      = [];
  bool  _loading      = true;
  int   _qty          = 1;
  bool  _showAllReviews = false; // toggle for "see all reviews"
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getProduct(widget.id),
      ApiService.getProductReviews(widget.id),
    ]);
    if (!mounted) return;
    setState(() {
      _product  = results[0].isSuccess ? results[0].data : null;
      _reviews  = results[1].isSuccess
          ? (results[1].data as List? ?? [])
          : [];
      _loading  = false;
    });
  }
 
  // ── Add to cart ────────────────────────────────────────────────────────────
 
  void _addToCart() {
    if (_product == null) return;
    final cart = context.read<CartProvider>();
    cart.addItem(CartItem(
      productId:  _product!['id'],
      name:       _product!['name'],
      image:      _product!['image'] ?? '',
      price:      (_product!['price'] ?? 0).toDouble(),
      quantity:   _qty,
      storeId:    _product!['store']?['id'] ?? 0,
      storeName:  _product!['store']?['name'] ?? '',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!['name']} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: ProductDetailSkeleton());
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'Product not found',
          subtitle: 'This product may have been removed.',
        ),
      );
    }
 
    final price   = (_product!['price'] ?? 0).toDouble();
    final inStock = (_product!['stock_quantity'] ?? 0) > 0;
    final related = _product!['related_products'] as List? ?? [];
 
    // Respect "see all" toggle — show 3 by default.
    final visibleReviews =
        _showAllReviews ? _reviews : _reviews.take(3).toList();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
 
          // ── Image AppBar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/products');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8)
                    ],
                  ),
                  child: const Icon(CupertinoIcons.back,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                url: _product!['image'],
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
              ),
            ),
          ),
 
          // ── Content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
 
                        // Category pill
                        if (_product!['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _product!['category']['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
 
                        Text(
                          _product!['name'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium,
                        ),
                        const SizedBox(height: 8),
 
                        Row(
                          children: [
                            PriceText(price: price, large: true),
                            const Spacer(),
                            if (_product!['average_rating'] != null)
                              StarRating(
                                rating: (_product!['average_rating'] ??
                                        0)
                                    .toDouble(),
                                reviewCount:
                                    _product!['review_count'],
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
 
                        // Store card
                        if (_product!['store'] != null)
                          GestureDetector(
                            onTap: () => context.go(
                                '/stores/${_product!['store']['id']}'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  AppNetworkImage(
                                    url: _product!['store']['logo'],
                                    width: 40,
                                    height: 40,
                                    radius: 10,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _product!['store']
                                                  ['name'] ??
                                              '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        const Text('View store',
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 12,
                                              color: AppColors.primary,
                                            )),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          ),
 
                        const SizedBox(height: 20),
 
                        // Description
                        Text('Description',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          _product!['description'] ??
                              'No description.',
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
 
                        // Stock status
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: inStock
                                    ? AppColors.success
                                    : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              inStock
                                  ? '${_product!['stock_quantity']} in stock'
                                  : 'Out of stock',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: inStock
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
 
                  // ── Reviews ────────────────────────────────────────
                  if (_reviews.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Reviews (${_reviews.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Spacer(),
                              // "See all" only appears when there are
                              // more than 3 reviews.
                              if (_reviews.length > 3)
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _showAllReviews =
                                          !_showAllReviews),
                                  child: Text(
                                    _showAllReviews
                                        ? 'Show less'
                                        : 'See all ${_reviews.length}',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...visibleReviews.map(
                            (r) => Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.border),
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
                                        rating: (r['rating'] ?? 0)
                                            .toDouble(),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
 
                  // ── Related products ───────────────────────────────
                  if (related.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'You may also like',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: related.length,
                        itemBuilder: (_, i) {
                          final rp = related[i] as Map;
                          return GestureDetector(
                            onTap: () => context
                                .go('/products/${rp['id']}'),
                            child: Container(
                              width: 140,
                              margin:
                                  const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.border),
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
                                      url: rp['image'],
                                      width: 140,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rp['name'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'R ${(rp['price'] ?? 0).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight:
                                                FontWeight.w900,
                                            fontSize: 13,
                                            color: AppColors.black,
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
                  ],
 
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
 
      // ── Bottom bar ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            QuantityStepper(
              value: _qty,
              onChanged: (v) => setState(() => _qty = v),
              max: _product!['stock_quantity'] ?? 99,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: inStock ? 'Add to Cart' : 'Out of Stock',
                onTap: inStock ? _addToCart : null,
                icon: CupertinoIcons.cart_badge_plus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
