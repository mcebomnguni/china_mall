// ─────────────────────────────────────────────────────────────────────────────
//  screens/auth/register_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstCtrl     = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _companyCtrl   = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _agreeTerms     = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _firstCtrl, _lastCtrl, _usernameCtrl, _emailCtrl,
      _phoneCtrl, _companyCtrl, _passCtrl, _confirmCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      setState(() => _error = 'You must agree to the Privacy Policy to continue.');
      return;
    }
    setState(() => _error = null);

    final auth = context.read<AuthService>();
    final err  = await auth.register(
      email:       _emailCtrl.text,
      password:    _passCtrl.text,
      username:    _usernameCtrl.text,
      firstName:   _firstCtrl.text,
      lastName:    _lastCtrl.text,
      phone:       _phoneCtrl.text,
      companyName: _companyCtrl.text,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      // After registration go to document upload
      context.go('/onboarding/documents');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: BackButton(onPressed: () => context.pop()),
        title: const StfLogo(size: 32),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 24, vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create Account',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text('Register to access STF Capital services',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Center(child: GoldDivider(width: 50)),
                    const SizedBox(height: 32),

                    if (_error != null)
                      ErrorBanner(
                        message:   _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),

                    // ── Personal details
                    _label('Personal Information'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GoldTextField(
                            controller:         _firstCtrl,
                            label:              'First Name',
                            textCapitalization: TextCapitalization.words,
                            prefixIcon:         Icons.person_outline_rounded,
                            validator:          (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GoldTextField(
                            controller:         _lastCtrl,
                            label:              'Last Name',
                            textCapitalization: TextCapitalization.words,
                            validator:          (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GoldTextField(
                      controller: _phoneCtrl,
                      label:      'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator:  (v) =>
                          (v?.isEmpty ?? true) ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Company
                    _label('Company Details'),
                    const SizedBox(height: 12),
                    GoldTextField(
                      controller:         _companyCtrl,
                      label:              'Company Name',
                      prefixIcon:         Icons.business_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator:          (v) =>
                          (v?.isEmpty ?? true) ? 'Please enter your company name' : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Account credentials
                    _label('Account Credentials'),
                    const SizedBox(height: 12),

                    GoldTextField(
                      controller: _usernameCtrl,
                      label:      'Username',
                      prefixIcon: Icons.alternate_email_rounded,
                      validator:  (v) {
                        if (v?.isEmpty ?? true) return 'Please choose a username';
                        if (v!.length < 3) return 'Username must be at least 3 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                          return 'Only letters, numbers and underscores allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    GoldTextField(
                      controller:  _emailCtrl,
                      label:       'Email Address',
                      prefixIcon:  Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator:   (v) {
                        if (v?.isEmpty ?? true) return 'Please enter your email';
                        if (!v!.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    GoldTextField(
                      controller:  _passCtrl,
                      label:       'Password',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscureText: _obscurePass,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18, color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Please enter a password';
                        if (v!.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    GoldTextField(
                      controller:  _confirmCtrl,
                      label:       'Confirm Password',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18, color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Agree terms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value:            _agreeTerms,
                            onChanged:        (v) =>
                                setState(() => _agreeTerms = v ?? false),
                            activeColor:      AppTheme.goldLight,
                            side: const BorderSide(color: AppTheme.darkBorder),
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.montserrat(
                                fontSize: 12, color: AppTheme.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: AppTheme.goldLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/privacy-policy'),
                                ),
                                const TextSpan(text: ' and consent to the processing of my personal information.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    GoldButton(
                      label:     'Create Account',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Already have an account?  ',
                            style: GoogleFonts.montserrat(
                              fontSize: 13, color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: ShaderMask(
                              shaderCallback: (r) =>
                                  AppTheme.goldGradientSimple.createShader(r),
                              child: Text('Sign In',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.montserrat(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: AppTheme.goldLight, letterSpacing: 1.5,
    ),
  );
}
