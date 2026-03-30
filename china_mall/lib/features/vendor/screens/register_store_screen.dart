import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class RegisterStoreScreen extends StatefulWidget {
  const RegisterStoreScreen({super.key});

  @override
  State<RegisterStoreScreen> createState() => _RegisterStoreScreenState();
}

class _RegisterStoreScreenState extends State<RegisterStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  int _step = 0;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _addressCtrl, _phoneCtrl, _emailCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final res = await ApiService.createStore({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    });

    setState(() => _saving = false);
    if (!mounted) return;

    if (res.isSuccess) {
      setState(() => _step = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Your Store'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _step == 2 ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.gradientRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏪', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text(
                    'Start selling\non China Stall Market Place',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your store will be reviewed by our team\nbefore going live — usually within 24hrs.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Store Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Store Name',
                prefixIcon: Icon(CupertinoIcons.house_fill,
                    color: AppColors.textTertiary),
              ),
              validator: (v) =>
                  v == null || v.trim().length < 3
                      ? 'Store name must be at least 3 characters'
                      : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell customers what you sell...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(CupertinoIcons.text_alignleft,
                      color: AppColors.textTertiary),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().length < 10
                      ? 'Please write at least 10 characters'
                      : null,
            ),
            const SizedBox(height: 24),

            Text('Contact Info',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Business Email',
                prefixIcon: Icon(CupertinoIcons.mail,
                    color: AppColors.textTertiary),
              ),
              validator: (v) =>
                  v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Business Phone',
                prefixIcon: Icon(CupertinoIcons.phone,
                    color: AppColors.textTertiary),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your business phone' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                prefixIcon: Icon(CupertinoIcons.location,
                    color: AppColors.textTertiary),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your business address' : null,
            ),
            const SizedBox(height: 28),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You may be asked to upload proof of business documents '
                      'after registration for final approval.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              label: 'Submit Store Application',
              loading: _saving,
              onTap: _submit,
              icon: CupertinoIcons.checkmark_shield,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_circle_fill,
                color: AppColors.success, size: 56),
          ),
          const SizedBox(height: 24),
          Text('Application Submitted!',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Our team will review your store and get back to you '
            'within 24 hours. You\'ll be notified once approved.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AppButton(
            label: 'Go to Dashboard',
            onTap: () => context.go('/vendor'),
            icon: CupertinoIcons.chart_bar_fill,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Back to Home',
            outline: true,
            onTap: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}
