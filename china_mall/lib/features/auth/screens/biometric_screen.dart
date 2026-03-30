import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';

/// Screen shown after login to let user enable fingerprint/face unlock
class BiometricSetupScreen extends StatefulWidget {
  final String userId;
  final String accessToken;

  const BiometricSetupScreen({
    super.key,
    required this.userId,
    required this.accessToken,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _loading = false;
  bool _available = false;
  List<BiometricType> _types = [];

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    _available = await BiometricService.isAvailable();
    _types = await BiometricService.getAvailableBiometrics();
    setState(() {});
  }

  String get _biometricLabel {
    if (_types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (_types.contains(BiometricType.face)) return 'Face ID';
    return 'Biometric';
  }

  Future<void> _enableBiometric() async {
    setState(() => _loading = true);
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'Scan your $_biometricLabel to enable quick sign-in',
      );
      if (!authenticated) {
        _showSnack('Biometric verification failed.', error: true);
        return;
      }

      final token =
          await BiometricService.generateBiometricToken(widget.userId);
      final res =
          await AuthService.registerBiometric(token, widget.accessToken);

      if (res['statusCode'] == 200) {
        await AuthService.saveBiometricToken(token);
        _showSnack('$_biometricLabel login enabled!');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(res['error'] ?? 'Failed to register biometric.', error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Sign-In Setup')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _types.contains(BiometricType.face)
                  ? Icons.face_unlock_outlined
                  : Icons.fingerprint,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Enable $_biometricLabel Login',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in faster with your $_biometricLabel instead of typing your password every time.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 48),
            if (!_available)
              const Text(
                'Biometric authentication is not available on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Enable $_biometricLabel'),
                  onPressed: _loading ? null : _enableBiometric,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip for now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget to show biometric login button on the login screen
class BiometricLoginButton extends StatefulWidget {
  final VoidCallback onSuccess;

  const BiometricLoginButton({super.key, required this.onSuccess});

  @override
  State<BiometricLoginButton> createState() => _BiometricLoginButtonState();
}

class _BiometricLoginButtonState extends State<BiometricLoginButton> {
  bool _hasBiometric = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AuthService.getBiometricToken();
    final available = await BiometricService.isAvailable();
    setState(() => _hasBiometric = token != null && available);
  }

  Future<void> _login() async {
    final authenticated = await BiometricService.authenticate(
      reason: 'Sign in to ChinaMall',
    );
    if (!authenticated) return;

    final token = await AuthService.getBiometricToken();
    if (token == null) return;

    final res = await AuthService.biometricLogin(token);
    if (res['statusCode'] == 200) {
      widget.onSuccess();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Biometric login failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBiometric) return const SizedBox.shrink();
    return IconButton(
      onPressed: _login,
      icon: const Icon(Icons.fingerprint, size: 48),
      color: Theme.of(context).colorScheme.primary,
      tooltip: 'Sign in with fingerprint',
    );
  }
}
