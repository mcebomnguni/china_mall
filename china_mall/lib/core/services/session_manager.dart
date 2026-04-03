import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Attach this to your app's navigator key.
/// Call SessionManager.onUserActivity() on any tap/scroll.
/// It will auto-logout after 4 minutes of inactivity.
class SessionManager {
  static Timer? _timer;
  static const _timeoutMinutes = 30;
  static VoidCallback? _onSessionExpired;

  /// Call once in main_shell.dart or your root widget
  static void init({required VoidCallback onSessionExpired}) {
    _onSessionExpired = onSessionExpired;
    _resetTimer();
  }

  /// Call this on every user interaction (tap, scroll, key press)
  static void onUserActivity() {
    _resetTimer();
  }

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(minutes: _timeoutMinutes),
      _handleTimeout,
    );
  }

  static Future<void> _handleTimeout() async {
    await AuthService.clearTokens();
    _onSessionExpired?.call();
  }

  static void dispose() {
    _timer?.cancel();
  }

  static const String _lastFullLoginKey = 'last_full_login_timestamp';
  static const int _fullLoginCycleDays = 30;

  static Future<bool> requiresFullLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFullLogin = prefs.getInt(_lastFullLoginKey);
    if (lastFullLogin == null) return true;
    final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastFullLogin);
    final daysSinceFullLogin = DateTime.now().difference(lastLoginDate).inDays;
    return daysSinceFullLogin >= _fullLoginCycleDays;
  }

  static Future<void> recordFullLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastFullLoginKey, DateTime.now().millisecondsSinceEpoch);
  }
}

/// Wrap your app's Scaffold or Navigator with this widget.
/// It listens to all pointer events to detect activity.
class SessionActivityDetector extends StatelessWidget {
  final Widget child;

  const SessionActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager.onUserActivity(),
      onPointerMove: (_) => SessionManager.onUserActivity(),
      child: child,
    );
  }
}
