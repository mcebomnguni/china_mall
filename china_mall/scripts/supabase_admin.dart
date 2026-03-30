import 'dart:convert';
import 'dart:io';

/// Supabase Admin Seeder (correct way)
class SupabaseSeeder {
  final String supabaseUrl;
  final String serviceRoleKey;
  final HttpClient _http = HttpClient();

  SupabaseSeeder({
    required this.supabaseUrl,
    required this.serviceRoleKey,
  });

  /// ✅ CREATE USER (REAL IMPLEMENTATION)
  Future<String?> createUser({
    required String email,
    String? password,
    bool emailConfirm = true,
    Map<String, dynamic>? userMetadata,
    Map<String, dynamic>? appMetadata,
  }) async {
    final uri = Uri.parse('$supabaseUrl/auth/v1/admin/users');

    final request = await _http.postUrl(uri);

    request.headers.set('apikey', serviceRoleKey);
    request.headers.set('Authorization', 'Bearer $serviceRoleKey');
    request.headers.set('Content-Type', 'application/json');

    final body = {
      'email': email,
      'password': password,
      'email_confirm': emailConfirm,
      if (userMetadata != null) 'user_metadata': userMetadata,
      if (appMetadata != null) 'app_metadata': appMetadata,
    };

    request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(responseBody);
      return data['id']; // ✅ auth.users.id
    }

    throw Exception(
      'Create user failed: ${response.statusCode} $responseBody',
    );
  }

  /// ✅ UPSERT PROFILE (with auto-retry on 404)
  Future<void> upsertProfile({
    required String id,
    String? email,
    String? phone,
    String? fullName,
    String? role,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('$supabaseUrl/rest/v1/profiles');

    final request = await _http.postUrl(uri);

    request.headers.set('apikey', serviceRoleKey);
    request.headers.set('Authorization', 'Bearer $serviceRoleKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'resolution=merge-duplicates');

    final body = {
      'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
    };

    request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close();

    if (response.statusCode == 404 && !isRetry) {
      print('⚠️ Profiles table not found, refreshing schema and retrying...');
      await _refreshSchema();
      await Future.delayed(Duration(seconds: 2));
      return upsertProfile(
        id: id,
        email: email,
        phone: phone,
        fullName: fullName,
        role: role,
        isRetry: true,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final resp = await response.transform(utf8.decoder).join();
      throw Exception('Profile upsert failed: ${response.statusCode} $resp');
    }
  }

  /// ✅ Refresh PostgREST schema cache
  Future<void> _refreshSchema() async {
    final uri = Uri.parse('$supabaseUrl/rest/v1/rpc/notify');
    final request = await _http.postUrl(uri);
    request.headers.set('apikey', serviceRoleKey);
    request.headers.set('Authorization', 'Bearer $serviceRoleKey');
    request.headers.set('Content-Type', 'application/json');
    request.add(utf8.encode(jsonEncode({'channel': 'pgrst', 'payload': 'reload schema'})));
    await request.close();
  }
}