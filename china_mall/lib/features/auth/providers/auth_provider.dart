import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  // Security — safe even if columns don't exist yet (pre-migration)
  String get securityMethod => _user?['security_method']?.toString() ?? 'none';
  bool get hasPin => securityMethod == 'pin' || securityMethod == 'both';
  bool get needsSecuritySetup {
    // Only prompt if the column actually exists in the profile data
    if (_user == null) return false;
    if (!_user!.containsKey('security_method')) return false;
    return _user!['security_method'] == null || _user!['security_method'] == 'none';
  }
  String get accountStatus => _user?['account_status']?.toString() ?? 'active';

  Future<void> init() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    await _loadOnboarding();
    await _restoreLocalSessionState();
    _listenToAuthChanges();

    await Future.wait([
      checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 3500)), // minimum splash display
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
      debugPrint('[Auth] Attempting login for: $email');
      debugPrint('[Auth] Supabase ready: ${SupabaseService.isReady}');
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
      try {
        await NotificationService.registerToken();
      } catch (_) {}
      _user = await _loadSupabaseProfile();

      // Check if account is suspended — auto-restore within 6 months
      // Only check if column exists in profile (post-migration)
      if (_user?.containsKey('account_status') == true &&
          _user?['account_status'] == 'suspended') {
        final restored = await restoreAccount();
        if (!restored) {
          await logout(reason: 'Your account could not be restored. The recovery period may have expired.');
          return false;
        }
      }

      _status = AuthStatus.authenticated;

      // Register device and check trust
      await registerDevice();

      return true;
    } on AuthException catch (e) {
      debugPrint('[Auth] AuthException: ${e.message} (statusCode: ${e.statusCode})');
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials')) {
        _error =
            'Incorrect email or password. If you just registered, please confirm your email first.';
      } else if (msg.contains('email not confirmed')) {
        _error = 'Please confirm your email address before signing in.';
      } else if (msg.contains('too many requests') ||
          msg.contains('rate limit')) {
        _error = 'Too many attempts. Please wait a moment and try again.';
      } else {
        _error = e.message;
      }
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _error = 'Unable to sign in right now. Check your internet connection.';
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
      // Soft delete: suspend account for 6 months, then auto-delete
      await SupabaseService.client.rpc('request_account_deletion', params: {
        'p_user_id': currentUser.id,
      });
      await logout(reason: 'Your account has been suspended. You can recover it within 6 months by logging in again.');
      return true;
    } catch (_) {
      _error = 'Unable to delete this account right now.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Restore a suspended account after user logs in
  Future<bool> restoreAccount() async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final result = await SupabaseService.client.rpc('restore_account', params: {
        'p_user_id': currentUser.id,
      });
      if (result == true) {
        _user = await _loadSupabaseProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set a login PIN
  Future<bool> setLoginPin(String pin) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      await SupabaseService.client.rpc('set_login_pin', params: {
        'p_user_id': currentUser.id,
        'p_pin': pin,
      });
      _user?['security_method'] = 'pin';
      notifyListeners();
      return true;
    } catch (e) {
      // RPC may not exist yet if migration hasn't run
      debugPrint('setLoginPin error: $e');
      _error = 'PIN setup is not available yet. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  /// Verify login PIN
  Future<bool> verifyPin(String pin) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final result = await SupabaseService.client.rpc('verify_login_pin', params: {
        'p_user_id': currentUser.id,
        'p_pin': pin,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Update security method preference
  Future<bool> setSecurityMethod(String method) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      await SupabaseService.client.rpc('set_security_method', params: {
        'p_user_id': currentUser.id,
        'p_method': method,
      });
      _user?['security_method'] = method;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('setSecurityMethod error: $e');
      return false;
    }
  }

  // ── Device linking ─────────────────────────────────────────────────────────

  bool _deviceTrusted = true; // assume trusted until proven otherwise
  bool get isDeviceTrusted => _deviceTrusted;
  bool _needsDeviceVerification = false;
  bool get needsDeviceVerification => _needsDeviceVerification;

  /// Get device fingerprint info
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return {
          'device_id': info.id,
          'device_name': '${info.brand} ${info.model}',
          'device_os': 'Android ${info.version.release}',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        return {
          'device_id': info.identifierForVendor ?? 'unknown',
          'device_name': info.name,
          'device_os': '${info.systemName} ${info.systemVersion}',
        };
      }
    } catch (e) {
      debugPrint('DeviceInfo error: $e');
    }
    return {'device_id': 'web-${DateTime.now().millisecondsSinceEpoch}', 'device_name': 'Web Browser', 'device_os': 'Web'};
  }

  /// Register current device after login, returns whether device is trusted
  Future<bool> registerDevice() async {
    if (!SupabaseService.isReady) return true; // skip if not ready
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return true;

    try {
      final info = await _getDeviceInfo();
      final result = await SupabaseService.client.rpc('register_device', params: {
        'p_user_id': currentUser.id,
        'p_device_id': info['device_id'],
        'p_device_name': info['device_name'],
        'p_device_os': info['device_os'],
      });

      if (result is Map) {
        final trusted = result['is_trusted'] == true;
        final isNew = result['is_new_device'] == true;
        _deviceTrusted = trusted;
        _needsDeviceVerification = isNew && !trusted;
        notifyListeners();
        return trusted;
      }
      return true;
    } catch (e) {
      debugPrint('registerDevice error: $e');
      return true; // don't block login if function doesn't exist yet
    }
  }

  /// Request device verification code (sent to email)
  Future<String?> requestDeviceVerificationCode() async {
    if (!SupabaseService.isReady) return null;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final info = await _getDeviceInfo();
      final code = await SupabaseService.client.rpc('generate_device_verification_code', params: {
        'p_user_id': currentUser.id,
        'p_device_id': info['device_id'],
      });
      return code?.toString();
    } catch (e) {
      debugPrint('requestDeviceVerificationCode error: $e');
      return null;
    }
  }

  /// Verify device with code + PIN
  Future<bool> verifyDeviceWithCode(String code) async {
    if (!SupabaseService.isReady) return false;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final info = await _getDeviceInfo();
      final result = await SupabaseService.client.rpc('verify_device_code', params: {
        'p_user_id': currentUser.id,
        'p_device_id': info['device_id'],
        'p_code': code,
      });
      if (result == true) {
        _deviceTrusted = true;
        _needsDeviceVerification = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('verifyDeviceWithCode error: $e');
      return false;
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
