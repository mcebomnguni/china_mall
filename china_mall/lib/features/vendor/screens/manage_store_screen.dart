import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class ManageStoreScreen extends StatefulWidget {
  const ManageStoreScreen({super.key});
 
  @override
  State<ManageStoreScreen> createState() => _ManageStoreScreenState();
}
 
class _ManageStoreScreenState extends State<ManageStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map? _store;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _phoneCtrl, _emailCtrl, _addressCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }
 
  Future<void> _load() async {
    final res = await ApiService.getMyStore();
    if (!mounted) return;
    if (res.isSuccess) {
      _store = res.data;
      _nameCtrl.text = _store?['name'] ?? '';
      _descCtrl.text = _store?['description'] ?? '';
      _phoneCtrl.text = _store?['phone'] ?? '';
      _emailCtrl.text = _store?['email'] ?? '';
      _addressCtrl.text = _store?['address'] ?? '';
    }
    setState(() => _loading = false);
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
 
    final res = await ApiService.updateMyStore({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
 
    setState(() => _saving = false);
    if (!mounted) return;
 
    if (res.isSuccess) {
      setState(() => _store = res.data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: const Text('Manage Store'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store status banner
                  if (_store != null)
                    _StatusBanner(status: _store!['status'] ?? 'pending'),
 
                  const SizedBox(height: 20),
 
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Store Info',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
 
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              const InputDecoration(labelText: 'Store Name'),
                          validator: (v) =>
                              v == null || v.trim().length < 3
                                  ? 'Min 3 characters'
                                  : null,
                        ),
                        const SizedBox(height: 12),
 
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 24),
 
                        Text('Contact',
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
 
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(labelText: 'Business Email'),
                          validator: (v) =>
                              v != null && v.isNotEmpty && !v.contains('@')
                                  ? 'Invalid email'
                                  : null,
                        ),
                        const SizedBox(height: 12),
 
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(labelText: 'Business Phone'),
                        ),
                        const SizedBox(height: 12),
 
                        TextFormField(
                          controller: _addressCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Business Address'),
                        ),
                        const SizedBox(height: 32),
 
                        AppButton(
                          label: 'Save Changes',
                          loading: _saving,
                          onTap: _save,
                          icon: CupertinoIcons.checkmark,
                        ),
                      ],
                    ),
                  ),
 
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
 
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});
 
  Color get _color {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'suspended':
      case 'banned': return AppColors.error;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }
 
  String get _message {
    switch (status) {
      case 'approved':
        return '✅  Your store is live and visible to buyers.';
      case 'pending':
        return '⏳  Your store is under review. Usually takes 24 hours.';
      case 'suspended':
        return '⚠️  Your store has been suspended. Contact support.';
      case 'rejected':
        return '❌  Your application was rejected. Contact support.';
      default:
        return 'Store status: $status';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _message,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: _color,
        ),
      ),
    );
  }
}
 
