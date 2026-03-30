import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
    print('✅ .env loaded from assets');
    print('Available keys: ${dotenv.env.keys}');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');
  } catch (e) {
    print('❌ Error loading .env: $e');
  }
}
