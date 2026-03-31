import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/supabase_service.dart';

enum _RecoveryMode { password, email }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  _RecoveryMode _mode = _RecoveryMode.password;
  bool _loading = false;
  bool _sent = false;
  String? _maskedEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Mode 1: Forgot Password ─────────────────────────────────────────────────
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _sent = false;
    });

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to send reset link. Please try again.',
            style: TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Mode 2: Forgot Email / Username ─────────────────────────────────────────
  Future<void> _recoverAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _sent = false;
      _maskedEmail = null;
    });

    try {
      final phone = _phoneCtrl.text.trim();
      final result = await SupabaseService.client
          .from('profiles')
          .select('email')
          .eq('phone', phone)
          .maybeSingle();

      if (!mounted) return;

      if (result == null || result['email'] == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No account found with this phone number.',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final email = result['email'] as String;
      final masked = _maskEmail(email);

      // Send the reset link to the found email
      await SupabaseService.client.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      setState(() {
        _maskedEmail = masked;
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Something went wrong. Please try again.',
            style: TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 1) return '$local***@$domain';
    return '${local[0]}${'*' * (local.length - 1)}@$domain';
  }

  void _switchMode(_RecoveryMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _sent = false;
      _maskedEmail = null;
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.brightness == Brightness.dark
              ? AppColors.darkHeroGradient
              : AppColors.heroGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back button ────────────────────────────────────
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      CupertinoIcons.back,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ── Title ──────────────────────────────────────────
                Text(
                  'Account recovery',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Reset your password or recover the email address linked to your account.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // ── Tab toggle ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildTab(
                        label: 'Forgot Password',
                        active: _mode == _RecoveryMode.password,
                        onTap: () => _switchMode(_RecoveryMode.password),
                      ),
                      _buildTab(
                        label: 'Forgot Email',
                        active: _mode == _RecoveryMode.email,
                        onTap: () => _switchMode(_RecoveryMode.email),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _sent ? _buildSuccessContent() : _buildFormContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab widget ────────────────────────────────────────────────────────────────
  Widget _buildTab({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.white : AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form content (before sending) ─────────────────────────────────────────────
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mode == _RecoveryMode.password) ...[
            const Text(
              'Enter your email',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'We\'ll send a password reset link to your inbox.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(CupertinoIcons.mail),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
              onFieldSubmitted: (_) => _sendResetLink(),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'SEND RESET LINK',
              loading: _loading,
              onTap: _sendResetLink,
            ),
          ],
          if (_mode == _RecoveryMode.email) ...[
            const Text(
              'Enter your phone number',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'We\'ll find the email linked to your phone and send a reset link.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(CupertinoIcons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
              onFieldSubmitted: (_) => _recoverAccount(),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'RECOVER ACCOUNT',
              loading: _loading,
              onTap: _recoverAccount,
            ),
          ],
        ],
      ),
    );
  }

  // ── Success content (after sending) ───────────────────────────────────────────
  Widget _buildSuccessContent() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 34,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        if (_mode == _RecoveryMode.password) ...[
          const Text(
            'Reset link sent!',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your email inbox. The link will expire in 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (_mode == _RecoveryMode.email) ...[
          const Text(
            'Account found!',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_maskedEmail != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.mail_solid,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _maskedEmail!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'A password reset link has been sent to this email.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: 'BACK TO LOGIN',
          onTap: () => context.go('/login'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _sent = false;
              _maskedEmail = null;
              _emailCtrl.clear();
              _phoneCtrl.clear();
            });
          },
          child: const Text(
            'Try again',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
