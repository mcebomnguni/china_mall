import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'supabase_service.dart';

class StoreProductService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getApprovedStores() async {
    try {
      final client = SupabaseService.client;
      final res = await client.from('stores').select();
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/stores/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getStoreDetail(int storeId) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('stores')
          .select('*, owner:profiles(*)')
          .eq('id', storeId)
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/stores/$storeId/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTopStores() async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('stores')
          .select('id,name,cover_url,created_at')
          .order('created_at', ascending: false)
          .limit(10);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/stores/top/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> reviewStore(
      int storeId, int rating, String comment) async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      final resp = await client.from('reviews').insert({
        'product_id': null,
        'profile_id': user?.id,
        'rating': rating,
        'body': comment,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select();
      return {'statusCode': 200, 'data': resp};
    } catch (_) {}
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/stores/$storeId/review/'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> getOwnerDashboard() async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final ordersRes = await client
            .from('orders')
            .select('id,total_amount,status,created_at')
            .eq('profile_id', user.id)
            .limit(50);
        return {'orders': ordersRes};
      }
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vendor/dashboard/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOwnerEarnings({int? year, int? month}) async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final res = await client
            .from('orders')
            .select('total_amount,created_at')
            .eq('profile_id', user.id);
        return List<dynamic>.from(res);
      }
    } catch (_) {}
    String url = '${ApiConstants.baseUrl}/vendor/earnings/';
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();
    if (params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOwnerDisputes() async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final res = await client.from('disputes').select('*').eq('raised_by', user.id);
        return List<dynamic>.from(res);
      }
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vendor/disputes/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getProducts({
    int? categoryId,
    int? storeId,
    String? search,
  }) async {
    try {
      final client = SupabaseService.client;
      var query = client.from('products').select();
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (storeId != null) query = query.eq('store_id', storeId);
      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }
      final response = await query;
      return List<dynamic>.from(response);
    } catch (_) {}

    String url = '${ApiConstants.baseUrl}/products/';
    final params = <String, String>{};
    if (categoryId != null) params['category'] = categoryId.toString();
    if (storeId != null) params['store'] = storeId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      url += '?${Uri(queryParameters: params).query}';
    }
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('products')
          .select('*, store:stores(*)')
          .eq('id', productId)
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTopProducts() async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('products')
          .select('id,title,price')
          .order('created_at', ascending: false)
          .limit(10);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/top/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTopProductsByCategory(int categoryId) async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('products')
          .select('id,title,price')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false)
          .limit(10);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/top/category/$categoryId/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getCategories() async {
    try {
      final client = SupabaseService.client;
      final res = await client.from('categories').select().order('label');
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/categories/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> submitProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required int categoryId,
    required List<File> images,
  }) async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        int? storeId;
        try {
          final storeRes =
              await client.from('stores').select('id').eq('owner', user.id).limit(1);
          if ((storeRes as List).isNotEmpty) {
            storeId = storeRes[0]['id'] as int?;
          }
        } catch (_) {}

        final createdProducts = await client
            .from('products')
            .insert({
              'store_id': storeId,
              'title': name,
              'description': description,
              'price': price,
              'stock': stock,
              'category_id': categoryId,
              'is_active': true,
            })
            .select();

        if ((createdProducts as List).isNotEmpty) {
          final created = Map<String, dynamic>.from(createdProducts[0] as Map);
          final productId = created['id'];
          final uploadedUrls = <String>[];

          for (int i = 0; i < images.length && i < 5; i++) {
            try {
              final file = images[i];
              final extension = file.path.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
              final path =
                  'products/$productId/${DateTime.now().millisecondsSinceEpoch}_$i$extension';
              await client.storage.from('product-images').upload(path, file);
              final publicUrl = client.storage.from('product-images').getPublicUrl(path);
              uploadedUrls.add(publicUrl);
              await client.from('product_images').insert({
                'product_id': productId,
                'url': publicUrl,
                'ordinal': i,
              });
            } catch (_) {}
          }

          return {
            'statusCode': 200,
            'data': {'product': created, 'images': uploadedUrls}
          };
        }
      }
    } catch (_) {}

    final token = await AuthService.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/vendor/products/submit/'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();
    request.fields['category'] = categoryId.toString();

    for (int i = 0; i < images.length && i < 5; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('images', images[i].path),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> reviewProduct(
      int productId, int rating, String comment) async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      final resp = await client.from('reviews').insert({
        'product_id': productId,
        'profile_id': user?.id,
        'rating': rating,
        'body': comment,
      }).select();
      return {'statusCode': 200, 'data': resp};
    } catch (_) {}
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId/review/'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<List<dynamic>> getOwnerProducts() async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final stores =
            await client.from('stores').select('id').eq('owner', user.id).limit(1);
        if ((stores as List).isNotEmpty) {
          final storeId = stores[0]['id'];
          final res = await client.from('products').select().eq('store_id', storeId);
          return List<dynamic>.from(res);
        }
      }
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vendor/products/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getOwnerProductDetail(int productId) async {
    try {
      final client = SupabaseService.client;
      final res =
          await client.from('products').select().eq('id', productId).maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vendor/products/$productId/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }
}
