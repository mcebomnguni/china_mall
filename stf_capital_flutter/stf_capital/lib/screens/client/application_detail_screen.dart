// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/application_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_models.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final svc  = context.watch<ApplicationService>();
    final auth = context.watch<AuthService>();

    return StfScaffold(
      title: 'Application Details',
      body: FutureBuilder<ServiceApplication?>(
        future: svc.getApplication(applicationId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.goldLight),
            );
          }
          if (!snap.hasData || snap.data == null) {
            return Center(
              child: Text('Application not found.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            );
          }
          final app = snap.data!;
          return _ApplicationDetail(
            app:     app,
            isAdmin: auth.isAdmin,
          );
        },
      ),
    );
  }
}

class _ApplicationDetail extends StatefulWidget {
  final ServiceApplication app;
  final bool               isAdmin;
  const _ApplicationDetail({required this.app, required this.isAdmin});

  @override
  State<_ApplicationDetail> createState() => _ApplicationDetailState();
}

class _ApplicationDetailState extends State<_ApplicationDetail> {
  ApplicationStatus? _newStatus;
  final _noteCtrl   = TextEditingController();
  final _returnCtrl = TextEditingController();
  bool  _updating   = false;

  @override
  void initState() {
    super.initState();
    _newStatus = widget.app.status;
    _noteCtrl.text   = widget.app.adminNote   ?? '';
    _returnCtrl.text = widget.app.returnReason ?? '';
  }

  @override
  void dispose() { _noteCtrl.dispose(); _returnCtrl.dispose(); super.dispose(); }

  Future<void> _update() async {
    if (_newStatus == null) return;
    setState(() => _updating = true);
    final svc = context.read<ApplicationService>();
    await svc.updateApplicationStatus(
      applicationId: widget.app.id,
      status:        _newStatus!,
      adminNote:     _noteCtrl.text.isNotEmpty     ? _noteCtrl.text     : null,
      returnReason:  _returnCtrl.text.isNotEmpty   ? _returnCtrl.text   : null,
    );
    if (!mounted) return;
    setState(() => _updating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application updated successfully.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.selectedProductName,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(app.productCategoryName,
                          style: GoogleFonts.montserrat(
                            fontSize: 12, color: AppTheme.textGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: app.status),
                ],
              ),
              const SizedBox(height: 8),
              const GoldDivider(),
              const SizedBox(height: 24),

              // ── Status explanation for client
              if (!widget.isAdmin) _ClientStatusInfo(status: app.status),
              if (!widget.isAdmin && app.returnReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:  AppTheme.statusReturned.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.statusReturned.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACTION REQUIRED',
                        style: GoogleFonts.montserrat(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.statusReturned, letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(app.returnReason!,
                        style: GoogleFonts.montserrat(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GoldButton(
                        label:    'Resubmit Application',
                        onPressed: () => context.push('/resubmit/${app.id}'),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Application info
              const SizedBox(height: 20),
              _DetailSection(title: 'Application Details', rows: [
                _DetailRow('Application ID', app.id.substring(0, 8).toUpperCase()),
                _DetailRow('Submitted',       _formatDate(app.createdAt)),
                _DetailRow('Last Updated',    _formatDate(app.updatedAt)),
              ]),
              const SizedBox(height: 14),

              if (widget.isAdmin) ...[
                _DetailSection(title: 'Client Information', rows: [
                  _DetailRow('Name',    app.clientName),
                  _DetailRow('Company', app.companyName),
                  _DetailRow('Email',   app.clientEmail),
                ]),
                const SizedBox(height: 14),
              ],

              _DetailSection(title: 'Product', rows: [
                _DetailRow('Category', app.productCategoryName),
                _DetailRow('Product',  app.selectedProductName),
              ]),
              const SizedBox(height: 14),

              // ── Documents
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUBMITTED DOCUMENTS',
                      style: GoogleFonts.montserrat(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppTheme.goldLight, letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (app.documents.isEmpty)
                      Text('No documents submitted.',
                        style: GoogleFonts.montserrat(
                          fontSize: 13, color: AppTheme.textSecondary,
                        ),
                      )
                    else
                      ...app.documents.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              doc.type == 'image'
                                  ? Icons.image_outlined
                                  : Icons.picture_as_pdf_outlined,
                              size: 16, color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(doc.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (doc.url.isNotEmpty)
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse(doc.url)),
                                child: Text('View',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11, color: AppTheme.goldLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),

              // ── Admin actions
              if (widget.isAdmin) ...[
                const SizedBox(height: 24),
                Text('ADMIN ACTIONS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.goldLight, letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Status selector
                DropdownButtonFormField<ApplicationStatus>(
                  value:       _newStatus,
                  dropdownColor: AppTheme.darkSurface2,
                  decoration: const InputDecoration(labelText: 'Update Status'),
                  items: ApplicationStatus.values.map((s) =>
                    DropdownMenuItem(
                      value: s,
                      child: Text(s.label,
                        style: GoogleFonts.montserrat(
                          fontSize: 13, color: AppTheme.statusColor(s.label),
                        ),
                      ),
                    ),
                  ).toList(),
                  onChanged: (v) => setState(() => _newStatus = v),
                ),
                const SizedBox(height: 14),

                if (_newStatus == ApplicationStatus.returned) ...[
                  GoldTextField(
                    controller: _returnCtrl,
                    label:      'Reason for Return (shown to client)',
                    maxLines:   3,
                    prefixIcon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                ],

                GoldTextField(
                  controller: _noteCtrl,
                  label:      'Admin Note (internal)',
                  maxLines:   3,
                  prefixIcon: Icons.sticky_note_2_outlined,
                ),
                const SizedBox(height: 20),

                GoldButton(
                  label:     'Save Changes',
                  onPressed: _update,
                  isLoading: _updating,
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month-1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

// ─── Client status explanation ────────────────────────────────────────────────
class _ClientStatusInfo extends StatelessWidget {
  final ApplicationStatus status;
  const _ClientStatusInfo({required this.status});

  @override
  Widget build(BuildContext context) {
    String message;
    Color  color;
    IconData icon;

    switch (status) {
      case ApplicationStatus.pendingReview:
        message = 'Your application has been submitted and is awaiting review by our team.';
        color = AppTheme.statusPending;
        icon  = Icons.hourglass_empty_rounded;
        break;
      case ApplicationStatus.opened:
        message = 'Your application has been opened by our team and is being reviewed.';
        color = AppTheme.statusOpened;
        icon  = Icons.folder_open_rounded;
        break;
      case ApplicationStatus.pendingOutcome:
        message = 'Your application has been reviewed and an outcome is being determined.';
        color = AppTheme.statusOpened;
        icon  = Icons.pending_actions_rounded;
        break;
      case ApplicationStatus.returned:
        message = 'Your application has been returned. Please review the notes below and resubmit with the correct information.';
        color = AppTheme.statusReturned;
        icon  = Icons.reply_rounded;
        break;
      case ApplicationStatus.approved:
        message = 'Congratulations. Your application has been approved. Our team will be in contact.';
        color = AppTheme.statusApproved;
        icon  = Icons.check_circle_rounded;
        break;
      case ApplicationStatus.declined:
        message = 'We regret to inform you that your application has been declined. Please contact us for further information.';
        color = AppTheme.statusDeclined;
        icon  = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
              style: GoogleFonts.montserrat(
                fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String           title;
  final List<_DetailRow> rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.cardDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.goldLight, letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        ...rows.asMap().entries.map((e) => Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(e.value.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.value.value,
                    style: GoogleFonts.montserrat(
                      fontSize: 12, color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (e.key < rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        )),
      ],
    ),
  );
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
