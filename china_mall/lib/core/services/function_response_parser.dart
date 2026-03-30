import 'dart:convert';

import 'package:functions_client/functions_client.dart';

class FunctionResponseParser {
  static dynamic unwrap(dynamic response) {
    if (response is FunctionResponse) return response.data;
    return response;
  }

  static int? statusCode(dynamic response) {
    if (response is FunctionResponse) return response.status;
    return null;
  }

  static dynamic parse(dynamic response) {
    final data = unwrap(response);
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  static Map<String, dynamic>? parseMap(dynamic response) {
    final parsed = parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  static List<dynamic>? parseList(dynamic response) {
    final parsed = parse(response);
    if (parsed is List) return List<dynamic>.from(parsed);
    return null;
  }

  static Map<String, dynamic> successMap(
    dynamic response, {
    int defaultStatusCode = 200,
    String fallbackKey = 'data',
  }) {
    final parsedMap = parseMap(response);
    if (parsedMap != null) {
      return {
        'statusCode': statusCode(response) ?? defaultStatusCode,
        ...parsedMap,
      };
    }

    return {
      'statusCode': statusCode(response) ?? defaultStatusCode,
      fallbackKey: parse(response),
    };
  }
}
