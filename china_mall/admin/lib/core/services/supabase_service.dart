import 'package:supabase_flutter/supabase_flutter.dart';

const _kUrl    = 'https://ipsdpswdubdczxfbvtty.supabase.co';
const _kAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlwc2Rwc3dkdWJkY3p4ZmJ2dHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MjgxMTIsImV4cCI6MjA5MDMwNDExMn0'
    '.10NJDPv65hSgmTlfQs1c_h9UKCg3zXt4zFHUlMnsNt8';

class AdminSupabase {
  static SupabaseClient get client => Supabase.instance.client;
  static User?          get currentUser => client.auth.currentUser;
  static bool           get isLoggedIn  => currentUser != null;

  static Future<void> init() async {
    await Supabase.initialize(url: _kUrl, anonKey: _kAnonKey);
  }
}
