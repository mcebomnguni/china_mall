import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/app_config_provider.dart';
import 'core/providers/theme_notifier.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/app_info_service.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/offline_wrapper.dart';
import 'core/widgets/session_manager.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/products/providers/products_provider.dart';
import 'features/orders/providers/orders_provider.dart';
import 'features/support/providers/support_provider.dart';
import 'core/services/supabase_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[ChinaStall] Starting app...');

    // Load .env from assets
    await dotenv.load(fileName: '.env');
    debugPrint('[ChinaStall] .env loaded from assets');

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? 'your-anon-key';
    final supabaseClientKey = supabaseAnonKey.isNotEmpty
        ? supabaseAnonKey
        : supabasePublishableKey;

    debugPrint('SUPABASE_URL: $supabaseUrl');
    debugPrint('SUPABASE_ANON_KEY: ${supabaseClientKey.isNotEmpty ? supabaseClientKey.substring(0, 20) : 'EMPTY'}...');
    debugPrint('Available env keys: ${dotenv.env.keys}');

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('[ChinaStall] Initializing AppInfoService...');
    await AppInfoService.init();

    debugPrint('[ChinaStall] Initializing Supabase...');
    await SupabaseService.init(
      url: supabaseUrl,
      anonKey: supabaseClientKey,
    );
    debugPrint('Supabase ready: ${SupabaseService.isReady}');
    
    if (SupabaseService.isReady) {
      try {
        debugPrint('[ChinaStall] Initializing NotificationService...');
        await NotificationService.init();
        debugPrint('[ChinaStall] NotificationService initialized');
      } catch (e) {
        debugPrint('[ChinaStall] NotificationService failed: $e');
      }
    }

    // Load persisted theme before first frame — no flash of wrong theme.
    debugPrint('[ChinaStall] Initializing theme...');
    final themeNotifier = ThemeNotifier();
    await themeNotifier.init();
    _applySystemUI(dark: themeNotifier.isDark);
    debugPrint('[ChinaStall] Theme initialized');

    debugPrint('[ChinaStall] Building app...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
          ChangeNotifierProvider(create: (_) => ConnectivityService()),
          ChangeNotifierProvider(create: (_) => AppConfigProvider()..load()),
          ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductsProvider()),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ChangeNotifierProvider(create: (_) => SupportProvider()),
        ],
        child: const ChinaStallApp(),
      ),
    );
    debugPrint('[ChinaStall] App started successfully');
  } catch (e, stackTrace) {
    debugPrint('[ChinaStall] FATAL ERROR IN MAIN: $e');
    debugPrint('Stack trace: $stackTrace');
    // Show error screen
    runApp(ErrorScreen(error: e.toString()));
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _applySystemUI({required bool dark}) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: dark ? const Color(0xFF111110) : Colors.white,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
  ));
}

class ChinaStallApp extends StatefulWidget {
  const ChinaStallApp({super.key});

  @override
  State<ChinaStallApp> createState() => _ChinaStallAppState();
}

class _ChinaStallAppState extends State<ChinaStallApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final auth          = context.watch<AuthProvider>();
    final themeNotifier = context.watch<ThemeNotifier>();
    // Create router once — GoRouter.refreshListenable handles auth changes
    _router ??= createRouter(auth);

    _applySystemUI(dark: themeNotifier.isDark);

    return MaterialApp.router(
      title: 'China Stall Market Place',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.mode,
      routerConfig: _router!,
      builder: (context, child) {
        return OfflineWrapper(
          child: SessionActivityDetector(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.maybeTextScalerOf(context)?.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2).scale(1) ?? 1.0,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
