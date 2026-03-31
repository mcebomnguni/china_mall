import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/page_header.dart';
import '../_widgets/section_card.dart';

class AdminMgmtScreen extends StatefulWidget {
  const AdminMgmtScreen({super.key});
  @override
  State<AdminMgmtScreen> createState() => _AdminMgmtScreenState();
}

class _AdminMgmtScreenState extends State<AdminMgmtScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  String? _error;
  bool _isSuperAdmin = false;
  bool _accessChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _isSuperAdmin = await AdminApi.isSuperAdmin();
      _accessChecked = true;
      if (_isSuperAdmin) {
        await _loadAdmins();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admins = await AdminApi.listAdmins();
      setState(() => _admins = admins);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddAdminDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'admin';
    String level = 'admin';
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AC.primary, size: 22),
                  SizedBox(width: 10),
                  Text('Add Admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AC.textPrimary,
                      )),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'The person must already have a registered account.',
                        style: TextStyle(fontSize: 12, color: AC.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'user@example.com',
                        prefixIcon:
                            Icon(Icons.email_rounded, size: 18, color: AC.textMuted),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Tumisang Msiza',
                        prefixIcon:
                            Icon(Icons.person_rounded, size: 18, color: AC.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_rounded,
                            size: 18, color: AC.textMuted),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => role = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: level,
                      decoration: const InputDecoration(
                        labelText: 'Admin Level',
                        prefixIcon: Icon(Icons.security_rounded,
                            size: 18, color: AC.textMuted),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'super_admin', child: Text('Super Admin')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => level = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AC.textSecond)),
                ),
                ElevatedButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(submitting ? 'Adding...' : 'Add Admin'),
                  onPressed: submitting
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          if (email.isEmpty || name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Email and Full Name are required'),
                                backgroundColor: AC.warning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            await AdminApi.createAdmin(
                              email,
                              name,
                              role: role,
                              level: level,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Admin "$name" added successfully'),
                                backgroundColor: AC.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _loadAdmins();
                          } catch (e) {
                            setDialogState(() => submitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add admin: $e'),
                                backgroundColor: AC.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Access denied state
    if (_accessChecked && !_isSuperAdmin) {
      return Scaffold(
        backgroundColor: AC.bg,
        body: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AC.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AC.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AC.error, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AC.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Super Admin only',
                  style: TextStyle(
                    fontSize: 14,
                    color: AC.textSecond,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // Top bar
          Container(
            color: AC.surface,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
            child: PageHeader(
              title: 'Admin Team',
              subtitle: 'Manage administrator accounts',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AC.textSecond),
                    onPressed: _loadAdmins,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Admin'),
                    onPressed: _showAddAdminDialog,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AC.border),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AC.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: AC.error)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              onPressed: _loadAdmins,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: SectionCard(
                          title: 'All Administrators',
                          action: Text(
                            '${_admins.length} total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AC.textMuted,
                            ),
                          ),
                          child: _admins.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'No admin accounts found',
                                      style:
                                          TextStyle(color: AC.textMuted),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Table header
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: _Hdr('NAME')),
                                          Expanded(
                                              flex: 3,
                                              child: _Hdr('EMAIL')),
                                          Expanded(
                                              flex: 2,
                                              child: _Hdr('ROLE')),
                                          Expanded(
                                              flex: 2,
                                              child: _Hdr('ADMIN LEVEL')),
                                          Expanded(
                                              flex: 2,
                                              child: _Hdr('JOINED')),
                                        ],
                                      ),
                                    ),
                                    const Divider(color: AC.border),
                                    // Rows
                                    ..._admins.map(_buildRow),
                                  ],
                                ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> a) {
    final role = (a['role'] as String?) ?? 'admin';
    final level = (a['admin_level'] as String?) ?? 'admin';
    final createdAt = a['created_at'] as String?;
    String joinedStr = '-';
    if (createdAt != null) {
      try {
        joinedStr = DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt));
      } catch (_) {
        joinedStr = createdAt;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Text(
              a['full_name'] ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Email
          Expanded(
            flex: 3,
            child: Text(
              a['email'] ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: AC.textSecond,
              ),
            ),
          ),
          // Role badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(
                label: role == 'staff' ? 'Staff' : 'Admin',
                color: role == 'staff' ? AC.info : AC.primary,
              ),
            ),
          ),
          // Admin Level badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(
                label: level == 'super_admin' ? 'Super Admin' : 'Admin',
                color: level == 'super_admin' ? AC.warning : AC.primary,
              ),
            ),
          ),
          // Joined
          Expanded(
            flex: 2,
            child: Text(
              joinedStr,
              style: const TextStyle(
                fontSize: 12,
                color: AC.textSecond,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _Hdr extends StatelessWidget {
  final String t;
  const _Hdr(this.t);
  @override
  Widget build(BuildContext context) {
    return Text(t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AC.textMuted,
          letterSpacing: 0.8,
        ));
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
