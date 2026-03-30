import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometrics are available on this device
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using biometrics — returns true if successful
  static Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }

  /// Generate a unique device + user token to store server-side
  static Future<String> generateBiometricToken(String userId) async {
    String deviceId = 'unknown';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? 'ios_unknown';
      }
    } catch (_) {}

    final raw = '$userId:$deviceId:chinamall_biometric_salt_2026';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
