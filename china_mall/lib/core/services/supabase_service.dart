import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;

  /// Call this once at app startup with your Supabase credentials.
  /// Example:
  /// await SupabaseService.init(url: 'https://xyz.supabase.co', anonKey: '...');
  static Future<void> init({required String url, required String anonKey}) async {
    if (_initialized) return;
    if (url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project.supabase.co') ||
        anonKey == 'your-anon-key') {
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );
    _initialized = true;
  }

  static bool get isReady => _initialized;
  static SupabaseClient get client => Supabase.instance.client;
}
