import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'function_response_parser.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AdminService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Overview ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPlatformOverview() async {
    try {
      final client = SupabaseService.client;
      final res = await client.rpc('admin_overview', params: {'days': 30});
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/overview/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getRevenueChart({int days = 30}) async {
    try {
      final client = SupabaseService.client;
      final res = await client.rpc('admin_overview', params: {'days': days});
      if (res != null) {
        final chart = (res as Map)['orders_by_day'];
        return chart is List ? chart : [];
      }
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/revenue-chart/?days=$days'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPendingApprovals() async {
    try {
      final client = SupabaseService.client;
      final res = await client.from('stores').select().eq('status', 'pending');
      return {'pending': res};
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/pending/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> distributeApprovals() async {
    try {
      final client = SupabaseService.client;
      final res = await client.functions.invoke('distribute_approvals');
      if (res != null) return {'statusCode': 200, 'data': res};
    } catch (_) {}
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/distribute/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAuditLog() async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/audit-log/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── Top lists ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getTopStores() async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('stores')
          .select('id,name,cover_url,created_at')
          .order('created_at', ascending: false)
          .limit(20);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/top-stores/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTopProducts() async {
    try {
      final client = SupabaseService.client;
      final res = await client
          .from('products')
          .select('id,title,price,created_at')
          .order('created_at', ascending: false)
          .limit(20);
      return List<dynamic>.from(res);
    } catch (_) {}
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/top-products/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getUsers({String? role, String? search}) async {
    try {
      final client = SupabaseService.client;
      var query = client.from('profiles').select();
      if (role != null) query = query.eq('role', role);
      if (search != null && search.isNotEmpty) query = query.or('email.ilike.%$search%,full_name.ilike.%$search%');
      final res = await query;
      return List<dynamic>.from(res);
    } catch (_) {}
    String url = '${ApiConstants.baseUrl}/admin/users/';
    final params = <String, String>{};
    if (role != null) params['role'] = role;
    if (search != null) params['search'] = search;
    if (params.isNotEmpty) url += '?${Uri(queryParameters: params).query}';
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String username,
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('admin_create_user', body: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });
      if (fnRes != null) {
        return FunctionResponseParser.successMap(fnRes);
      }
    } catch (_) {}
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/create-admin/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'username': username, 'email': email,
        'password': password, 'role': role,
      }),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> userAction(
      int userId, String action) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('admin_user_action', body: {'user_id': userId, 'action': action});
      if (fnRes != null) return {'statusCode': 200, 'data': fnRes};
    } catch (_) {}
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/action/'),
      headers: await _authHeaders(),
      body: jsonEncode({'action': action}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Ads ────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getAds({String? status}) async {
    String url = '${ApiConstants.baseUrl}/admin/ads/';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> reviewAd(
      int adId, String action, {String reason = ''}) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/ads/$adId/review/'),
      headers: await _authHeaders(),
      body: jsonEncode({'action': action, 'reason': reason}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Push campaigns ─────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPushCampaigns({String? status}) async {
    String url = '${ApiConstants.baseUrl}/admin/push-campaigns/';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> reviewPushCampaign(
      int campaignId, String action, {String reason = ''}) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/push-campaigns/$campaignId/review/'),
      headers: await _authHeaders(),
      body: jsonEncode({'action': action, 'reason': reason}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }
}
