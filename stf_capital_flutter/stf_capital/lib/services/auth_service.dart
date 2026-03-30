// ─────────────────────────────────────────────────────────────────────────────
//  services/auth_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/app_models.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Security constants
  static const Duration _sessionTimeout = Duration(minutes: 5); // Auto-logout after 5 minutes
  static const Duration _biometricCooldown = Duration(minutes: 1); // Require biometric again after 1 minute
  static const int _maxFailedAttempts = 3; // Lock account after 3 failed attempts
  static const Duration _lockoutDuration = Duration(minutes: 15); // Lock account for 15 minutes

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  int _failedAttempts = 0;
  Timer? _sessionTimer;
  DateTime? _lastActivity;
  bool _isLocked = false;
  DateTime? _lockedUntil;

  static const bool _enableDemoLogin = bool.fromEnvironment(
    'ENABLE_DEMO_LOGIN',
    defaultValue: true,
  );
  static const String _demoClientEmail = '';
  static const String _demoClientPassword = '';
  static const String _demoAdminEmail = '';
  static const String _demoAdminPassword = '';

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }

  // ── Init: restore session ─────────────────────────────────────────────────
  Future<void> init() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<String?> demoLoginClient() async {
    if (!_enableDemoLogin) return 'Demo login is disabled.';
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 200)); // Reduced delay
    
    // Use consistent UID for demo client
    const demoClientUid = 'demo_client_123456';
    
    _currentUser = AppUser(
      uid: demoClientUid,
      username: 'demo_client',
      email: 'demo_client@example.com',
      firstName: 'Demo',
      lastName: 'Client',
      phone: '+1234567890',
      companyName: 'Demo Company',
      role: UserRole.client,
      createdAt: DateTime.now(),
    );
    
    // Skip Firestore save for demo - just create local user
    _setLoading(false);
    notifyListeners();
    return null;
  }

  Future<String?> demoLoginAdmin() async {
    if (!_enableDemoLogin) return 'Demo login is disabled.';
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 200)); // Reduced delay
    
    // Use consistent UID for demo admin
    const demoAdminUid = 'demo_admin_123456';
    
    _currentUser = AppUser(
      uid: demoAdminUid,
      username: 'demo_admin',
      email: 'demo_admin@example.com',
      firstName: 'Demo',
      lastName: 'Admin',
      phone: '+1234567890',
      companyName: 'STF Capital Admin',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );
    
    // Skip Firestore save for demo - just create local user
    _setLoading(false);
    notifyListeners();
    return null;
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<String?> register({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String companyName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // Check username uniqueness
      final usernameDoc = await _db
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      if (usernameDoc.exists) {
        _setLoading(false);
        return 'Username is already taken. Please choose a different username.';
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password,
      );

      final user = AppUser(
        uid:         cred.user!.uid,
        username:    username.trim(),
        email:       email.trim(),
        firstName:   firstName.trim(),
        lastName:    lastName.trim(),
        phone:       phone.trim(),
        companyName: companyName.trim(),
        role:        UserRole.client,
        createdAt:   DateTime.now(),
      );

      final batch = _db.batch();
      batch.set(_db.collection('users').doc(user.uid), user.toMap());
      batch.set(_db.collection('usernames').doc(username.toLowerCase()),
          {'uid': user.uid});
      await batch.commit();

      _currentUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        companyName: user.companyName,
        role: UserRole.client,
        createdAt: user.createdAt,
      );
      _setLoading(false);
      return null; // success
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _isLocked = false;
    _lockedUntil = null;
  }

  Future<void> _autoLogout() async {
    await _auth.signOut();
    _currentUser = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    notifyListeners();
  }

  // ── Helper Methods ────────────────────────────────────────────
  void _createUserSession(AppUser user) {
    _currentUser = user;
    _resetFailedAttempts();
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  void _incrementFailedAttempts() {
    _failedAttempts++;
    notifyListeners();
  }

  Future<void> _checkSessionTimeout() async {
    if (_lastActivity == null) return;

    final now = DateTime.now();
    if (now.difference(_lastActivity!) > _sessionTimeout) {
      await _autoLogout();
    }
  }

  // ── Device ID Validation ────────────────────────────────────
  Future<bool> _isDevelopmentDevice() async {
    // Check if running on development device/emulator
    try {
      // In debug mode, consider it a development device
      if (kDebugMode) {
        return true;
      }
      
      // Check for common development device identifiers
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.fingerprint.startsWith('generic') || 
          deviceInfo.model.toLowerCase().contains('emulator') ||
          deviceInfo.product.toLowerCase().contains('sdk_gphone')) {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking device info: $e');
    }
    
    return false;
  }

  // ── Enhanced Login Method (above) ─────────────────────────────────────────────────────
  Future<String?> login({
    required String emailOrUsername,
    required String password,
    bool useBiometrics = false,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // Development device check
      if (await _isDevelopmentDevice()) {
        _setLoading(false);
        return 'Biometric login is not available on development devices. Please use password authentication.';
      }

      String email = emailOrUsername.trim();

      // If not an email, look up username
      if (!email.contains('@')) {
        final usernameDoc = await _db
            .collection('usernames')
            .doc(email.toLowerCase())
            .get();
        if (!usernameDoc.exists) {
          _setLoading(false);
          return 'Username not found.';
        }
        final uid = usernameDoc.data()!['uid'] as String;
        final userDoc = await _db.collection('users').doc(uid).get();
        email = userDoc.data()!['email'] as String;
      }

      await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );

      await _loadUserData(_auth.currentUser!.uid);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<String?> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    }
  }

  // ── Forgot Username ───────────────────────────────────────────────────────
  Future<String?> recoverUsername(String email) async {
    _setLoading(true);
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      _setLoading(false);
      if (snap.docs.isEmpty) return null; // handled by UI (not found)
      final user = AppUser.fromMap(snap.docs.first.data());
      return user.username;
    } catch (e) {
      _setLoading(false);
      return null;
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String companyName,
  }) async {
    if (_currentUser == null) return 'Not logged in.';
    _setLoading(true);
    try {
      final updates = {
        'firstName':   firstName.trim(),
        'lastName':    lastName.trim(),
        'phone':       phone.trim(),
        'companyName': companyName.trim(),
      };
      await _db.collection('users').doc(_currentUser!.uid).update(updates);
      _currentUser = _currentUser!.copyWith(
        firstName:   firstName,
        lastName:    lastName,
        phone:       phone,
        companyName: companyName,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return 'Failed to update profile.';
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    }
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  Future<String?> deleteAccount(String password) async {
    if (_currentUser == null) return 'Not logged in.';
    _setLoading(true);
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!, password: password,
      );
      await user.reauthenticateWithCredential(cred);

      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(_currentUser!.uid));
      batch.delete(_db.collection('usernames')
          .doc(_currentUser!.username.toLowerCase()));
      await batch.commit();

      await user.delete();
      _currentUser = null;
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _authError(e.code);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── Error mapping ─────────────────────────────────────────────────────────
  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':    return 'This email address is already registered.';
      case 'invalid-email':           return 'Please enter a valid email address.';
      case 'weak-password':           return 'Password must be at least 6 characters.';
      case 'user-not-found':          return 'No account found with this email address.';
      case 'wrong-password':          return 'Incorrect password. Please try again.';
      case 'user-disabled':           return 'This account has been disabled.';
      case 'too-many-requests':       return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':   return 'Please log in again to complete this action.';
      default:                        return 'Authentication failed. Please try again.';
    }
  }
}
