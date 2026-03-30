import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'function_response_parser.dart';
import 'supabase_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // ── Token helpers ──────────────────────────────────────────────────────────

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    await _storage.write(
      key: 'token_saved_at',
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  static Future<void> setLastAuthAt(String timestamp) async {
    await _storage.write(key: 'last_auth_at', value: timestamp);
  }

  static Future<String?> getLastAuthAt() async {
    return await _storage.read(key: 'last_auth_at');
  }

  /// Returns true if the 4-minute window has passed since last token save.
  static Future<bool> isSessionExpired() async {
    final savedAt = await _storage.read(key: 'token_saved_at');
    if (savedAt == null) return true;
    final saved = DateTime.tryParse(savedAt);
    if (saved == null) return true;
    return DateTime.now().difference(saved).inMinutes >= 4;
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    // Try Supabase password reset email first
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return {'statusCode': 200, 'detail': 'reset_email_sent'};
    } catch (_) {
      // fallback to existing Django endpoint
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('auth_verify_otp', body: {'email': email, 'otp': otp});
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        if (parsed != null) {
          return {
            'statusCode': FunctionResponseParser.statusCode(fnRes) ?? 200,
            ...parsed,
          };
        }
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('auth_reset_password', body: {
        'email': email,
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        if (parsed != null) {
          return {
            'statusCode': FunctionResponseParser.statusCode(fnRes) ?? 200,
            ...parsed,
          };
        }
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );
    return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
  }

  // ── Forgot Username ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> forgotUsername(String email) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('auth_forgot_username', body: {'email': email});
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        if (parsed != null) {
          return {
            'statusCode': FunctionResponseParser.statusCode(fnRes) ?? 200,
            ...parsed,
          };
        }
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/forgot-username/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
  }

  // ── Biometric ──────────────────────────────────────────────────────────────

  static Future<void> saveBiometricToken(String token) async {
    await _storage.write(key: 'biometric_token', value: token);
  }

  static Future<String?> getBiometricToken() async {
    return await _storage.read(key: 'biometric_token');
  }

  static Future<Map<String, dynamic>> registerBiometric(
      String biometricToken, String accessToken) async {
    // Try Supabase: insert into `devices` table linked to current user
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final resp = await SupabaseService.client
            .from('devices')
            .insert({
              'profile_id': user.id,
              'device_id': biometricToken,
              'last_seen': DateTime.now().toIso8601String(),
            })
            .select();
        return {'statusCode': 200, 'data': resp};
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/biometric/register/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'biometric_token': biometricToken}),
    );
    return {'statusCode': response.statusCode, ...jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> biometricLogin(
      String biometricToken) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('auth_biometric_login', body: {'biometric_token': biometricToken});
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        if (parsed != null) {
          final access = parsed['access'];
          final refresh = parsed['refresh'];
          if (access is String && refresh is String) {
            await saveTokens(access, refresh);
          }
          return {
            'statusCode': FunctionResponseParser.statusCode(fnRes) ?? 200,
            ...parsed,
          };
        }
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/biometric/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'biometric_token': biometricToken}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveTokens(body['access'], body['refresh']);
    }
    return {'statusCode': response.statusCode, ...body};
  }
}
