import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'vendor_onboarding_formal_screen.dart'
    show _DocUploadTile, _InfoBox, _SectionHeader;

class VendorOnboardingInformalScreen extends StatefulWidget {
  const VendorOnboardingInformalScreen({super.key});

  @override
  State<VendorOnboardingInformalScreen> createState() =>
      _VendorOnboardingInformalScreenState();
}

class _VendorOnboardingInformalScreenState
    extends State<VendorOnboardingInformalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  int _step = 0; // 0 = contact, 1 = documents, 2 = workers, 3 = success
  bool _saving = false;

  // Documents
  PlatformFile? _idFile;
  PlatformFile? _permitFile;
  PlatformFile? _affidavitFile;
  PlatformFile? _proofOfAccountFile;

  // Workers
  final List<_WorkerEntry> _workers = [];

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    for (final w in _workers) w.dispose();
    super.dispose();
  }

  Future<String?> _uploadFile(
      PlatformFile file, String userId, String docType) async {
    try {
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return null;
      final path = '$userId/$docType/${file.name}';
      await SupabaseService.client.storage.from('vendor-docs').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return SupabaseService.client.storage
          .from('vendor-docs')
          .getPublicUrl(path);
    } catch (_) {
      return 'pending:${file.name}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idFile == null ||
        _permitFile == null ||
        _affidavitFile == null ||
        _proofOfAccountFile == null) {
      _showError('Please upload all four required documents.');
      return;
    }

    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final idUrl = await _uploadFile(_idFile!, userId, 'id_document');
      final permitUrl = await _uploadFile(_permitFile!, userId, 'permit');
      final affidavitUrl =
          await _uploadFile(_affidavitFile!, userId, 'affidavit');
      final proofUrl =
          await _uploadFile(_proofOfAccountFile!, userId, 'proof_of_account');

      final workersData = <Map<String, dynamic>>[];
      for (final w in _workers) {
        if (w.nameCtrl.text.trim().isEmpty) continue;
        String? idUrl;
        if (w.idFile != null) {
          idUrl = await _uploadFile(
              w.idFile!, userId, 'worker_id_${_workers.indexOf(w)}');
        }
        workersData.add({
          'name': w.nameCtrl.text.trim(),
          'phone': w.phoneCtrl.text.trim(),
          'id_url': idUrl,
        });
      }

      await SupabaseService.client.from('vendor_applications').insert({
        'profile_id': userId,
        'business_type': 'informal',
        'status': 'pending',
        'store_name': _storeNameCtrl.text.trim(),
        'id_document_url': idUrl,
        'permit_url': permitUrl,
        'affidavit_url': affidavitUrl,
        'informal_proof_of_account_url': proofUrl,
        'contact_info': {
          'name': _nameCtrl.text.trim(),
          'surname': _surnameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        },
        'workers': workersData,
      });

      await auth.updateProfile({'username': _storeNameCtrl.text.trim()});

      setState(() {
        _saving = false;
        _step = 3;
      });
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to submit. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickFile(Function(PlatformFile) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      onPicked(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unregistered Vendor'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/vendor/setup'),
        ),
        bottom: _step < 3
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: AppColors.border,
                  color: AppColors.courierColor,
                ),
              )
            : null,
      ),
      body: _step == 3 ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InformalStepIndicator(current: _step),
            const SizedBox(height: 28),

            if (_step == 0) ..._buildStep0(),
            if (_step == 1) ..._buildStep1(),
            if (_step == 2) ..._buildStep2(),

            const SizedBox(height: 32),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      outline: true,
                      onTap: () => setState(() => _step--),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: _step == 2 ? 'Submit Application' : 'Continue',
                    loading: _saving,
                    icon: _step == 2
                        ? CupertinoIcons.checkmark_shield
                        : CupertinoIcons.arrow_right,
                    onTap: _step == 2 ? _submit : _nextStep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_idFile == null ||
          _permitFile == null ||
          _affidavitFile == null ||
          _proofOfAccountFile == null) {
        _showError('Please upload all four required documents.');
        return;
      }
      setState(() => _step = 2);
    }
  }

  List<Widget> _buildStep0() => [
        _SectionHeader(
            icon: CupertinoIcons.person_fill,
            title: 'Contact Information',
            color: AppColors.courierColor),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Store / Trading Name',
            prefixIcon: Icon(CupertinoIcons.house_fill,
                color: AppColors.textTertiary),
            hintText: 'e.g. Mama\'s Kitchen',
          ),
          validator: (v) =>
              v == null || v.trim().length < 2 ? 'Enter your store name' : null,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: TextFormField(
            controller: _surnameCtrl,
            decoration: const InputDecoration(labelText: 'Surname'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          )),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon:
                  Icon(CupertinoIcons.mail, color: AppColors.textTertiary)),
          validator: (v) =>
              v == null || !v.contains('@') ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon:
                  Icon(CupertinoIcons.phone, color: AppColors.textTertiary)),
          validator: (v) =>
              v == null || v.isEmpty ? 'Enter your phone number' : null,
        ),
      ];

  List<Widget> _buildStep1() => [
        _SectionHeader(
            icon: CupertinoIcons.doc_fill,
            title: 'Required Documents',
            color: AppColors.courierColor),
        const SizedBox(height: 4),
        const Text(
          'All four documents are required for approval.',
          style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _DocUploadTile(
          label: 'ID Document',
          hint: 'Owner\'s identity document',
          required: true,
          file: _idFile,
          onPick: () => _pickFile((f) => setState(() => _idFile = f)),
          onRemove: () => setState(() => _idFile = null),
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Trading / Vendor Permit',
          required: true,
          file: _permitFile,
          onPick: () => _pickFile((f) => setState(() => _permitFile = f)),
          onRemove: () => setState(() => _permitFile = null),
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Affidavit',
          hint: 'Sworn statement confirming business legitimacy',
          required: true,
          file: _affidavitFile,
          onPick: () => _pickFile((f) => setState(() => _affidavitFile = f)),
          onRemove: () => setState(() => _affidavitFile = null),
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Proof of Bank Account',
          hint: 'Must match owner\'s ID name',
          required: true,
          file: _proofOfAccountFile,
          onPick: () =>
              _pickFile((f) => setState(() => _proofOfAccountFile = f)),
          onRemove: () => setState(() => _proofOfAccountFile = null),
        ),
      ];

  List<Widget> _buildStep2() => [
        _SectionHeader(
            icon: CupertinoIcons.person_2_fill,
            title: 'Workers',
            color: AppColors.courierColor),
        const SizedBox(height: 4),
        const Text(
          'Add workers associated with your business. This is optional.',
          style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4),
        ),
        const SizedBox(height: 20),
        if (_workers.isEmpty)
          _InfoBox(text: 'No workers added. You can skip this step or add workers below.'),
        const SizedBox(height: 8),
        ..._workers.asMap().entries.map((entry) {
          final index = entry.key;
          final worker = entry.value;
          return _WorkerForm(
            index: index,
            worker: worker,
            onRemove: () => setState(() => _workers.removeAt(index)),
            onPickId: () =>
                _pickFile((f) => setState(() => worker.idFile = f)),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _workers.add(_WorkerEntry())),
          icon: const Icon(CupertinoIcons.add_circled, size: 18),
          label: const Text('Add a worker',
              style: TextStyle(fontFamily: 'Satoshi')),
        ),
      ];

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_shield_fill,
                color: AppColors.success, size: 52),
          ),
          const SizedBox(height: 24),
          Text('Application Submitted!',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Your documents are under review by our team.\nWe\'ll notify you within 24–48 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const Spacer(),
          AppButton(
            label: 'Go to Dashboard',
            icon: CupertinoIcons.chart_bar_fill,
            onTap: () => context.go('/vendor'),
          ),
          const SizedBox(height: 12),
          AppButton(
              label: 'Back to Home',
              outline: true,
              onTap: () => context.go('/')),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── WorkerEntry ───────────────────────────────────────────────────────────────
class _WorkerEntry {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  PlatformFile? idFile;
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _WorkerForm extends StatelessWidget {
  final int index;
  final _WorkerEntry worker;
  final VoidCallback onRemove;
  final VoidCallback onPickId;

  const _WorkerForm({
    required this.index,
    required this.worker,
    required this.onRemove,
    required this.onPickId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Worker ${index + 1}',
                  style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(CupertinoIcons.xmark_circle_fill,
                    color: AppColors.error, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: worker.nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(CupertinoIcons.person,
                    color: AppColors.textTertiary)),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: worker.phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(CupertinoIcons.phone,
                    color: AppColors.textTertiary)),
          ),
          const SizedBox(height: 10),
          _DocUploadTile(
            label: 'Passport / ID Document',
            required: false,
            file: worker.idFile,
            onPick: onPickId,
            onRemove: () {},
          ),
        ],
      ),
    );
  }
}

// ── Step indicator for informal ───────────────────────────────────────────────
class _InformalStepIndicator extends StatelessWidget {
  final int current;
  const _InformalStepIndicator({required this.current});

  static const _labels = ['Contact', 'Documents', 'Workers'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done || active
                      ? AppColors.courierColor
                      : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(CupertinoIcons.checkmark,
                          size: 12, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: active
                                  ? Colors.white
                                  : AppColors.textTertiary)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(_labels[i],
                      style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w900 : FontWeight.w500,
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textTertiary))),
              if (i < _labels.length - 1)
                Expanded(
                    child: Container(
                        height: 1,
                        color: i < current
                            ? AppColors.courierColor
                            : AppColors.border)),
            ],
          ),
        );
      }),
    );
  }
}
