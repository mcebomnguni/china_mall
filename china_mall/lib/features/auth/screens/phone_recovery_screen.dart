import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/function_response_parser.dart';
import '../../../core/services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHONE NUMBER RECOVERY SCREEN (item #3)
// 3-step flow: Enter phone → Enter OTP → Set new password
// ─────────────────────────────────────────────────────────────────────────────

enum _PhoneStep { enterPhone, enterOtp, newPassword }

class PhoneRecoveryScreen extends StatefulWidget {
  final String purpose; // 'password_reset' or 'username_recovery'

  const PhoneRecoveryScreen({
    super.key,
    this.purpose = 'password_reset',
  });

  @override
  State<PhoneRecoveryScreen> createState() => _PhoneRecoveryScreenState();
}

class _PhoneRecoveryScreenState extends State<PhoneRecoveryScreen> {
  _PhoneStep _step = _PhoneStep.enterPhone;
  bool _loading = false;

  String _phone = '';
  String _resetToken = '';
  String? _recoveredUsername;  // ignore: unused_field

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  // ── Step 1: Request OTP ────────────────────────────────────────────────────

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Try Supabase Edge Function first
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('auth_phone_otp', body: {'phone_number': _phoneCtrl.text.trim(), 'purpose': widget.purpose});
        if (fnRes != null) {
          final parsed = FunctionResponseParser.parse(fnRes);
          _phone = _phoneCtrl.text.trim();
          setState(() => _step = _PhoneStep.enterOtp);
          final isSandbox = (parsed is Map && parsed['sandbox'] == true);
          _showSnack(isSandbox ? 'Sandbox mode: check your server console for the OTP.' : 'OTP sent to your phone.');
          return;
        }
      } catch (_) {}

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/phone-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _phoneCtrl.text.trim(),
          'purpose': widget.purpose,
        }),
      );
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _phone = _phoneCtrl.text.trim();
        setState(() => _step = _PhoneStep.enterOtp);
        final isSandbox = body['sandbox'] == true;
        _showSnack(isSandbox
            ? 'Sandbox mode: check your server console for the OTP.'
            : 'OTP sent to your phone.');
      } else {
        _showSnack(body['error'] ?? 'Failed to send OTP.', error: true);
      }
    } catch (_) {
      _showSnack('Network error. Please try again.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Try Supabase function first
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('auth_phone_otp_verify', body: {'phone_number': _phone, 'otp': _otpCtrl.text.trim()});
        if (fnRes != null) {
          final parsed = FunctionResponseParser.parse(fnRes);
          if (parsed is Map && parsed['verified'] == true) {
            if (parsed['purpose'] == 'username_recovery') {
              setState(() => _recoveredUsername = parsed['username']);
              _showUsernameDialog(parsed['username']);
            } else {
              _resetToken = parsed['reset_token'];
              setState(() => _step = _PhoneStep.newPassword);
            }
            return;
          } else {
            _showSnack(parsed['error'] ?? 'Invalid OTP.', error: true);
            return;
          }
        }
      } catch (_) {}

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/phone-otp/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _phone,
          'otp': _otpCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body['verified'] == true) {
        if (body['purpose'] == 'username_recovery') {
          // Username returned directly
          setState(() => _recoveredUsername = body['username']);
          _showUsernameDialog(body['username']);
        } else {
          _resetToken = body['reset_token'];
          setState(() => _step = _PhoneStep.newPassword);
        }
      } else {
        _showSnack(body['error'] ?? 'Invalid OTP.', error: true);
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Step 3: Reset password ─────────────────────────────────────────────────

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Try Supabase function first
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('auth_phone_reset', body: {
          'phone_number': _phone,
          'reset_token': _resetToken,
          'new_password': _newPasswordCtrl.text,
          'confirm_password': _confirmPasswordCtrl.text,
        });
        if (fnRes != null) {
          if (!mounted) return;
          _showSnack('Password reset successfully!');
          Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }
      } catch (_) {}

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/phone-reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _phone,
          'reset_token': _resetToken,
          'new_password': _newPasswordCtrl.text,
          'confirm_password': _confirmPasswordCtrl.text,
        }),
      );
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (!mounted) return;
        _showSnack('Password reset successfully!');
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final error = body['error'];
        _showSnack(
          error is List ? error.join('\n') : error ?? 'Failed.',
          error: true,
        );
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showUsernameDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Your Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your username is:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(username,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == 'username_recovery'
            ? 'Recover Username'
            : 'Reset via Phone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              _StepIndicator(
                steps: widget.purpose == 'username_recovery'
                    ? ['Phone', 'OTP', 'Done']
                    : ['Phone', 'OTP', 'New Password'],
                current: _step.index,
              ),
              const SizedBox(height: 32),

              // ── Step 1: Phone number ───────────────────────────────────
              if (_step == _PhoneStep.enterPhone) ...[
                const Text('Enter your phone number',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  widget.purpose == 'username_recovery'
                      ? 'We\'ll send a code to verify it\'s you, then show your username.'
                      : 'We\'ll send a 6-digit code to reset your password.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0821234567',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.replaceAll(' ', '').length < 10) {
                      return 'Enter a valid SA phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _ActionButton(
                  label: 'Send OTP',
                  loading: _loading,
                  onPressed: _requestOtp,
                ),
              ],

              // ── Step 2: OTP ────────────────────────────────────────────
              if (_step == _PhoneStep.enterOtp) ...[
                const Text('Enter OTP',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('A 6-digit code was sent to $_phone',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28, letterSpacing: 12),
                  decoration: InputDecoration(
                    hintText: '------',
                    counterText: '',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.length != 6
                      ? 'Enter the 6-digit OTP'
                      : null,
                ),
                const SizedBox(height: 24),
                _ActionButton(
                  label: 'Verify OTP',
                  loading: _loading,
                  onPressed: _verifyOtp,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _step = _PhoneStep.enterPhone;
                              _otpCtrl.clear();
                            }),
                    child: const Text('Change phone number'),
                  ),
                ),
              ],

              // ── Step 3: New password ───────────────────────────────────
              if (_step == _PhoneStep.newPassword) ...[
                const Text('Set New Password',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.length < 8
                      ? 'Minimum 8 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      v != _newPasswordCtrl.text
                          ? 'Passwords do not match'
                          : null,
                ),
                const SizedBox(height: 24),
                _ActionButton(
                  label: 'Reset Password',
                  loading: _loading,
                  onPressed: _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int current;
  const _StepIndicator({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: done
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: done ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i],
                      style: TextStyle(
                          fontSize: 10,
                          color: done
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey)),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: i < current
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _ActionButton(
      {required this.label,
      required this.loading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
