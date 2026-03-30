import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  static const _kBiometricKey = 'biometric_enabled';
  static const _kOnboardingDoneKey = 'onboarding_done';
  static const _kHardLoginMinutes = 30;

  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthStatus _status = AuthStatus.unknown;
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;
  bool _onboardingDone = false;
  DateTime? _lastAuthAt;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get onboardingDone => _onboardingDone;

  String get role => _user?['role']?.toString() ?? 'buyer';
  bool get isBuyer => role == 'buyer';
  bool get isVendor => role == 'vendor';
  bool get isCourier => role == 'courier';
  bool get isStaff => role == 'staff' || role == 'admin';
  bool get isOnline => _user?['is_online'] == true;

  Future<void> init() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    await _loadOnboarding();
    await _restoreLocalSessionState();
    _listenToAuthChanges();

    await Future.wait([
      checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
    _onboardingDone = true;
    notifyListeners();
  }

  Future<void> _restoreLocalSessionState() async {
    final savedAt = await AuthService.getLastAuthAt();
    _lastAuthAt = savedAt != null ? DateTime.tryParse(savedAt) : null;
  }

  void _listenToAuthChanges() {
    if (!SupabaseService.isReady || _authSubscription != null) return;

    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((_) {
      unawaited(checkAuthStatus());
    });
  }

  bool _requiresHardLogin() {
    if (_lastAuthAt == null) return false;
    return DateTime.now().difference(_lastAuthAt!).inMinutes >= _kHardLoginMinutes;
  }

  Future<void> _markAuthenticated() async {
    _lastAuthAt = DateTime.now();
    await AuthService.setLastAuthAt(_lastAuthAt!.toIso8601String());
  }

  Future<Map<String, dynamic>?> _loadSupabaseProfile() async {
    if (!SupabaseService.isReady) return null;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    final profile = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', currentUser.id)
        .maybeSingle();

    if (profile == null) {
      final fallback = <String, dynamic>{
        'id': currentUser.id,
        'email': currentUser.email,
        'full_name': currentUser.userMetadata?['full_name'],
        'role': currentUser.userMetadata?['role'] ?? 'buyer',
      };

      await SupabaseService.client.from('profiles').upsert(fallback);
      return fallback;
    }

    return Map<String, dynamic>.from(profile);
  }

  Future<bool> checkAuthStatus() async {
    _error = null;

    try {
      if (!SupabaseService.isReady) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final session = SupabaseService.client.auth.currentSession;
      final currentUser = SupabaseService.client.auth.currentUser;
      if (session == null || currentUser == null || _requiresHardLogin()) {
        if (_requiresHardLogin()) {
          await logout(reason: 'Session expired. Sign in again to continue.');
        } else {
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
        return false;
      }

      _user = await _loadSupabaseProfile();
      _status = _user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      notifyListeners();
      return _status == AuthStatus.authenticated;
    } catch (e) {
      _error = 'Failed to restore your session.';
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isBioEnabled = prefs.getBool(_kBiometricKey) ?? false;
    if (!isBioEnabled || !SupabaseService.isReady) return false;

    try {
      final canAuth =
          await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuth) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to unlock China Stall',
        biometricOnly: false,
      );

      if (!authenticated) return false;
      await _markAuthenticated();
      return checkAuthStatus();
    } catch (_) {
      _error = 'Biometric authentication failed.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    if (!SupabaseService.isReady) {
      _error = 'Supabase is not configured yet.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final email = username.trim();
      final authResponse = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.session == null || authResponse.user == null) {
        throw const AuthException('Invalid login response.');
      }

      await AuthService.saveTokens(
        authResponse.session!.accessToken,
        authResponse.session!.refreshToken ?? '',
      );
      await _markAuthenticated();
      await NotificationService.registerToken();
      _user = await _loadSupabaseProfile();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (_) {
      _error = 'Unable to sign in right now.';
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    if (!SupabaseService.isReady) {
      _error = 'Supabase is not configured yet.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final firstName = data['first_name']?.toString().trim() ?? '';
      final lastName = data['last_name']?.toString().trim() ?? '';
      final fullName = '$firstName $lastName'.trim();
      final email = data['email']?.toString().trim() ?? '';
      final password = data['password']?.toString() ?? '';
      final role = data['role']?.toString() ?? 'buyer';

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'username': data['username']?.toString().trim(),
          'phone': data['phone']?.toString().trim(),
        },
      );

      final createdUser = response.user;
      if (createdUser != null) {
        await SupabaseService.client.from('profiles').upsert({
          'id': createdUser.id,
          'email': email,
          'phone': data['phone']?.toString().trim(),
          'full_name': fullName,
          'role': role,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to create your account right now.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout({String? reason}) async {
    try {
      await NotificationService.unregisterToken();
    } catch (_) {}

    try {
      if (SupabaseService.isReady) {
        await SupabaseService.client.auth.signOut();
      }
    } catch (_) {}

    await AuthService.clearTokens();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _lastAuthAt = null;
    _error = reason;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final updates = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('profiles')
          .update(updates)
          .eq('id', currentUser.id);

      _user = {
        ...?_user,
        ...updates,
      };
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to update your profile.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount({String? password}) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.client.from('profiles').update({
        'email': null,
        'phone': null,
        'full_name': 'Deleted User',
        'avatar_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      await logout();
      return true;
    } catch (_) {
      _error = 'Unable to delete this account right now.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
