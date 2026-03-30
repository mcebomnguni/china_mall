import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_theme.dart';
 
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
 
  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}
 
class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users      = [];
  bool          _loading    = true;
  bool          _loadError  = false;
  String?       _roleFilter;
  final _searchCtrl = TextEditingController();
 
  // Debounce timer so search fires 400ms after typing stops.
  Timer? _debounce;
 
  static const _roles = [
    'customer', 'store_owner', 'courier', 'admin', 'super_admin',
  ];
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin');
    }
  }
 
  // ── Load ───────────────────────────────────────────────────────────────────
 
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = false; });
    try {
      final users = await AdminService.getUsers(
        role:   _roleFilter,
        search: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
      );
      if (mounted) setState(() => _users = users);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load users. Check your connection.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Search with debounce ───────────────────────────────────────────────────
 
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }
 
  // ── Toggle user active state ───────────────────────────────────────────────
 
  Future<void> _toggleUser(int userId, bool currentlyActive) async {
    final action = currentlyActive ? 'suspend' : 'activate';
    try {
      final res = await AdminService.userAction(userId, action);
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                res['error']?.toString() ?? 'Action failed.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
 
  // ── Create admin dialog ────────────────────────────────────────────────────
 
  void _showCreateAdminDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role        = 'admin';
 
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Create Admin Account',
            style: TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  textCapitalization: TextCapitalization.none,
                  decoration:
                      const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration:
                      const InputDecoration(labelText: 'Role'),
                  items: ['admin', 'super_admin']
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty ||
                    passwordCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All fields are required.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final res = await AdminService.createAdminUser(
                  username: usernameCtrl.text.trim(),
                  email:    emailCtrl.text.trim(),
                  password: passwordCtrl.text,
                  role:     role,
                );
                if (!mounted) return;
                if (res['statusCode'] == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin account created!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          res['error']?.toString() ??
                              'Failed to create admin.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_badge_plus,
                color: AppColors.textPrimary),
            onPressed: _showCreateAdminDialog,
            tooltip: 'Create Admin',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filter ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    // Fires search on every keystroke (debounced)
                    // AND on submit — covers backspace-to-clear.
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) {
                      _debounce?.cancel();
                      _load();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search username or email…',
                      prefixIcon:
                          const Icon(CupertinoIcons.search, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _debounce?.cancel();
                                _load();
                              },
                              child: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 16,
                                  color: AppColors.textTertiary),
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _roleFilter,
                  hint: const Text('Role',
                      style: TextStyle(
                          fontFamily: 'Satoshi', fontSize: 13)),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All')),
                    ..._roles.map((r) => DropdownMenuItem(
                        value: r, child: Text(r))),
                  ],
                  onChanged: (v) {
                    setState(() => _roleFilter = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
 
          // ── User count ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_users.length} user${_users.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
 
          // ── List ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.wifi_slash,
                                size: 40,
                                color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load users',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found.',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final u = _users[i]
                                    as Map<String, dynamic>;
                                final active =
                                    u['is_active'] == true;
                                final roleC = _roleColor(
                                    u['role']?.toString());
 
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        backgroundColor:
                                            roleC.withValues(alpha: 0.12),
                                        child: Text(
                                          ((u['username']
                                                          ?.toString() ??
                                                      '?')[0])
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontWeight:
                                                FontWeight.w700,
                                            color: roleC,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
 
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              u['username'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Satoshi',
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors
                                                    .textPrimary,
                                              ),
                                            ),
                                            Text(
                                              u['email'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Satoshi',
                                                fontSize: 12,
                                                color: AppColors
                                                    .textTertiary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 7,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleC
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(6),
                                              ),
                                              child: Text(
                                                u['role'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'Satoshi',
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: roleC,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
 
                                      // Active toggle
                                      Switch.adaptive(
                                        value: active,
                                        activeTrackColor: AppColors.success,
                                        onChanged: (_) => _toggleUser(
                                            u['id'], active),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
 
  // ── Role colour ────────────────────────────────────────────────────────────
 
  Color _roleColor(String? role) {
    switch (role) {
      case 'super_admin':  return AppColors.error;
      case 'admin':        return AppColors.adminColor;
      case 'store_owner':  return AppColors.storeColor;
      case 'courier':      return AppColors.courierColor;
      default:             return AppColors.info;
    }
  }
}