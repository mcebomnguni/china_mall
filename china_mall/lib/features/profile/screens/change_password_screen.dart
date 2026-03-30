import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
 
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
 
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _oldCtrl    = TextEditingController();
  final _newCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
 
  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true; // was sharing _obscureNew — now independent
  bool _saving         = false;
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    // Rebuild strength bar whenever new password changes.
    _newCtrl.addListener(() => setState(() {}));
  }
 
  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }
 
  // ── Password strength ──────────────────────────────────────────────────────
 
  /// Returns 0–4 representing password strength.
  int _strength(String pw) {
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8)  score++;
    if (pw.length >= 12) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score.clamp(0, 4);
  }
 
  Color _strengthColor(int score) {
    switch (score) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return AppColors.success;
      default: return AppColors.border;
    }
  }
 
  String _strengthLabel(int score) {
    switch (score) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }
 
  // ── Submit ─────────────────────────────────────────────────────────────────
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
 
    final res = await ApiService.changePassword(
      _oldCtrl.text,
      _newCtrl.text,
      _confirmCtrl.text,
    );
 
    if (!mounted) return;
    setState(() => _saving = false);
 
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safePop();
    } else {
      // Clear password fields on failure so user starts fresh.
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final newPw   = _newCtrl.text;
    final score   = _strength(newPw);
    final strengthColor = _strengthColor(score);
    final strengthLabel = _strengthLabel(score);
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // ── Security header ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.lock_shield_fill,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure your account',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Use at least 8 characters with uppercase letters, numbers, and symbols.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
 
              // ── Current password ──────────────────────────────────────
              TextFormField(
                controller: _oldCtrl,
                obscureText: _obscureOld,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(CupertinoIcons.lock,
                      color: AppColors.textTertiary),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureOld = !_obscureOld),
                    child: Icon(
                      _obscureOld
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your current password'
                    : null,
              ),
              const SizedBox(height: 16),
 
              // ── New password ──────────────────────────────────────────
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(CupertinoIcons.lock_fill,
                      color: AppColors.textTertiary),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    child: Icon(
                      _obscureNew
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (v == _oldCtrl.text) {
                    return 'New password must differ from current';
                  }
                  return null;
                },
              ),
 
              // ── Strength indicator ────────────────────────────────────
              if (newPw.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 4 segment bar
                    Expanded(
                      child: Row(
                        children: List.generate(4, (i) {
                          final filled = i < score;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 4,
                              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: filled
                                    ? strengthColor
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        strengthLabel,
                        key: ValueKey(strengthLabel),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: strengthColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
 
              const SizedBox(height: 16),
 
              // ── Confirm password ──────────────────────────────────────
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm, // independent toggle
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(CupertinoIcons.lock_rotation,
                      color: AppColors.textTertiary),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                    child: Icon(
                      _obscureConfirm
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 36),
 
              // ── Submit button ─────────────────────────────────────────
              AppButton(
                label: 'Update Password',
                loading: _saving,
                onTap: _submit,
                icon: CupertinoIcons.checkmark_shield,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
