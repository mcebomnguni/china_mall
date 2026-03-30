import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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

  print('Testing Supabase connection...');
  print('URL: $supabaseUrl');
  print('Key: ${supabaseAnonKey.substring(0, 20)}...');

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Supabase initialized successfully');

    // Test login with first test user
    final email = 'customer.test.001@chinamall.local';
    final password = 'Test1234!';
    
    print('\nTesting login with:');
    print('Email: $email');
    print('Password: $password');

    final response = await Supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session != null && response.user != null) {
      print('✅ Login successful!');
      print('User ID: ${response.user!.id}');
      print('Email: ${response.user!.email}');
      
      // Check user metadata
      final metadata = response.user!.userMetadata;
      print('User metadata: $metadata');
      
      // Try to get profile
      final profile = await Supabase.client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();
      
      if (profile != null) {
        print('✅ Profile found: $profile');
      } else {
        print('⚠️ No profile found in profiles table');
      }
    } else {
      print('❌ Login failed: No session or user returned');
    }
  } on AuthException catch (e) {
    print('❌ AuthException: ${e.message}');
    print('Status: ${e.statusCode}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
