import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form    = GlobalKey<FormState>();
  final _fname   = TextEditingController();
  final _lname   = TextEditingController();
  final _email   = TextEditingController();
  final _user    = TextEditingController();
  final _pass    = TextEditingController();
  final _confirm = TextEditingController();
  String _role   = 'buyer';
  bool _obscure  = true;
  
  // New state for Privacy Policy
  bool _acceptedTerms = false;

  static const _roles = [
    {'key': 'buyer',   'label': 'Customer',    'icon': CupertinoIcons.device_phone_portrait, 'desc': 'Shop & track orders'},
    {'key': 'vendor',  'label': 'Store Owner', 'icon': CupertinoIcons.house_fill,      'desc': 'Sell your products'},
    {'key': 'courier', 'label': 'Courier',     'icon': CupertinoIcons.car_fill,              'desc': 'Deliver & earn'},
  ];

  @override
  void dispose() {
    for (final c in [_fname, _lname, _email, _user, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    // 1. Validation check
    if (!_form.currentState!.validate()) return;

    // 2. Privacy Policy check
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Privacy Policy to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok   = await auth.register({
      'first_name': _fname.text.trim(),
      'last_name':  _lname.text.trim(),
      'email':      _email.text.trim(),
      'username':   _user.text.trim(),
      'password':   _pass.text,
      'password_confirm': _confirm.text,
      'role':       _role,
    });

    if (!mounted) return;

    if (ok) {
      if (_role == 'vendor') {
        // Auto-login vendor and take them straight to store setup
        final loginOk = await auth.login(_email.text.trim(), _pass.text);
        if (!mounted) return;
        if (loginOk) {
          context.go('/vendor/setup');
        } else {
          // Email confirmation required — sign in first, then complete store setup
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created! Sign in to complete your store setup.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      } else {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created! Please sign in.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                      child: Container(
                        width: 36, 
                        height: 36, 
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5), 
                          borderRadius: BorderRadius.circular(11)
                        ), 
                        child: const Icon(CupertinoIcons.back, size: 16)
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Create Account', style: TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Join China Stall today', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 28),

                // Role picker
                const Text('I WANT TO', style: TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textTertiary)),
                const SizedBox(height: 10),
                Row(
                  children: _roles.map((r) {
                    final sel = _role == r['key'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = r['key'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(r['icon'] as IconData, size: 20, color: sel ? Colors.white : AppColors.textSecondary),
                              const SizedBox(height: 5),
                              Text(r['label'] as String, style: TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w900, color: sel ? Colors.white : AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Fields
                Row(children: [
                  Expanded(child: _Field(ctrl: _fname, hint: 'First Name', validator: (v) => Validators.name(v, min: 1))),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(ctrl: _lname, hint: 'Last Name', validator: (v) => Validators.name(v, min: 1))),
                ]),
                const SizedBox(height: 10),
                _Field(ctrl: _email, hint: 'Email Address', keyboard: TextInputType.emailAddress, validator: Validators.email),
                const SizedBox(height: 10),
                _Field(ctrl: _user, hint: 'Username', validator: (v) => Validators.name(v, min: 3, max: 30)),
                const SizedBox(height: 10),
                _Field(
                  ctrl: _pass, 
                  hint: 'Password', 
                  obscure: _obscure, 
                  validator: Validators.password, 
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure), 
                    child: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 16, color: AppColors.textTertiary)
                  )
                ),
                const SizedBox(height: 10),
                _Field(ctrl: _confirm, hint: 'Confirm Password', obscure: true, validator: (v) => Validators.confirmPassword(v, _pass.text)),
                
                const SizedBox(height: 20),

                // Privacy Policy Toggle
                GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _acceptedTerms = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  label: 'CREATE ACCOUNT', 
                  loading: auth.loading, 
                  // Button turns grey/disabled if terms aren't accepted
                  onTap: _acceptedTerms ? _submit : null,
                ),
                
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.textTertiary)),
                  GestureDetector(onTap: () => context.go('/login'), child: const Text('Sign In', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w900, decoration: TextDecoration.underline))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({required this.ctrl, required this.hint, this.obscure = false, this.keyboard = TextInputType.text, this.validator, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
      ),
    );
  }
}
