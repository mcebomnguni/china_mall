// ─────────────────────────────────────────────────────────────────────
//  services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/timezone.dart';
import '../models/app_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;

  // Notification settings
  static const String _notificationsKey = 'notification_settings';
  static const String _termsKey = 'terms_accepted';
  static const String _privacyKey = 'privacy_accepted';

  // Initialize notification service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize Firebase messaging
    await _messaging.requestPermission();
    await _messaging.getToken();
    
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
          '@mipmap/ic_launcher',
          'primary channel notifications',
          importance: Importance.high,
          priority: Priority.high,
        );
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    await _localNotifications.initialize(
      initializationSettingsAndroid: initializationSettingsAndroid,
      initializationSettingsIOS: initializationSettingsIOS,
    );
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permissions
    await PermissionHandler().requestPermissions([
      Permission.notification,
      Permission.vibrate,
      Permission.sound,
    ]);
  }

  // Send push notification to client
  Future<void> sendNotificationToClient({
    required String clientUid,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      // Create notification data
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'clientUid': clientUid,
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
        'type': 'push_notification',
      };

      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification['id'])
          .set(notification);

      // Send local notification
      await _localNotifications.show(
        AndroidNotificationDetails(
          'Custom notification',
          title,
          body,
          notificationData: notification,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: AndroidStyleInformation(
            color: '#FFD4AF37',
            icon: '@mipmap/ic_launcher',
            largeIcon: imageUrl,
          ),
        ),
        NotificationDetails(
          title,
          body,
          notificationData: notification,
        ),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Get notification settings
  Future<bool> areNotificationsEnabled() async {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }

  // Get terms acceptance
  Future<bool> areTermsAccepted() async {
    return _prefs.getBool(_termsKey) ?? false;
  }

  Future<void> acceptTerms() async {
    await _prefs.setBool(_termsKey, true);
  }

  // Get privacy acceptance
  Future<bool> isPrivacyAccepted() async {
    return _prefs.getBool(_privacyKey) ?? false;
  }

  Future<void> acceptPrivacy() async {
    await _prefs.setBool(_privacyKey, true);
  }

  // Get notification badge count
  Future<int> getUnreadCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('clientUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('read', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting notification count: $e');
      return 0;
    }
  }

  // Clear notification badge
  Future<void> clearBadgeCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('clientUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('read', isEqualTo: false)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('Error clearing notification badge: $e');
    }
  }
}
