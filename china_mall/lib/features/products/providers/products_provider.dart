import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
 
class ProductsProvider extends ChangeNotifier {
  List<dynamic> _products   = [];
  List<dynamic> _featured   = [];
  List<dynamic> _trending   = [];
  List<dynamic> _categories = [];
  bool          _loading    = false;
  bool          _loadingMore = false;
  bool          _hasMore    = true;
  int           _page       = 1;
  String?       _error;
  String?       _selectedCategory;
  String        _searchQuery = '';
  String        _ordering    = '';
 
  // ── Getters ────────────────────────────────────────────────────────────────
 
  List<dynamic> get products      => _products;
  List<dynamic> get featured      => _featured;
  List<dynamic> get trending      => _trending;
  List<dynamic> get categories    => _categories;
  bool          get loading       => _loading;
  bool          get loadingMore   => _loadingMore;
  bool          get hasMore       => _hasMore;
  String?       get error         => _error;
  String?       get selectedCategory => _selectedCategory;
  String        get searchQuery   => _searchQuery;
  String        get ordering      => _ordering;
 
  // ── Categories ─────────────────────────────────────────────────────────────
 
  Future<void> loadCategories() async {
    final res = await ApiService.getCategories();
    if (res.isSuccess) {
      _categories = res.data as List? ?? [];
      notifyListeners();
    }
  }
 
  // ── Products — initial load ────────────────────────────────────────────────
 
  Future<void> loadProducts({
    String? category,
    String? search,
    String? ordering,
    bool    silent = false,
  }) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
 
    // Reset pagination on a fresh load.
    _page    = 1;
    _hasMore = true;
 
    if (category != null) _selectedCategory = category;
    if (search   != null) _searchQuery      = search;
    if (ordering != null) _ordering         = ordering;
 
    final res = await ApiService.getProducts(
      category: _selectedCategory,
      search:   _searchQuery.isEmpty ? null : _searchQuery,
      ordering: _ordering.isEmpty    ? null : _ordering,
      page:     _page,
    );
 
    _loading = false;
 
    if (res.isSuccess) {
      final data = res.data;
      _products = _extractItems(data);
      _hasMore  = _hasNextPage(data);
      _error    = null;
    } else {
      _error = res.errorMessage;
    }
    notifyListeners();
  }
 
  // ── Products — load next page ──────────────────────────────────────────────
 
  Future<void> loadMoreProducts() async {
    if (_loadingMore || !_hasMore) return;
 
    _loadingMore = true;
    _page++;
    notifyListeners();
 
    final res = await ApiService.getProducts(
      category: _selectedCategory,
      search:   _searchQuery.isEmpty ? null : _searchQuery,
      ordering: _ordering.isEmpty    ? null : _ordering,
      page:     _page,
    );
 
    _loadingMore = false;
 
    if (res.isSuccess) {
      final data = res.data;
      _products.addAll(_extractItems(data));
      _hasMore = _hasNextPage(data);
    }
    // Don't set _error on loadMore failure — keep existing results.
    notifyListeners();
  }
 
  // ── Featured / Trending ────────────────────────────────────────────────────
 
  Future<void> loadFeatured() async {
    final results = await Future.wait([
      ApiService.getFeaturedProducts(),
      ApiService.getTrendingProducts(),
    ]);
    _featured = results[0].isSuccess
        ? (results[0].data as List? ?? [])
        : [];
    _trending = results[1].isSuccess
        ? (results[1].data as List? ?? [])
        : [];
    notifyListeners();
  }
 
  // ── Filters ────────────────────────────────────────────────────────────────
 
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery      = '';
    _ordering         = '';
    loadProducts();
  }
 
  // ── Single product ─────────────────────────────────────────────────────────
 
  Future<Map?> getProduct(int id) async {
    final res = await ApiService.getProduct(id);
    return res.isSuccess ? res.data : null;
  }
 
  // ── Reviews ────────────────────────────────────────────────────────────────
 
  Future<bool> postReview(
      int productId, int rating, String comment) async {
    final res = await ApiService.postProductReview(productId, {
      'rating':  rating,
      'comment': comment,
    });
    return res.isSuccess;
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
  List _extractItems(dynamic data) {
    if (data == null) return [];
    if (data is Map) return (data['results'] ?? data) as List? ?? [];
    return data as List? ?? [];
  }
 
  bool _hasNextPage(dynamic data) =>
      data is Map && data['next'] != null;
}