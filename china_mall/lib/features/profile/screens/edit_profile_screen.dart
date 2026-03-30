import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
 
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
 
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
 
  File? _pickedImage;
  bool _saving = false;
 
  final _picker = ImagePicker();
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
 
    _firstNameCtrl = TextEditingController(text: user['first_name'] ?? '');
    _lastNameCtrl  = TextEditingController(text: user['last_name'] ?? '');
    _emailCtrl     = TextEditingController(text: user['email'] ?? '');
 
    // Strip leading country code so we don't double-prefix on save.
    String rawPhone = user['phone']?.toString() ?? '';
    if (rawPhone.startsWith('+27')) { rawPhone = rawPhone.substring(3); }
    else if (rawPhone.startsWith('27')) { rawPhone = rawPhone.substring(2); }
    if (rawPhone.startsWith('0')) { rawPhone = rawPhone.substring(1); }
 
    _phoneCtrl = TextEditingController(text: rawPhone);
 
    // Rebuild avatar initial whenever first name changes.
    _firstNameCtrl.addListener(() => setState(() {}));
  }
 
  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
 
  // ── Avatar picker ──────────────────────────────────────────────────────────
 
  Future<void> _pickImage() async {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Change Profile Photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickFrom(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickFrom(ImageSource.gallery);
            },
            child: const Text('Choose from Library'),
          ),
          if (_pickedImage != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _pickedImage = null);
              },
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
 
  Future<void> _pickFrom(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (file != null && mounted) {
        setState(() => _pickedImage = File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
 
  // ── Save ───────────────────────────────────────────────────────────────────
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
 
    final Map<String, dynamic> updateData = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name' : _lastNameCtrl.text.trim(),
      'email'     : _emailCtrl.text.trim(),
      'phone'     : '+27${_phoneCtrl.text.trim().replaceAll(' ', '')}',
    };
 
    // If a new image was picked, attach it for the provider to upload.
    if (_pickedImage != null) {
      updateData['avatar_path'] = _pickedImage!.path;
    }
 
    final success =
        await context.read<AuthProvider>().updateProfile(updateData);
 
    if (!mounted) return;
    setState(() => _saving = false);
 
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safePop();
    } else {
      final errorMsg = context.read<AuthProvider>().error ??
          'Failed to update profile. Check your details.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    // Avatar initial — reflects live typing
    final initial = _firstNameCtrl.text.trim().isNotEmpty
        ? _firstNameCtrl.text.trim()[0].toUpperCase()
        : 'U';
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Edit Profile',
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
 
              // ── Avatar ────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      // Avatar circle
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _pickedImage == null
                              ? AppColors.gradientRed
                              : null,
                          color: _pickedImage != null
                              ? AppColors.surface
                              : null,
                          border: Border.all(
                              color: AppColors.border, width: 2),
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              ? Image.file(
                                  _pickedImage!,
                                  fit: BoxFit.cover,
                                  width: 88,
                                  height: 88,
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                        ),
                      ),
 
                      // Camera badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.border, width: 2),
                          ),
                          child: const Icon(CupertinoIcons.camera_fill,
                              size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              // Tap hint
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
 
              const SizedBox(height: 32),
 
              // ── Account Details ───────────────────────────────────────
              const Text(
                'Account Details',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
 
              // First name + Last name
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Last Name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
 
              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(CupertinoIcons.mail, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final emailRx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRx.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
 
              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+27 ',
                  prefixIcon: Icon(CupertinoIcons.phone, size: 20),
                  hintText: '81 234 5678',
                ),
                maxLength: 11, // 9 digits + 2 spaces for readability
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final digits = v.replaceAll(' ', '');
                  if (digits.length != 9) {
                    return 'Enter 9 digits after +27 (e.g. 811234567)';
                  }
                  return null;
                },
              ),
 
              const SizedBox(height: 40),
 
              // ── Save button ───────────────────────────────────────────
              AppButton(
                label: 'SAVE CHANGES',
                loading: _saving,
                onTap: _save,
                icon: CupertinoIcons.check_mark_circled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}