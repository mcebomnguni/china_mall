#!/usr/bin/env dart run

import 'dart:io';
import 'dart:math';
import 'supabase_admin.dart';

/// Supabase test user seed script (admin-only).
/// Usage:
///   dart run scripts/create_test_users.dart [--dry-run]

const defaultCounts = {
  'customer': 100,
  'vendor': 20,
  'courier': 10,
  'admin': 2,
};

const defaultPassword = 'Test1234!';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  print('=== Supabase Test User Seed ===');
  if (dryRun) print('DRY RUN: No real changes will be made.\n');

  /// ✅ Load env safely
  final env = await _loadEnv();

  final supabaseUrl = env['SUPABASE_URL'];
  final serviceRoleKey = env['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || serviceRoleKey == null) {
    stderr.writeln(
      '❌ ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env',
    );
    exit(1);
  }

  /// ✅ Generate users
  final users = <Map<String, dynamic>>[];

  for (final entry in defaultCounts.entries) {
    for (int i = 1; i <= entry.value; i++) {
      users.add(_generateUser(entry.key, i));
    }
  }

  print('Will create ${users.length} users:');
  defaultCounts.forEach((k, v) => print('  - $k: $v'));
  print('');

  if (dryRun) {
    print('=== Preview ===');
    for (final u in users.take(5)) {
      print('  ${u['email']} (${u['user_metadata']['role']})');
    }
    print('... (${users.length - 5} more)');
    return;
  }

  final seeder = SupabaseSeeder(
    supabaseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );

  final report = {
    'created': <String>[],
    'skipped': <String>[],
    'failed': <String>[],
  };

  /// ✅ Process users safely
  for (final u in users) {
    try {
      final authId = await seeder.createUser(
        email: u['email'],
        password: u['password'],
        emailConfirm: u['email_confirm'],
        userMetadata: u['user_metadata'],
        appMetadata: u['app_metadata'],
      );

      if (authId == null) {
        report['skipped']!.add('${u['email']} (no auth id)');
        continue;
      }

      await seeder.upsertProfile(
        id: authId,
        email: u['email'],
        phone: u['user_metadata']['phone'],
        fullName: u['user_metadata']['full_name'],
        role: u['user_metadata']['role'],
      );

      report['created']!.add('${u['email']} ($authId)');
    } catch (e) {
      final msg = e.toString().toLowerCase();

      if (msg.contains('email_exists')) {
        report['skipped']!.add('${u['email']} (already exists)');
      } else {
        report['failed']!.add('${u['email']} ($e)');
      }
    }
  }

  /// ✅ Print report
  print('\n=== REPORT ===');
  report.forEach((key, list) {
    print('\n$key (${list.length})');
    for (final item in list) {
      print('  $item');
    }
  });

  /// ✅ Save CSV safely
  final file = File('scripts/seed_report.csv');

  final buffer = StringBuffer('status,email,role,notes\n');

  void writeRows(String status, List<String> rows) {
    for (final row in rows) {
      final email = row.split(' ').first;
      buffer.writeln('$status,$email,test,"$row"');
    }
  }

  writeRows('created', report['created']!);
  writeRows('skipped', report['skipped']!);
  writeRows('failed', report['failed']!);

  await file.writeAsString(buffer.toString());

  print('\n✅ Report saved → scripts/seed_report.csv');
}

/// ✅ Improved ENV loader (supports system + .env)
Future<Map<String, String>> _loadEnv() async {
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

  /// fallback → system env overrides .env
  env.addAll(Platform.environment);

  return env;
}

/// ✅ User generator
Map<String, dynamic> _generateUser(String role, int index) {
  final idx = index.toString().padLeft(3, '0');

  return {
    'email': '$role.test.$idx@chinamall.local',
    'password': defaultPassword,
    'email_confirm': true,
    'user_metadata': {
      'full_name': '${_capitalize(role)} Test $idx',
      'role': role,
      'phone': '+27${70000000 + index}',
    },
    'app_metadata': {
      'role': role,
      'provider': 'seed_script',
    },
  };
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);