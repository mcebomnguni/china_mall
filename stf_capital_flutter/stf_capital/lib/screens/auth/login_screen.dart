// ─────────────────────────────────────────────────────────────────────────────
//  screens/auth/login_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

const bool _enableDemoLogin = bool.fromEnvironment(
  'ENABLE_DEMO_LOGIN',
  defaultValue: true,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _idCtrl    = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final auth = context.read<AuthService>();
    final err  = await auth.login(
      emailOrUsername: _idCtrl.text,
      password:        _passCtrl.text,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go(auth.isAdmin ? '/admin' : '/dashboard');
    }
  }

  Future<void> _demoClient() async {
    setState(() => _error = null);
    final auth = context.read<AuthService>();
    final err = await auth.demoLoginClient();

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go(auth.isAdmin ? '/admin' : '/dashboard');
    }
  }

  Future<void> _demoAdmin() async {
    setState(() => _error = null);
    final auth = context.read<AuthService>();
    final err = await auth.demoLoginAdmin();

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go(auth.isAdmin ? '/admin' : '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthService>();
    final isWide   = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 24, vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo
                    Center(child: StfLogo(size: 52)),
                    const SizedBox(height: 40),

                    // ── Heading
                    Text('Welcome Back',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text('Sign in to your STF Capital account',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Center(child: GoldDivider(width: 50)),
                    const SizedBox(height: 36),

                    // ── Error
                    if (_error != null)
                      ErrorBanner(
                        message:   _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),

                    // ── Fields
                    GoldTextField(
                      controller:  _idCtrl,
                      label:       'Email Address or Username',
                      prefixIcon:  Icons.person_outline_rounded,
                      validator:   (v) =>
                          (v?.isEmpty ?? true) ? 'Please enter your email or username' : null,
                    ),
                    const SizedBox(height: 16),

                    GoldTextField(
                      controller:  _passCtrl,
                      label:       'Password',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscureText: _obscure,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18, color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 10),

                    // ── Forgot links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/forgot-username'),
                          child: const Text('Forgot Username?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Submit
                    GoldButton(
                      label:     'Sign In',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                    const SizedBox(height: 28),

                    if (_enableDemoLogin) ...[
                      Row(
                        children: [
                          Expanded(
                            child: GoldButton(
                              label: 'Demo Client',
                              onPressed: auth.isLoading ? null : _demoClient,
                              isLoading: auth.isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GoldButton(
                              label: 'Demo Admin',
                              onPressed: auth.isLoading ? null : _demoAdmin,
                              isLoading: auth.isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New to STF Capital?  ',
                          style: GoogleFonts.montserrat(
                            fontSize: 13, color: AppTheme.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: ShaderMask(
                            shaderCallback: (r) =>
                                AppTheme.goldGradientSimple.createShader(r),
                            child: Text('Create an Account',
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
                    const SizedBox(height: 30),

                    // ── Privacy Policy
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/privacy-policy'),
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.montserrat(
                            fontSize: 11, color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
