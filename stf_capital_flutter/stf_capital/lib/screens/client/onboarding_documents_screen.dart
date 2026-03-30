// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/onboarding_documents_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class OnboardingDocumentsScreen extends StatefulWidget {
  final ProductCategory? preselectedCategory;
  final ProductItem? preselectedItem;
  
  const OnboardingDocumentsScreen({
    super.key,
    this.preselectedCategory,
    this.preselectedItem,
  });
  @override
  State<OnboardingDocumentsScreen> createState() =>
      _OnboardingDocumentsScreenState();
}

class _OnboardingDocumentsScreenState extends State<OnboardingDocumentsScreen> {
  // Map from required doc name to picked file info
  final Map<String, _PickedFile?> _files = {
    for (final doc in RequiredDocuments.registration) doc: null,
  };

  bool _uploading = false;
  String? _error;
  double _progress = 0;

  bool get _allRequiredUploaded {
    // The last 2 are conditional; first 7 are required
    final required = RequiredDocuments.registration.take(7);
    return required.every((k) => _files[k] != null);
  }

  Future<void> _pickFile(String docName) async {
    final result = await FilePicker.platform.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _files[docName] = _PickedFile(
          name: result.files.first.name,
          path: result.files.first.path ?? '',
        );
      });
    }
  }

  Future<void> _proceed() async {
    if (!_allRequiredUploaded) {
      setState(() => _error = 'Please upload all required documents before proceeding.');
      return;
    }

    setState(() { _uploading = true; _error = null; });

    final auth    = context.read<AuthService>();
    final svc     = context.read<ApplicationService>();
    final uid     = auth.currentUser!.uid;
    final tempId  = 'onboarding_${uid}';
    final docs    = <UploadedDocument>[];
    int total     = _files.values.where((f) => f != null).length;
    int done      = 0;

    for (final entry in _files.entries) {
      if (entry.value == null) continue;
      final doc = await svc.uploadDocument(
        uid:           uid,
        applicationId: tempId,
        filePath:      entry.value!.path,
        fileName:      entry.value!.name,
      );
      if (doc != null) docs.add(doc);
      done++;
      setState(() => _progress = done / total);
    }

    // Submit application directly if we have preselected category and item
    if (widget.preselectedCategory != null && widget.preselectedItem != null) {
      final error = await svc.submitApplication(
        client: auth.currentUser!,
        productCategoryId: widget.preselectedCategory!.name,
        productCategoryName: widget.preselectedCategory!.displayName,
        selectedProductId: widget.preselectedItem!.id,
        selectedProductName: widget.preselectedItem!.name,
        documents: docs,
      );
      
      setState(() => _uploading = false);
      if (!mounted) return;
      
      if (error != null) {
        setState(() => _error = error);
      } else {
        // Show success and navigate to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppTheme.goldLight,
          ),
        );
        context.go('/dashboard');
      }
    } else {
      // Fallback to old flow for resubmissions
      setState(() => _uploading = false);
      if (!mounted) return;
      context.go('/onboarding/products', extra: docs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text('Upload Documents',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: Text('Skip for now',
              style: GoogleFonts.montserrat(
                fontSize: 12, color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Step indicator
                  _StepIndicator(current: 1, total: 2),
                  const SizedBox(height: 28),

                  SectionHeader(
                    title:    'Required Documents',
                    subtitle: 'To access our full range of services, please upload the following documents. All files must be in PDF, JPG, or PNG format.',
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    ErrorBanner(
                      message:   _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),

                  // ── Document list
                  ...RequiredDocuments.registration.asMap().entries.map((entry) {
                    final i       = entry.key;
                    final docName = entry.value;
                    final isOpt   = i >= 7; // last 2 conditional
                    final file    = _files[docName];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: file != null
                            ? AppTheme.statusApproved.withOpacity(0.05)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: file != null
                              ? AppTheme.statusApproved.withOpacity(0.4)
                              : Theme.of(context).colorScheme.outline,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            file != null
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: file != null
                                ? AppTheme.statusApproved
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(docName,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isOpt)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text('OPTIONAL',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 9, color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (file != null) ...[
                                  const SizedBox(height: 4),
                                  Text(file.name,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: AppTheme.statusApproved,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _uploading ? null : () => _pickFile(docName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color:        AppTheme.darkSurface2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Text(
                                file != null ? 'Replace' : 'Upload',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: file != null
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                                      : AppTheme.goldLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  if (_uploading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Uploading documents...',
                          style: GoogleFonts.montserrat(
                            fontSize: 12, color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value:           _progress,
                            backgroundColor: AppTheme.darkSurface2,
                            color:           AppTheme.goldLight,
                            minHeight:       4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: widget.preselectedItem != null 
                          ? 'Submit Application' 
                          : 'Continue',
                      onPressed: _uploading ? null : _proceed,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedFile {
  final String name;
  final String path;
  const _PickedFile({required this.name, required this.path});
}

// ── Step Indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) {
      final active = i + 1 == current;
      final done   = i + 1 < current;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: active || done
                          ? AppTheme.goldGradientSimple
                          : null,
                      color: active || done ? null : AppTheme.darkSurface2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i == 0 ? 'Upload Documents' : 'Select Product',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: active ? AppTheme.goldLight : AppTheme.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (i < total - 1) const SizedBox(width: 12),
          ],
        ),
      );
    }),
  );
}
