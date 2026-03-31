import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/section_card.dart';

class VendorDetailScreen extends StatefulWidget {
  final int id;
  const VendorDetailScreen({super.key, required this.id});
  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  Map<String, dynamic>? _app;
  bool   _loading = true;
  bool   _acting  = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final a = await AdminApi.getVendorApplicationDetail(widget.id);
      setState(() => _app = a);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _acting = true);
    try {
      await AdminApi.approveVendor(widget.id);
      if (mounted) {
        _showSuccess('Store approved! Vendor has been notified.');
        context.go('/vendors');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() => _notesDialog(
    title: 'Reject Application',
    confirmLabel: 'Reject',
    confirmColor: AC.error,
    onConfirm: (notes) async {
      await AdminApi.rejectVendor(widget.id, notes: notes);
      if (mounted) {
        _showSuccess('Application rejected.');
        context.go('/vendors');
      }
    },
  );

  Future<void> _moreInfo() => _notesDialog(
    title: 'Request More Information',
    confirmLabel: 'Send Request',
    confirmColor: AC.info,
    onConfirm: (notes) async {
      await AdminApi.vendorMoreInfo(widget.id, notes: notes);
      if (mounted) {
        _showSuccess('More-info request sent to vendor.');
        await _load();
      }
    },
  );

  Future<void> _notesDialog({
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function(String) onConfirm,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter notes for the vendor…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _acting = true);
      try {
        await onConfirm(ctrl.text.trim());
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _acting = false);
      }
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AC.success,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AC.error,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AC.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/vendors'),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Store Approvals'),
                          ),
                          const Text(' / ', style: TextStyle(color: AC.textMuted)),
                          Text(_app?['store_name'] ?? '',
                              style: const TextStyle(color: AC.textSecond)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column — application info
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _ApplicationInfoCard(app: _app!),
                                const SizedBox(height: 16),
                                _DocumentsCard(app: _app!),
                                if (_app!['business_type'] == 'formal') ...[
                                  const SizedBox(height: 16),
                                  _PeopleCard(app: _app!),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  _WorkersCard(app: _app!),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right column — action panel
                          SizedBox(
                            width: 280,
                            child: _ActionPanel(
                              app: _app!,
                              acting: _acting,
                              onApprove: _approve,
                              onReject: _reject,
                              onMoreInfo: _moreInfo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Application info card ─────────────────────────────────────────────────────

class _ApplicationInfoCard extends StatelessWidget {
  final Map<String, dynamic> app;
  const _ApplicationInfoCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final owner  = app['profiles'] as Map?;
    final type   = app['business_type'] as String?;
    final contact = app['contact_info'] as Map? ?? {};

    return SectionCard(
      title: 'Application Details',
      child: Column(
        children: [
          _Row('Store Name',   app['store_name'] ?? '—'),
          _Row('Business Type', type == 'formal' ? 'Registered Business' : 'Informal Vendor'),
          _Row('Owner Name',   owner?['full_name'] ?? '—'),
          _Row('Owner Email',  owner?['email'] ?? '—'),
          _Row('Owner Phone',  owner?['phone'] ?? contact['phone'] ?? '—'),
          _Row('Submitted',    app['created_at'] != null
              ? DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(app['created_at']))
              : '—'),
          if (app['admin_notes'] != null)
            _Row('Admin Notes', app['admin_notes'], highlight: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Row(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 13,
                  color: highlight ? AC.warning : AC.textPrimary,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Documents card ────────────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  final Map<String, dynamic> app;
  const _DocumentsCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final isFormal = app['business_type'] == 'formal';
    final docs = isFormal
        ? [
            ('COR Certificate',         app['cor_url']),
            ('Proof of Bank Account',   app['proof_of_account_url']),
          ]
        : [
            ('ID Document',             app['id_document_url']),
            ('Trading Permit',          app['permit_url']),
            ('Affidavit',               app['affidavit_url']),
            ('Proof of Bank Account',   app['informal_proof_of_account_url']),
          ];

    return SectionCard(
      title: 'Submitted Documents',
      child: Column(
        children: docs.map((d) => _DocRow(label: d.$1, url: d.$2)).toList(),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;
  final dynamic url;
  const _DocRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final hasDoc = url != null && url.toString().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(hasDoc ? Icons.description_rounded : Icons.close_rounded,
              size: 16,
              color: hasDoc ? AC.success : AC.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AC.textPrimary)),
          ),
          if (hasDoc)
            TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              onPressed: () => launchUrl(Uri.parse(url.toString())),
              style: TextButton.styleFrom(foregroundColor: AC.primary),
            )
          else
            const Text('Not submitted',
                style: TextStyle(color: AC.error, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── People card (formal) ──────────────────────────────────────────────────────

class _PeopleCard extends StatelessWidget {
  final Map<String, dynamic> app;
  const _PeopleCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final people = (app['people'] as List?)?.cast<Map>() ?? [];
    if (people.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Authorised Representatives',
      child: Column(
        children: people.asMap().entries.map((e) {
          final p   = e.value;
          final idx = e.key;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AC.primary.withOpacity(0.1),
              child: Text('${idx + 1}',
                  style: const TextStyle(color: AC.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text('${p['name']} ${p['surname']}'),
            subtitle: Text(p['email'] ?? ''),
            trailing: p['id_url'] != null
                ? TextButton(
                    onPressed: () => launchUrl(Uri.parse(p['id_url'])),
                    child: const Text('View ID'),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

// ── Workers card (informal) ───────────────────────────────────────────────────

class _WorkersCard extends StatelessWidget {
  final Map<String, dynamic> app;
  const _WorkersCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final workers = (app['workers'] as List?)?.cast<Map>() ?? [];
    if (workers.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Workers',
      child: Column(
        children: workers.asMap().entries.map((e) {
          final w = e.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(w['name'] ?? ''),
            subtitle: Text(w['phone'] ?? ''),
            trailing: w['id_url'] != null
                ? TextButton(
                    onPressed: () => launchUrl(Uri.parse(w['id_url'])),
                    child: const Text('View ID'),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

// ── Action panel ──────────────────────────────────────────────────────────────

class _ActionPanel extends StatelessWidget {
  final Map<String, dynamic> app;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onMoreInfo;
  const _ActionPanel({
    required this.app,
    required this.acting,
    required this.onApprove,
    required this.onReject,
    required this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    final status = app['status'] as String?;
    final isPending = status == 'pending' || status == 'more_info_required';

    return SectionCard(
      title: 'Decision',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBadge(status),
          const SizedBox(height: 16),

          if (isPending) ...[
            const Text(
              'Review the documents carefully before approving. '
              'Approving will create the vendor\'s store and allow them to list products.',
              style: TextStyle(fontSize: 12, color: AC.textSecond, height: 1.6),
            ),
            const SizedBox(height: 20),

            if (acting) ...[
              const Center(child: CircularProgressIndicator(color: AC.primary)),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve Store'),
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(backgroundColor: AC.success),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Request More Info'),
                onPressed: onMoreInfo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AC.info,
                  side: const BorderSide(color: AC.info),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject Application'),
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AC.error,
                  side: const BorderSide(color: AC.error),
                ),
              ),
            ],
          ] else ...[
            Text(
              status == 'approved'
                  ? 'This application has been approved. The store is live.'
                  : 'This application has been finalised.',
              style: const TextStyle(fontSize: 12, color: AC.textSecond),
            ),
          ],
        ],
      ),
    );
  }
}
