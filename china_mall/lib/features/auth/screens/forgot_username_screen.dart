import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/auth_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class ForgotUsernameScreen extends StatefulWidget {
  const ForgotUsernameScreen({super.key});

  @override
  State<ForgotUsernameScreen> createState() => _ForgotUsernameScreenState();
}

class _ForgotUsernameScreenState extends State<ForgotUsernameScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.forgotUsername(_emailController.text.trim());
      if (res['statusCode'] == 200) {
        setState(() => _sent = true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['email']?[0] ?? 'Something went wrong.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Username')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 80, color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    'Username sent!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your username has been sent to ${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recover your username',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the email address linked to your account and we\'ll send you your username.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Send Username',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
