// lib/core/services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// PUSH NOTIFICATIONS (item #26)
// Firebase Cloud Messaging setup + in-app notification centre
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'auth_service.dart';
import 'function_response_parser.dart';
import 'supabase_service.dart';

// ── Background message handler (must be top-level function) ──────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages silently
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'chinamall_channel',
    'ChinaMall Notifications',
    description: 'Order updates, delivery alerts and promotions',
    importance: Importance.high,
  );

  static Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  // ── Initialise (call once in main.dart) ────────────────────────────────────

  static Future<void> init() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Set up local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Register token with backend
    await registerToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) => _saveTokenToBackend(token));
  }

  // ── Token registration ─────────────────────────────────────────────────────

  static Future<void> registerToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToBackend(token);
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      // Try Supabase Edge Function first
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('notifications_register_device', body: {
          'token': token,
          'platform': 'android',
          'device_name': 'ChinaMall App',
        });
        if (fnRes != null) return;
      } catch (_) {}

      final authToken = await AuthService.getAccessToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/register-device/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': 'android', // or detect platform
          'device_name': 'ChinaMall App',
        }),
      );
    } catch (_) {}
  }

  static Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      final authToken = await AuthService.getAccessToken();
      if (token == null || authToken == null) return;
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('notifications_unregister_device', body: {'token': token});
        if (fnRes != null) return;
      } catch (_) {}

      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unregister-device/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigate based on payload
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNavigation(data);
    }
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    _handleNavigation(message.data);
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    // Use your router to navigate
    // if (data['order_id'] != null) router.push('/orders/${data['order_id']}');
    // if (data['store_id'] != null) router.push('/stores/${data['store_id']}');
  }

  // ── Fetch in-app notifications ─────────────────────────────────────────────

  static Future<List<dynamic>> getNotifications() async {
    // Try Supabase table first
    try {
      final client = SupabaseService.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        final resp = await client
            .from('notifications')
            .select()
            .eq('profile_id', currentUser.id)
            .order('created_at', ascending: false);
        return List<dynamic>.from(resp);
      }
    } catch (_) {}

    final token = await AuthService.getAccessToken();
    if (token == null) return [];
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<int> getUnreadCount() async {
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('notifications_unread_count');
      if (fnRes != null) {
        final parsed = FunctionResponseParser.parseMap(fnRes);
        final unreadCount = parsed?['unread_count'];
        if (unreadCount is int) return unreadCount;
        if (unreadCount is num) return unreadCount.toInt();
      }
    } catch (_) {}

    final token = await AuthService.getAccessToken();
    if (token == null) return 0;
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body)['unread_count'] ?? 0;
  }

  static Future<void> markAllRead() async {
    final token = await AuthService.getAccessToken();
    if (token == null) return;
    try {
      final client = SupabaseService.client;
      final fnRes = await client.functions.invoke('notifications_mark_read');
      if (fnRes != null) return;
    } catch (_) {}

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/mark-read/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
  }
}
