import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/auth_text_field.dart';
import '../../../core/widgets/primary_button.dart';

enum _Step { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  bool _loading = false;
  String _email = '';
  String _resetToken = '';

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.forgotPassword(_emailController.text.trim());
      if (res['message'] != null) {
        _email = _emailController.text.trim();
        setState(() => _step = _Step.otp);
        _showSnack('OTP sent to your email.');
      } else {
        _showSnack(res['email']?[0] ?? 'Something went wrong.', error: true);
      }
    } catch (_) {
      _showSnack('Network error. Please try again.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.verifyOtp(_email, _otpController.text.trim());
      if (res['statusCode'] == 200) {
        _resetToken = res['reset_token'];
        setState(() => _step = _Step.newPassword);
      } else {
        _showSnack(res['error'] ?? 'Invalid OTP.', error: true);
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.resetPassword(
        email: _email,
        token: _resetToken,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (res['statusCode'] == 200) {
        if (!mounted) return;
        _showSnack('Password reset successfully!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showSnack(res['error'] ?? 'Failed to reset password.', error: true);
      }
    } catch (_) {
      _showSnack('Network error.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _StepIndicator(current: _step),
              const SizedBox(height: 32),

              if (_step == _Step.email) ...[
                const Text('Enter your email address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('We\'ll send a 6-digit OTP to reset your password.'),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Send OTP',
                  loading: _loading,
                  onPressed: _submitEmail,
                ),
              ],

              if (_step == _Step.otp) ...[
                const Text('Enter OTP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('A 6-digit code was sent to $_email'),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _otpController,
                  label: 'OTP Code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) =>
                      v == null || v.length != 6 ? 'Enter the 6-digit OTP' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Verify OTP',
                  loading: _loading,
                  onPressed: _submitOtp,
                ),
              ],

              if (_step == _Step.newPassword) ...[
                const Text('Set New Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (v) => v != _newPasswordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Reset Password',
                  loading: _loading,
                  onPressed: _submitNewPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final _Step current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Email', 'OTP', 'New Password'];
    final currentIndex = _Step.values.indexOf(current);
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= currentIndex;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontSize: 12)),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
