// ─────────────────────────────────────────────────────────────────────────────
//  screens/auth/forgot_screens.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── Forgot Password ───────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _sent       = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final err = await context.read<AuthService>().sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    if (err != null) setState(() => _error = err);
    else             setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _successView() : _formView(auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView(AuthService auth) => Form(
    key: _formKey,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_outlined,
            color: AppTheme.goldLight, size: 52),
        const SizedBox(height: 24),
        Text('Reset Password',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email address associated with your account and we will send you a password reset link.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Center(child: GoldDivider(width: 50)),
        const SizedBox(height: 36),
        if (_error != null)
          ErrorBanner(
            message:   _error!,
            onDismiss: () => setState(() => _error = null),
          ),
        GoldTextField(
          controller:   _emailCtrl,
          label:        'Email Address',
          prefixIcon:   Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator:    (v) {
            if (v?.isEmpty ?? true) return 'Please enter your email';
            if (!v!.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 24),
        GoldButton(
          label:     'Send Reset Link',
          onPressed: _submit,
          isLoading: auth.isLoading,
        ),
      ],
    ),
  );

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.mark_email_read_outlined,
          color: AppTheme.statusApproved, size: 60),
      const SizedBox(height: 24),
      Text('Email Sent',
        style: Theme.of(context).textTheme.displaySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        'A password reset link has been sent to ${_emailCtrl.text}. Please check your inbox and follow the instructions.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 36),
      GoldButton(
        label:     'Return to Sign In',
        onPressed: () => context.go('/login'),
      ),
    ],
  );
}

// ── Forgot Username ───────────────────────────────────────────────────────────
class ForgotUsernameScreen extends StatefulWidget {
  const ForgotUsernameScreen({super.key});
  @override
  State<ForgotUsernameScreen> createState() => _ForgotUsernameScreenState();
}

class _ForgotUsernameScreenState extends State<ForgotUsernameScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  String? _result;
  String? _error;
  bool _searched = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _searched = false; });
    final auth     = context.read<AuthService>();
    final username = await auth.recoverUsername(_emailCtrl.text);
    if (!mounted) return;
    if (username == null) {
      setState(() {
        _error    = 'No account was found with this email address.';
        _searched = true;
      });
    } else {
      setState(() { _result = username; _searched = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_search_outlined,
                        color: AppTheme.goldLight, size: 52),
                    const SizedBox(height: 24),
                    Text('Recover Username',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the email address linked to your account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Center(child: GoldDivider(width: 50)),
                    const SizedBox(height: 36),

                    if (_error != null)
                      ErrorBanner(
                        message:   _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),

                    if (_result != null)
                      Container(
                        margin:  const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:  AppTheme.statusApproved.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.statusApproved.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppTheme.statusApproved, size: 36),
                            const SizedBox(height: 12),
                            Text('Your Username',
                              style: GoogleFonts.montserrat(
                                fontSize: 12, color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_result!,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 28, color: AppTheme.goldLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    GoldTextField(
                      controller:   _emailCtrl,
                      label:        'Email Address',
                      prefixIcon:   Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator:    (v) {
                        if (v?.isEmpty ?? true) return 'Please enter your email';
                        if (!v!.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      label:     'Recover Username',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      GoldButton(
                        label:    'Go to Sign In',
                        onPressed: () => context.go('/login'),
                        outlined: true,
                      ),
                    ],
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
