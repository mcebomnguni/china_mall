import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'function_response_parser.dart';
import 'supabase_service.dart';

class DeliveryService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Quotes ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDeliveryQuote({
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
    double weightKg = 1.0,
  }) async {
    // Try Supabase Edge Function first
    try {
      final client = SupabaseService.client;
      final payload = {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'weight_kg': weightKg,
      };
      final fnRes = await client.functions.invoke('delivery_quote', body: payload);
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
      // ignore and fallback to HTTP
    }

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/delivery/quote/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'weight_kg': weightKg,
      }),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Booking ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> bookDelivery({
    required int orderId,
    required String deliveryType, // 'courier_guy' or 'app_driver'
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    double weightKg = 1.0,
  }) async {
    try {
      final client = SupabaseService.client;
      final payload = {
        'order_id': orderId,
        'delivery_type': deliveryType,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'delivery_address': deliveryAddress,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'weight_kg': weightKg,
      };
      final fnRes = await client.functions.invoke('delivery_book', body: payload);
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

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/delivery/book/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'order_id': orderId,
        'delivery_type': deliveryType,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'delivery_address': deliveryAddress,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'weight_kg': weightKg,
      }),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Tracking ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> trackDelivery(int deliveryId) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('delivery_track', body: {'delivery_id': deliveryId});
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

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/delivery/$deliveryId/track/'),
      headers: await _authHeaders(),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<List<dynamic>> getTrackingHistory(int deliveryId) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('delivery_tracking_history', body: {'delivery_id': deliveryId});
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseList(fnRes);
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/delivery/$deliveryId/tracking-history/'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── Driver: Location & Status ──────────────────────────────────────────────

  static Future<void> updateDriverLocation({
    required int deliveryId,
    required double lat,
    required double lng,
  }) async {
    try {
      final client = SupabaseService.client;
      await client.functions.invoke('driver_location', body: {
        'delivery_id': deliveryId,
        'lat': lat,
        'lng': lng,
      });
      return;
    } catch (_) {}

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver/location/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'delivery_id': deliveryId,
        'lat': lat,
        'lng': lng,
      }),
    );
  }

  static Future<Map<String, dynamic>> toggleOnline(bool isOnline) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('driver_online', body: {'is_online': isOnline});
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

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver/online/'),
      headers: await _authHeaders(),
      body: jsonEncode({'is_online': isOnline}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required int deliveryId,
    required String status,
  }) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('driver_update_delivery_status', body: {'delivery_id': deliveryId, 'status': status});
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

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver/delivery/$deliveryId/status/'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ── Courier Documents ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCourierDocuments() async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('courier_documents_list');
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

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/courier/documents/'),
      headers: await _authHeaders(),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> uploadCourierDocument({
    required String docType,
    required String filePath,
  }) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('courier_document_upload', body: {'doc_type': docType, 'file_path': filePath});
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

    final token = await AuthService.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/courier/documents/upload/'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['doc_type'] = docType;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> saveBankingDetails(
      Map<String, dynamic> details) async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('courier_banking_save', body: details);
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

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/courier/banking/'),
      headers: await _authHeaders(),
      body: jsonEncode(details),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }
}
