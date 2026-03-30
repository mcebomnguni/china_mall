import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class ApiService {
  static const String _webBase = 'http://localhost:8000';
  static const String _mobileBase = 'http://192.168.18.3:8000';

  static String get baseUrl => kIsWeb ? _webBase : _mobileBase;

  static String? _token;

  static Future<void> loadToken() async {
    _token ??= await AuthService.getAccessToken();
  }

  static Future<void> setToken(String token) async {
    _token = token;
  }

  static Future<void> clearToken() async {
    _token = null;
  }

  static bool get isAuthenticated => _token != null;
  static String? get currentToken => _token;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.0.0',
        'X-Platform': kIsWeb ? 'web' : 'mobile',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<ApiResponse> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } on Exception catch (e) {
      return ApiResponse(0, {'error': _friendlyError(e)});
    }
  }

  static Future<ApiResponse> _post(String path, Map body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } on Exception catch (e) {
      return ApiResponse(0, {'error': _friendlyError(e)});
    }
  }

  static Future<ApiResponse> _put(String path, Map body) async {
    try {
      final res = await http
          .put(Uri.parse('$baseUrl$path'),
              headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } on Exception catch (e) {
      return ApiResponse(0, {'error': _friendlyError(e)});
    }
  }

  static Future<ApiResponse> _delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } on Exception catch (e) {
      return ApiResponse(0, {'error': _friendlyError(e)});
    }
  }

  static ApiResponse _parse(http.Response res) {
    try {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      return ApiResponse(res.statusCode, body);
    } catch (_) {
      return ApiResponse(res.statusCode, {'raw': res.body});
    }
  }

  static String _friendlyError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) return 'Request timed out. Please check your connection.';
    if (msg.contains('connection')) return 'Cannot connect. Is the server running?';
    if (msg.contains('socket')) return 'Network error. Please check your internet connection.';
    return 'Something went wrong. Please try again.';
  }

  static Future<T?> _safely<T>(Future<T> Function() action) async {
    try {
      if (!SupabaseService.isReady) return null;
      return await action();
    } catch (e) {
      if (kDebugMode) debugPrint('Supabase call failed: $e');
      return null;
    }
  }

  // Remaps a raw Supabase products row to the shape the UI expects.
  static Map<String, dynamic> _mapProductData(dynamic raw) {
    final p = Map<String, dynamic>.from(raw as Map);

    // Flatten product_images join → sorted URL list + first as 'image'
    final rawImages = p['product_images'];
    List<String> imageUrls = [];
    if (rawImages is List && rawImages.isNotEmpty) {
      final sorted = List<Map>.from(rawImages)
        ..sort((a, b) => (a['ordinal'] ?? 0).compareTo(b['ordinal'] ?? 0));
      imageUrls =
          sorted.where((e) => e['url'] != null).map((e) => e['url'] as String).toList();
    }
    p['image'] = imageUrls.isNotEmpty ? imageUrls.first : null;
    p['product_image_urls'] = imageUrls;

    // Flatten categories join
    final catJoin = p['categories'];
    if (catJoin is Map) p['category'] = catJoin;

    // Flatten stores join
    final storeJoin = p['stores'];
    if (storeJoin is Map) p['store'] = storeJoin;

    return p;
  }

  // ── Upload a single image to the product-images bucket ──────────────────
  static Future<String?> uploadProductImage(
      Uint8List bytes, String userId, String filename) async {
    if (!SupabaseService.isReady) return null;
    try {
      final path = '$userId/$filename';
      await SupabaseService.client.storage
          .from('product-images')
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(upsert: true));
      return SupabaseService.client.storage
          .from('product-images')
          .getPublicUrl(path);
    } catch (e) {
      if (kDebugMode) debugPrint('Image upload failed: $e');
      return null;
    }
  }

  // ── Config ───────────────────────────────────────────────────────────────
  static Future<ApiResponse> getAppConfig() => _get('/api/analytics/config/');

  // ── Auth ─────────────────────────────────────────────────────────────────
  static Future<ApiResponse> login(String username, String password) =>
      _post('/api/auth/login/', {'username': username, 'password': password});

  static Future<ApiResponse> register(Map<String, dynamic> data) =>
      _post('/api/auth/register/', data);

  static Future<ApiResponse> logout() async {
    await clearToken();
    return _post('/api/auth/logout/', {});
  }

  // ── Profile ──────────────────────────────────────────────────────────────
  static Future<ApiResponse> getProfile() async {
    final supabaseRes = await _safely(() async {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return null;
      return await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    });
    if (supabaseRes != null) return ApiResponse(200, supabaseRes);
    return _get('/api/auth/profile/');
  }

  static Future<ApiResponse> updateProfile(Map data) async {
    final updated = await _safely(() async {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return null;
      await SupabaseService.client
          .from('profiles')
          .update(data)
          .eq('id', user.id);
      return await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    });
    if (updated != null) return ApiResponse(200, updated);
    return _put('/api/auth/profile/', data);
  }

  static Future<ApiResponse> getBuyerProfile() => _get('/api/auth/profile/buyer/');

  static Future<ApiResponse> changePassword(String old, String nw, String confirm) =>
      _post('/api/auth/change-password/', {
        'old_password': old,
        'new_password': nw,
        'new_password_confirm': confirm,
      });

  // ── Stores ───────────────────────────────────────────────────────────────
  static Future<ApiResponse> getStores() async {
    final data = await _safely(() async => await SupabaseService.client
        .from('stores')
        .select('*, owner:profiles(full_name)'));
    if (data != null) return ApiResponse(200, data);
    return _get('/api/stores/');
  }

  static Future<ApiResponse> searchStores(String q) async {
    final data = await _safely(() async => await SupabaseService.client
        .from('stores')
        .select('*')
        .ilike('name', '%$q%'));
    if (data != null) return ApiResponse(200, data);
    return _get('/api/stores/search/?search=$q');
  }

  static Future<ApiResponse> getFeaturedStores() async {
    final data = await _safely(() async => await SupabaseService.client
        .from('stores')
        .select('*')
        .eq('is_featured', true));
    if (data != null) return ApiResponse(200, data);
    return _get('/api/stores/featured/');
  }

  static Future<ApiResponse> getStore(int id) async {
    final data = await _safely(() async => await SupabaseService.client
        .from('stores')
        .select('*')
        .eq('id', id)
        .maybeSingle());
    if (data != null) return ApiResponse(200, data);
    return _get('/api/stores/$id/');
  }

  static Future<ApiResponse> getStoreReviews(int id) async {
    final data = await _safely(() async => await SupabaseService.client
        .from('reviews')
        .select('*')
        .eq('store_id', id)
        .order('created_at', ascending: false));
    if (data != null) return ApiResponse(200, data);
    return _get('/api/stores/$id/reviews/');
  }

  static Future<ApiResponse> postStoreReview(int id, Map d) async {
    final data = await _safely(() async => await SupabaseService.client
        .from('reviews')
        .insert({...d, 'store_id': id})
        .select());
    if (data != null) return ApiResponse(201, data);
    return _post('/api/stores/$id/reviews/', d);
  }

  static Future<ApiResponse> getMyStore() => _get('/api/stores/my-store/');
  static Future<ApiResponse> updateMyStore(Map d) => _put('/api/stores/my-store/', d);
  static Future<ApiResponse> createStore(Map d) => _post('/api/stores/create/', d);
  static Future<ApiResponse> getPendingStores() => _get('/api/stores/pending/');
  static Future<ApiResponse> approveStore(int id, String action, {String? reason}) =>
      _post('/api/stores/$id/approval/',
          {'action': action, if (reason != null) 'reason': reason});

  // ── Categories ───────────────────────────────────────────────────────────
  static Future<ApiResponse> getCategories() async {
    final data = await _safely(() async => await SupabaseService.client
        .from('categories')
        .select('*')
        .order('id'));
    if (data != null) return ApiResponse(200, data);
    return _get('/api/products/categories/');
  }

  // ── Products (buyer browsing) ────────────────────────────────────────────
  static Future<ApiResponse> getProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String? ordering,
    int? page,
    int? limit,
  }) async {
    if (SupabaseService.isReady) {
      try {
        final products = await SupabaseService.client
            .from('products')
            .select('*, product_images(url, ordinal), categories(slug, label, icon), stores(id, name)')
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(limit ?? 60);

        var result =
            (products as List).map(_mapProductData).toList();

        // In-memory filters
        if (search != null && search.isNotEmpty) {
          result = result
              .where((p) => (p['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(search.toLowerCase()))
              .toList();
        }
        if (minPrice != null) {
          result = result
              .where((p) => ((p['price'] ?? 0) as num) >= minPrice)
              .toList();
        }
        if (maxPrice != null) {
          result = result
              .where((p) => ((p['price'] ?? 0) as num) <= maxPrice)
              .toList();
        }
        if (inStock == true) {
          result = result
              .where((p) => ((p['stock_quantity'] ?? 0) as num) > 0)
              .toList();
        }
        if (category != null && category.isNotEmpty) {
          result = result
              .where((p) => p['category']?['slug'] == category)
              .toList();
        }
        return ApiResponse(200, result);
      } catch (e) {
        if (kDebugMode) debugPrint('getProducts Supabase error: $e');
      }
    }
    final p = <String>[];
    if (category != null) p.add('category=$category');
    if (search != null) p.add('search=$search');
    if (minPrice != null) p.add('min_price=$minPrice');
    if (maxPrice != null) p.add('max_price=$maxPrice');
    if (inStock != null) p.add('in_stock=$inStock');
    if (ordering != null) p.add('ordering=$ordering');
    if (page != null) p.add('page=$page');
    if (limit != null) p.add('limit=$limit');
    return _get('/api/products/${p.isNotEmpty ? '?${p.join('&')}' : ''}');
  }

  static Future<ApiResponse> searchProducts(String q) async {
    if (SupabaseService.isReady) {
      try {
        final products = await SupabaseService.client
            .from('products')
            .select('*, product_images(url, ordinal), stores(id, name)')
            .eq('is_active', true)
            .ilike('name', '%$q%')
            .limit(40);
        return ApiResponse(200,
            (products as List).map(_mapProductData).toList());
      } catch (e) {
        if (kDebugMode) debugPrint('searchProducts error: $e');
      }
    }
    return _get('/api/products/search/?search=$q');
  }

  static Future<ApiResponse> getFeaturedProducts() async {
    final data = await _safely(() async {
      final products = await SupabaseService.client
          .from('products')
          .select('*, product_images(url, ordinal), stores(id, name)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(20);
      return (products as List).map(_mapProductData).toList();
    });
    if (data != null) return ApiResponse(200, data);
    return _get('/api/products/featured/');
  }

  static Future<ApiResponse> getTrendingProducts() async {
    final data = await _safely(() async {
      final products = await SupabaseService.client
          .from('products')
          .select('*, product_images(url, ordinal), stores(id, name)')
          .eq('is_active', true)
          .eq('is_on_sale', true)
          .order('created_at', ascending: false)
          .limit(20);
      return (products as List).map(_mapProductData).toList();
    });
    if (data != null) return ApiResponse(200, data);
    return _get('/api/products/trending/');
  }

  static Future<ApiResponse> getProductsByStore(int id) async {
    final data = await _safely(() async {
      final products = await SupabaseService.client
          .from('products')
          .select('*, product_images(url, ordinal), categories(slug, label, icon)')
          .eq('store_id', id)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (products as List).map(_mapProductData).toList();
    });
    if (data != null) return ApiResponse(200, data);
    return _get('/api/products/store/$id/');
  }

  static Future<ApiResponse> getProduct(int id) async {
    if (SupabaseService.isReady) {
      try {
        final product = await SupabaseService.client
            .from('products')
            .select(
                '*, product_images(url, ordinal), categories(slug, label, icon), stores(id, name, logo, slug)')
            .eq('id', id)
            .maybeSingle();
        if (product != null) return ApiResponse(200, _mapProductData(product));
      } catch (e) {
        if (kDebugMode) debugPrint('getProduct error: $e');
      }
    }
    return _get('/api/products/$id/');
  }

  static Future<ApiResponse> getProductReviews(int id) =>
      _get('/api/products/$id/reviews/');
  static Future<ApiResponse> postProductReview(int id, Map d) =>
      _post('/api/products/$id/reviews/', d);

  // ── Vendor product management ─────────────────────────────────────────────
  static Future<ApiResponse> getMyProducts() async {
    if (SupabaseService.isReady) {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return ApiResponse(401, {'error': 'Not logged in'});

        final store = await SupabaseService.client
            .from('stores')
            .select('id')
            .eq('owner', user.id)
            .maybeSingle();

        if (store == null) return ApiResponse(200, <dynamic>[]);

        final products = await SupabaseService.client
            .from('products')
            .select('*, product_images(url, ordinal), categories(slug, label, icon)')
            .eq('store_id', store['id'])
            .order('created_at', ascending: false);

        return ApiResponse(
            200, (products as List).map(_mapProductData).toList());
      } catch (e) {
        if (kDebugMode) debugPrint('getMyProducts error: $e');
      }
    }
    return _get('/api/products/vendor/');
  }

  static Future<ApiResponse> createProduct(Map d) async {
    if (SupabaseService.isReady) {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return ApiResponse(401, {'error': 'Not logged in'});

        final store = await SupabaseService.client
            .from('stores')
            .select('id')
            .eq('owner', user.id)
            .maybeSingle();

        if (store == null) {
          return ApiResponse(400,
              {'error': 'No store found. Please register your store first.'});
        }

        // Resolve category_id from slug
        int? categoryId;
        if (d['category'] != null) {
          final cat = await SupabaseService.client
              .from('categories')
              .select('id')
              .eq('slug', d['category'])
              .maybeSingle();
          categoryId = cat?['id'];
        }

        // Insert product row
        final product = await SupabaseService.client
            .from('products')
            .insert({
              'store_id': store['id'],
              'name': d['name'],
              'description': d['description'],
              'price': d['price'],
              'vendor_price': d['vendor_price'],
              'stock_quantity': d['stock_quantity'],
              'category_id': categoryId,
              'status': 'pending',
              'sizes': d['sizes'] ?? [],
              'dimensions': d['dimensions'] ?? {},
              'colours': d['colours'] ?? [],
              'fabric_material': d['fabric_material'],
              'product_ref_id': d['product_ref_id'],
              'sale_price': d['sale_price'],
              'is_on_sale': d['is_on_sale'] ?? false,
              'discount_percent': d['discount_percent'] ?? 0,
              'is_active': true,
            })
            .select()
            .single();

        // Insert product_images rows
        final imageUrls = d['image_urls'];
        if (imageUrls is List && imageUrls.isNotEmpty) {
          await SupabaseService.client.from('product_images').insert(
                imageUrls
                    .asMap()
                    .entries
                    .map((e) => {
                          'product_id': product['id'],
                          'url': e.value,
                          'ordinal': e.key,
                        })
                    .toList(),
              );
        }

        return ApiResponse(201, product);
      } catch (e) {
        if (kDebugMode) debugPrint('createProduct error: $e');
        return ApiResponse(500, {'error': e.toString()});
      }
    }
    return _post('/api/products/vendor/create/', d);
  }

  static Future<ApiResponse> updateProduct(int id, Map d) async {
    if (SupabaseService.isReady) {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return ApiResponse(401, {'error': 'Not logged in'});

        // Resolve category_id
        int? categoryId;
        if (d['category'] != null) {
          final cat = await SupabaseService.client
              .from('categories')
              .select('id')
              .eq('slug', d['category'])
              .maybeSingle();
          categoryId = cat?['id'];
        }

        final updates = <String, dynamic>{
          if (d['name'] != null) 'name': d['name'],
          if (d['description'] != null) 'description': d['description'],
          if (d['price'] != null) 'price': d['price'],
          if (d['vendor_price'] != null) 'vendor_price': d['vendor_price'],
          if (d['stock_quantity'] != null) 'stock_quantity': d['stock_quantity'],
          if (categoryId != null) 'category_id': categoryId,
          if (d['status'] != null) 'status': d['status'],
          'sizes': d['sizes'] ?? [],
          'dimensions': d['dimensions'] ?? {},
          'colours': d['colours'] ?? [],
          if (d.containsKey('fabric_material')) 'fabric_material': d['fabric_material'],
          if (d.containsKey('product_ref_id')) 'product_ref_id': d['product_ref_id'],
          'is_on_sale': d['is_on_sale'] ?? false,
          'discount_percent': d['discount_percent'] ?? 0,
          if (d.containsKey('sale_price')) 'sale_price': d['sale_price'],
          'updated_at': DateTime.now().toIso8601String(),
        };

        final updated = await SupabaseService.client
            .from('products')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        // Remove deleted images
        final removedUrls = d['removed_image_urls'];
        if (removedUrls is List && removedUrls.isNotEmpty) {
          await SupabaseService.client
              .from('product_images')
              .delete()
              .eq('product_id', id)
              .inFilter('url', removedUrls.cast<String>());
        }

        // Add new images
        final newUrls = d['new_image_urls'];
        if (newUrls is List && newUrls.isNotEmpty) {
          final existing = await SupabaseService.client
              .from('product_images')
              .select('ordinal')
              .eq('product_id', id)
              .order('ordinal', ascending: false)
              .limit(1);
          int nextOrdinal =
              existing.isNotEmpty ? (existing.first['ordinal'] ?? 0) + 1 : 0;
          await SupabaseService.client.from('product_images').insert(
                newUrls
                    .asMap()
                    .entries
                    .map((e) => {
                          'product_id': id,
                          'url': e.value,
                          'ordinal': nextOrdinal + e.key,
                        })
                    .toList(),
              );
        }

        return ApiResponse(200, updated);
      } catch (e) {
        if (kDebugMode) debugPrint('updateProduct error: $e');
        return ApiResponse(500, {'error': e.toString()});
      }
    }
    return _put('/api/products/vendor/$id/', d);
  }

  static Future<ApiResponse> deleteProduct(int id) async {
    if (SupabaseService.isReady) {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return ApiResponse(401, {'error': 'Not logged in'});
        await SupabaseService.client
            .from('products')
            .delete()
            .eq('id', id);
        return ApiResponse(204, {});
      } catch (e) {
        if (kDebugMode) debugPrint('deleteProduct error: $e');
        return ApiResponse(500, {'error': e.toString()});
      }
    }
    return _delete('/api/products/vendor/$id/');
  }

  static Future<ApiResponse> getPendingProducts() => _get('/api/products/pending/');
  static Future<ApiResponse> approveProduct(int id, String action,
          {String? reason}) =>
      _post('/api/products/$id/approve/',
          {'action': action, if (reason != null) 'reason': reason});

  // ── Cart / Orders ─────────────────────────────────────────────────────────
  static Future<ApiResponse> checkCart(List<Map> items, String method) =>
      _post('/api/orders/cart/check/', {'items': items, 'delivery_method': method});

  static Future<ApiResponse> createOrder(Map d) => _post('/api/orders/create/', d);

  static Future<ApiResponse> getOrders({String? status}) =>
      _get('/api/orders/${status != null ? '?status=$status' : ''}');

  static Future<ApiResponse> getOrder(int id) => _get('/api/orders/$id/');

  static Future<ApiResponse> trackOrder(int id) => _get('/api/orders/$id/track/');

  static Future<ApiResponse> cancelOrder(int id) =>
      _post('/api/orders/$id/cancel/', {});

  static Future<ApiResponse> getReturns() => _get('/api/orders/returns/');
  static Future<ApiResponse> createReturn(Map d) =>
      _post('/api/orders/returns/create/', d);
  static Future<ApiResponse> getDisputes() => _get('/api/orders/disputes/');
  static Future<ApiResponse> createDispute(Map d) =>
      _post('/api/orders/disputes/create/', d);
  static Future<ApiResponse> getVendorOrders({String? status}) =>
      _get('/api/orders/vendor/${status != null ? '?status=$status' : ''}');
  static Future<ApiResponse> getVendorOrder(int id) =>
      _get('/api/orders/vendor/$id/');
  static Future<ApiResponse> getAllOrders({String? status}) =>
      _get('/api/orders/staff/all/${status != null ? '?status=$status' : ''}');

  // ── Payments ──────────────────────────────────────────────────────────────
  static Future<ApiResponse> payOrder(int orderId, String token) =>
      _post('/api/payments/$orderId/pay/', {'token': token});
  static Future<ApiResponse> getPaymentStatus(int orderId) =>
      _get('/api/payments/$orderId/status/');
  static Future<ApiResponse> getPaymentHistory() => _get('/api/payments/history/');
  static Future<ApiResponse> getPayouts() => _get('/api/payments/payouts/');

  // ── Courier ───────────────────────────────────────────────────────────────
  static Future<ApiResponse> getCourierProfile() => _get('/api/couriers/profile/');
  static Future<ApiResponse> toggleAvailability(bool on) =>
      _post('/api/couriers/availability/', {'is_online': on});
  static Future<ApiResponse> updateCourierStatus(bool on) =>
      toggleAvailability(on);
  static Future<ApiResponse> getCourierJobs({String? status}) =>
      _get('/api/couriers/jobs/${status != null ? '?status=$status' : ''}');
  static Future<ApiResponse> updateDeliveryStatus(int id, String status) =>
      _post('/api/couriers/jobs/$id/status/', {'status': status});
  static Future<ApiResponse> updateLocation(double lat, double lng) =>
      _post('/api/couriers/location/', {'latitude': '$lat', 'longitude': '$lng'});
  static Future<ApiResponse> getCourierEarnings() => _get('/api/couriers/earnings/');

  // ── Analytics ─────────────────────────────────────────────────────────────
  static Future<ApiResponse> getBuyerDashboard() => _get('/api/analytics/buyer/');
  static Future<ApiResponse> getVendorDashboard() => _get('/api/analytics/vendor/');
  static Future<ApiResponse> getStaffDashboard() => _get('/api/analytics/staff/');
  static Future<ApiResponse> calculateDelivery(double sub, String method) =>
      _post('/api/analytics/delivery-pricing/',
          {'subtotal': sub, 'delivery_method': method});
}

class ApiResponse {
  final int statusCode;
  final dynamic data;

  ApiResponse(this.statusCode, this.data);

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isOffline => statusCode == 0;
  bool get hasError => !isSuccess;

  String get errorMessage {
    if (isOffline) return 'No connection. Please check your internet.';
    if (isServerError) return 'Server error. Please try again later.';
    if (data is Map) {
      for (final key in ['detail', 'error', 'message', 'non_field_errors']) {
        if (data[key] != null) {
          final value = data[key];
          return value is List ? value.first.toString() : value.toString();
        }
      }
      final fieldErrors = (data as Map)
          .entries
          .where((entry) => entry.value is List)
          .map((entry) => '${entry.key}: ${(entry.value as List).first}')
          .join(', ');
      if (fieldErrors.isNotEmpty) return fieldErrors;
    }
    return 'Something went wrong. Please try again.';
  }
}
