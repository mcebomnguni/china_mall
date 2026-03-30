import 'dart:io';
import 'dart:convert';

void main() async {
  // Load .env
  final env = <String, String>{};
  final file = File('.env');
  if (await file.exists()) {
    final lines = await file.readAsLines();
    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final parts = l.split('=');
      if (parts.length < 2) continue;
      final key = parts.first.trim();
      var value = parts.sublist(1).join('=').trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }

  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final serviceKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  print('Supabase URL length: ${supabaseUrl.length}');
  print('Supabase URL: $supabaseUrl');
  print('Anon Key length: ${supabaseAnonKey.length}');
  print('Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
  print('Service Key length: ${serviceKey.length}');
  print('Service Key: ${serviceKey.substring(0, 20)}...');

  // Test HTTP request to Supabase Auth
  final client = HttpClient();
  
  try {
    // Test if Supabase is reachable
    final uri = Uri.parse('$supabaseUrl/auth/v1/user');
    final request = await client.getUrl(uri);
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    
    final response = await request.close();
    print('Supabase Auth endpoint status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 401) {
      print('✅ Supabase is reachable and configured correctly');
    } else {
      print('❌ Supabase returned unexpected status: ${response.statusCode}');
      final responseBody = await response.transform(utf8.decoder).join();
      print('Response: $responseBody');
    }
  } catch (e) {
    print('❌ Error connecting to Supabase: $e');
  } finally {
    client.close();
  }
}
