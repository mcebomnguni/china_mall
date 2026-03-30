// ─────────────────────────────────────────────────────────────────────────────
//  main.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'services/auth_service.dart';
import 'services/application_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait + landscape on mobile, unrestricted on web/desktop
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:         Colors.transparent,
    statusBarBrightness:    Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    // TODO: Replace with your Firebase project options
    // Generated from google-services.json / GoogleService-Info.plist
    // or firebase_options.dart via FlutterFire CLI
    options: const FirebaseOptions(
      apiKey:            'YOUR_API_KEY',
      appId:             'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId:         'YOUR_PROJECT_ID',
      storageBucket:     'YOUR_STORAGE_BUCKET',
    ),
  );

  runApp(const StfCapitalApp());
}

class StfCapitalApp extends StatelessWidget {
  const StfCapitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => ApplicationService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final _router = buildRouter(context.read<AuthService>());

  @override
  Widget build(BuildContext context) {
    // Rebuild router redirect when auth changes
    context.watch<AuthService>();

    return MaterialApp.router(
      title:             'STF Capital',
      debugShowCheckedModeBanner: false,
      theme:             AppTheme.light,
      darkTheme:         AppTheme.dark,
      themeMode:         context.watch<ThemeService>().isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig:      _router,
    );
  }
}
