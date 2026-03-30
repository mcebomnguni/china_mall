import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'function_response_parser.dart';
import 'supabase_service.dart';

class PaymentService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── PIN management ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> setPaymentPIN(
      String pin, String confirmPin) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/pin/set/'),
      headers: await _authHeaders(),
      body: jsonEncode({'pin': pin, 'confirm_pin': confirmPin}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> verifyPaymentPIN(String pin) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/verify-pin/'),
      headers: await _authHeaders(),
      body: jsonEncode({'pin': pin}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Checkout ───────────────────────────────────────────────────────────────

  /// Full payment flow:
  /// 1. Verify biometric or PIN
  /// 2. Call initiate — get redirect_url
  /// 3. Open WebView with redirect_url
  static Future<Map<String, dynamic>> initiatePayment({
    required int orderId,
    required int amountCents,
    required bool biometricVerified,
    String? pinToken,
  }) async {
    // Try Supabase Edge Function first (initiate_payment)
    try {
      final client = SupabaseService.client;
      final payload = {
        'order_id': orderId,
        'amount_cents': amountCents,
        'biometric_verified': biometricVerified,
        if (pinToken != null) 'pin_token': pinToken,
      };
      final fnRes = await client.functions.invoke('initiate_payment', body: payload);
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        if (parsed != null) {
          return {
            'statusCode': FunctionResponseParser.statusCode(fnRes) ?? 200,
            ...parsed,
          };
        }
      }
    } catch (_) {
      // fallback to HTTP
    }

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/initiate/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'order_id': orderId,
        'amount_cents': amountCents,
        'biometric_verified': biometricVerified,
        if (pinToken != null) 'pin_token': pinToken,
      }),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Payment history ────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPaymentHistory() async {
    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final res = await client
            .from('payments')
            .select('*')
            .eq('profile_id', user.id)
            .order('created_at', ascending: false);
        return List<dynamic>.from(res);
      }
    } catch (_) {}

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/payments/history/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── Refund ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> requestRefund({
    required int transactionId,
    required int amountCents,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/refund/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'transaction': transactionId,
        'amount_cents': amountCents,
        'reason': reason,
      }),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }
}
