// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/resubmit_screen.dart
//  Shown when a client clicks "Resubmit" on a returned application.
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

class ResubmitScreen extends StatefulWidget {
  final String applicationId;
  const ResubmitScreen({super.key, required this.applicationId});

  @override
  State<ResubmitScreen> createState() => _ResubmitScreenState();
}

class _ResubmitScreenState extends State<ResubmitScreen> {
  ServiceApplication? _app;
  bool _loading   = true;
  bool _uploading = false;
  String? _error;
  double _progress = 0;

  final Map<String, _PickedFile?> _files = {
    for (final d in RequiredDocuments.registration) d: null,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<ApplicationService>();
    final app = await svc.getApplication(widget.applicationId);
    setState(() { _app = app; _loading = false; });
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

  Future<void> _submit() async {
    final requiredUploaded = RequiredDocuments.registration.take(7)
        .every((k) => _files[k] != null);
    if (!requiredUploaded) {
      setState(() => _error = 'Please upload all required documents.');
      return;
    }

    setState(() { _uploading = true; _error = null; });

    final auth    = context.read<AuthService>();
    final svc     = context.read<ApplicationService>();
    final uid     = auth.currentUser!.uid;
    final docs    = <UploadedDocument>[];
    final total   = _files.values.where((f) => f != null).length;
    int done      = 0;

    for (final entry in _files.entries) {
      if (entry.value == null) continue;
      final doc = await svc.uploadDocument(
        uid:           uid,
        applicationId: widget.applicationId,
        filePath:      entry.value!.path,
        fileName:      entry.value!.name,
      );
      if (doc != null) docs.add(doc);
      done++;
      setState(() => _progress = done / total);
    }

    // Update the application status back to pending_review with new docs
    await svc.updateApplicationStatus(
      applicationId: widget.applicationId,
      status:        ApplicationStatus.pendingReview,
    );

    setState(() => _uploading = false);
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    return StfScaffold(
      title: 'Resubmit Application',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Return reason
                if (_app?.returnReason != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin:  const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color:  AppTheme.statusReturned.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.statusReturned.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REASON FOR RETURN',
                          style: GoogleFonts.montserrat(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppTheme.statusReturned, letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_app!.returnReason!,
                          style: GoogleFonts.montserrat(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                SectionHeader(
                  title:    'Upload Corrected Documents',
                  subtitle: 'Please upload all required documents. Only PDF, JPG and PNG files are accepted (max 10 MB each).',
                ),
                const SizedBox(height: 24),

                if (_error != null)
                  ErrorBanner(
                    message:   _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),

                ...RequiredDocuments.registration.asMap().entries.map((entry) {
                  final i       = entry.key;
                  final docName = entry.value;
                  final isOpt   = i >= 7;
                  final file    = _files[docName];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: file != null
                          ? AppTheme.statusApproved.withOpacity(0.05)
                          : AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: file != null
                            ? AppTheme.statusApproved.withOpacity(0.4)
                            : AppTheme.darkBorder,
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
                                        fontSize: 13, fontWeight: FontWeight.w500,
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
                                          fontSize: 9,
                                          color: AppTheme.textSecondary,
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
                                    fontSize: 11, color: AppTheme.statusApproved,
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
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: file != null
                                    ? AppTheme.textSecondary
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

                if (_uploading) ...[
                  Text('Uploading documents...',
                    style: GoogleFonts.montserrat(
                      fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value:           _progress,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      color:           AppTheme.goldLight,
                      minHeight:       4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GoldButton(
                  label:     'Resubmit Application',
                  onPressed: _uploading ? null : _submit,
                  isLoading: _uploading,
                ),
                const SizedBox(height: 40),
              ],
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
