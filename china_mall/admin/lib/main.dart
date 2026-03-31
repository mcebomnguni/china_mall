import 'package:flutter/material.dart';
import 'core/services/supabase_service.dart';
import 'core/router/admin_router.dart';
import 'core/theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminSupabase.init();
  runApp(const ChinaStallAdminApp());
}

class ChinaStallAdminApp extends StatelessWidget {
  const ChinaStallAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'China Stall Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      routerConfig: adminRouter,
    );
  }
}
