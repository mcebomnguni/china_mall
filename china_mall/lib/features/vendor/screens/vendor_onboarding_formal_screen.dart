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

class VendorOnboardingFormalScreen extends StatefulWidget {
  const VendorOnboardingFormalScreen({super.key});

  @override
  State<VendorOnboardingFormalScreen> createState() => _VendorOnboardingFormalScreenState();
}

class _VendorOnboardingFormalScreenState extends State<VendorOnboardingFormalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  int _step = 0; // 0 = business info, 1 = documents, 2 = people, 3 = success
  bool _saving = false;

  // Documents
  PlatformFile? _corFile;
  PlatformFile? _proofOfAccountFile;

  // People (up to 3, first is required)
  final List<_PersonEntry> _people = [_PersonEntry()];

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    for (final p in _people) p.dispose();
    super.dispose();
  }

  Future<String?> _uploadFile(PlatformFile file, String userId, String docType) async {
    try {
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return null;
      final path = '$userId/$docType/${file.name}';
      await SupabaseService.client.storage.from('vendor-docs').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return SupabaseService.client.storage.from('vendor-docs').getPublicUrl(path);
    } catch (_) {
      return 'pending:${file.name}'; // fallback — store name only
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_corFile == null || _proofOfAccountFile == null) {
      _showError('Please upload both the COR certificate and proof of bank account.');
      return;
    }

    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Upload documents
      final corUrl = await _uploadFile(_corFile!, userId, 'cor');
      final proofUrl = await _uploadFile(_proofOfAccountFile!, userId, 'proof_of_account');

      // Build people array
      final peopleData = <Map<String, dynamic>>[];
      for (final person in _people) {
        if (person.nameCtrl.text.trim().isEmpty) continue;
        String? idUrl;
        if (person.idFile != null) {
          idUrl = await _uploadFile(person.idFile!, userId, 'person_id_${_people.indexOf(person)}');
        }
        peopleData.add({
          'name': person.nameCtrl.text.trim(),
          'surname': person.surnameCtrl.text.trim(),
          'email': person.emailCtrl.text.trim(),
          'id_url': idUrl,
        });
      }

      await SupabaseService.client.from('vendor_applications').insert({
        'profile_id': userId,
        'business_type': 'formal',
        'status': 'pending',
        'store_name': _storeNameCtrl.text.trim(),
        'cor_url': corUrl,
        'proof_of_account_url': proofUrl,
        'people': peopleData,
      });

      // Update profile with store name
      await auth.updateProfile({'username': _storeNameCtrl.text.trim()});

      setState(() { _saving = false; _step = 3; });
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to submit application. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
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
        title: const Text('Registered Business'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/vendor/setup'),
        ),
        bottom: _step < 3
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: AppColors.border,
                  color: AppColors.storeColor,
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
            _StepIndicator(current: _step, labels: const ['Business', 'Documents', 'People']),
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
                    icon: _step == 2 ? CupertinoIcons.checkmark_shield : CupertinoIcons.arrow_right,
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
      if (_corFile == null || _proofOfAccountFile == null) {
        _showError('Please upload both required documents.');
        return;
      }
      setState(() => _step = 2);
    }
  }

  List<Widget> _buildStep0() => [
    VendorSectionHeader(icon: CupertinoIcons.building_2_fill, title: 'Business Information', color: AppColors.storeColor),
    const SizedBox(height: 16),
    TextFormField(
      controller: _storeNameCtrl,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Store / Business Name',
        prefixIcon: Icon(CupertinoIcons.house_fill, color: AppColors.textTertiary),
        hintText: 'e.g. Mkhwanazi Trading (Pty) Ltd',
      ),
      validator: (v) => v == null || v.trim().length < 3 ? 'Enter your business name' : null,
    ),
    const SizedBox(height: 20),
    VendorInfoBox(text: 'Enter the business name exactly as it appears on your Company Registration Certificate (COR).'),
  ];

  List<Widget> _buildStep1() => [
    VendorSectionHeader(icon: CupertinoIcons.doc_fill, title: 'Required Documents', color: AppColors.storeColor),
    const SizedBox(height: 4),
    const Text(
      'Upload clear, legible copies of each document.',
      style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.textSecondary),
    ),
    const SizedBox(height: 20),

    VendorDocUploadTile(
      label: 'COR — Company Registration Certificate',
      required: true,
      file: _corFile,
      onPick: () => _pickFile((f) => setState(() => _corFile = f)),
      onRemove: () => setState(() => _corFile = null),
    ),
    const SizedBox(height: 12),
    VendorDocUploadTile(
      label: 'Proof of Bank Account',
      hint: 'Must match the business name',
      required: true,
      file: _proofOfAccountFile,
      onPick: () => _pickFile((f) => setState(() => _proofOfAccountFile = f)),
      onRemove: () => setState(() => _proofOfAccountFile = null),
    ),
  ];

  List<Widget> _buildStep2() => [
    VendorSectionHeader(icon: CupertinoIcons.person_2_fill, title: 'People Information', color: AppColors.storeColor),
    const SizedBox(height: 4),
    const Text(
      'Add up to 3 people associated with this business. At least one is required.',
      style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.textSecondary, height: 1.4),
    ),
    const SizedBox(height: 20),

    ..._people.asMap().entries.map((entry) {
      final index = entry.key;
      final person = entry.value;
      return _PersonForm(
        index: index,
        person: person,
        canRemove: _people.length > 1,
        onRemove: () => setState(() => _people.removeAt(index)),
        onPickId: () => _pickFile((f) => setState(() => person.idFile = f)),
      );
    }),

    if (_people.length < 3)
      TextButton.icon(
        onPressed: () => setState(() => _people.add(_PersonEntry())),
        icon: const Icon(CupertinoIcons.add_circled, size: 18),
        label: const Text('Add another person', style: TextStyle(fontFamily: 'Satoshi')),
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
            child: const Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.success, size: 52),
          ),
          const SizedBox(height: 24),
          Text('Application Submitted!', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Your business documents are under review.\nOur team will get back to you within 24–48 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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
            onTap: () => context.go('/'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── PersonEntry ───────────────────────────────────────────────────────────────
class _PersonEntry {
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  PlatformFile? idFile;

  void dispose() {
    nameCtrl.dispose();
    surnameCtrl.dispose();
    emailCtrl.dispose();
  }
}

// ── PersonForm widget ─────────────────────────────────────────────────────────
class _PersonForm extends StatelessWidget {
  final int index;
  final _PersonEntry person;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onPickId;

  const _PersonForm({
    required this.index,
    required this.person,
    required this.canRemove,
    required this.onRemove,
    required this.onPickId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Text('Person ${index + 1}${index == 0 ? ' (Required)' : ' (Optional)'}',
                  style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.error, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: person.nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: index == 0 ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
            )),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(
              controller: person.surnameCtrl,
              decoration: const InputDecoration(labelText: 'Surname'),
              validator: index == 0 ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
            )),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: person.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(CupertinoIcons.mail, color: AppColors.textTertiary)),
            validator: index == 0 ? (v) => v == null || !v.contains('@') ? 'Enter valid email' : null : null,
          ),
          const SizedBox(height: 10),
          VendorDocUploadTile(
            label: 'ID Document',
            required: index == 0,
            file: person.idFile,
            onPick: onPickId,
            onRemove: () {},
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final List<String> labels;
  const _StepIndicator({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done || active ? AppColors.storeColor : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(CupertinoIcons.checkmark, size: 12, color: Colors.white)
                      : Text('${i + 1}', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.textTertiary)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(labels[i], style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: active ? FontWeight.w900 : FontWeight.w500, color: active ? AppColors.textPrimary : AppColors.textTertiary))),
              if (i < labels.length - 1)
                Expanded(child: Container(height: 1, color: i < current ? AppColors.storeColor : AppColors.border)),
            ],
          ),
        );
      }),
    );
  }
}

class VendorSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const VendorSectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      ],
    );
  }
}

class VendorDocUploadTile extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final PlatformFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const VendorDocUploadTile({
    required this.label,
    this.hint,
    required this.required,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = file != null;
    return GestureDetector(
      onTap: uploaded ? null : onPick,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded ? AppColors.green050 : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: uploaded ? AppColors.success : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              uploaded ? CupertinoIcons.doc_checkmark_fill : CupertinoIcons.doc_fill,
              color: uploaded ? AppColors.success : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                    if (required) const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)),
                  ]),
                  if (hint != null) Text(hint!, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.textTertiary)),
                  if (uploaded) Text(file!.name, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.success), overflow: TextOverflow.ellipsis),
                  if (!uploaded) const Text('PDF, JPG or PNG — tap to upload', style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            if (uploaded)
              GestureDetector(
                onTap: onRemove,
                child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.error, size: 20),
              )
            else
              const Icon(CupertinoIcons.arrow_up_circle, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class VendorInfoBox extends StatelessWidget {
  final String text;
  const VendorInfoBox({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.info_circle, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
      ],
    ),
  );
}
