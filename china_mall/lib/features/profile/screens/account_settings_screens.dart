import 'dart:convert';
 
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_notifier.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// (dark mode is intentionally excluded — owned by ThemeNotifier)
// ─────────────────────────────────────────────────────────────────────────────
 
const _kAnalyticsOptOut    = 'pref_analytics_opt_out';
const _kEmailNotifications = 'pref_email_notifications';
const _kPushNotifications  = 'pref_push_notifications';
const _kOrderUpdates       = 'pref_order_updates';
const _kPromotions         = 'pref_promotions';
const _kLanguage           = 'pref_language';
const _kCurrency           = 'pref_currency';
 
// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
 
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
 
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}
 
class _PreferencesScreenState extends State<PreferencesScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool   _darkMode           = false;
  bool   _analyticsOptOut    = false;
  bool   _emailNotifications = true;
  bool   _pushNotifications  = true;
  bool   _orderUpdates       = true;
  bool   _promotions         = false;
  String _language           = 'English';
  String _currency           = 'ZAR';
 
  bool _loading = true;
  bool _saving  = false;
 
  static const _languages  = ['English', 'Zulu', 'Xhosa', 'Afrikaans', 'Sotho'];
  static const _currencies = ['ZAR'];
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      // Dark mode is owned by ThemeNotifier — read it from there so we stay
      // in sync with whatever the root app is already showing.
      _darkMode           = Provider.of<ThemeNotifier>(context, listen: false).isDark;
      _analyticsOptOut    = prefs.getBool(_kAnalyticsOptOut)    ?? false;
      _emailNotifications = prefs.getBool(_kEmailNotifications) ?? true;
      _pushNotifications  = prefs.getBool(_kPushNotifications)  ?? true;
      _orderUpdates       = prefs.getBool(_kOrderUpdates)       ?? true;
      _promotions         = prefs.getBool(_kPromotions)         ?? false;
      _language           = prefs.getString(_kLanguage)         ?? 'English';
      _currency           = prefs.getString(_kCurrency)         ?? 'ZAR';
      _loading            = false;
    });
  }
 
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
 
      // Dark mode — delegate to ThemeNotifier so the root MaterialApp
      // switches immediately without a restart.
      await themeNotifier.setDark(_darkMode);
 
      // All other preferences — persist to SharedPreferences directly.
      await prefs.setBool(_kAnalyticsOptOut,    _analyticsOptOut);
      await prefs.setBool(_kEmailNotifications, _emailNotifications);
      await prefs.setBool(_kPushNotifications,  _pushNotifications);
      await prefs.setBool(_kOrderUpdates,       _orderUpdates);
      await prefs.setBool(_kPromotions,         _promotions);
      await prefs.setString(_kLanguage,         _language);
      await prefs.setString(_kCurrency,         _currency);
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _back,
          tooltip: 'Back',
        ),
        title: const Text(
          'Preferences',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Appearance ────────────────────────────────────────
                _Section(
                  title: 'Appearance',
                  children: [
                    _SwitchTile(
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme throughout the app',
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                    ),
                  ],
                ),
 
                // ── Language & Currency ───────────────────────────────
                _Section(
                  title: 'Language & Currency',
                  children: [
                    _DropdownTile<String>(
                      title: 'Language',
                      value: _language,
                      items: _languages,
                      onChanged: (v) => setState(() => _language = v),
                    ),
                    _DropdownTile<String>(
                      title: 'Currency',
                      value: _currency,
                      items: _currencies,
                      onChanged: (v) => setState(() => _currency = v),
                    ),
                  ],
                ),
 
                // ── Notifications ─────────────────────────────────────
                _Section(
                  title: 'Notifications',
                  children: [
                    _SwitchTile(
                      title: 'Push Notifications',
                      value: _pushNotifications,
                      onChanged: (v) =>
                          setState(() => _pushNotifications = v),
                    ),
                    _SwitchTile(
                      title: 'Email Notifications',
                      value: _emailNotifications,
                      onChanged: (v) =>
                          setState(() => _emailNotifications = v),
                    ),
                    _SwitchTile(
                      title: 'Order Updates',
                      subtitle: 'Status changes and delivery updates',
                      value: _orderUpdates,
                      onChanged: (v) => setState(() => _orderUpdates = v),
                    ),
                    _SwitchTile(
                      title: 'Promotions & Deals',
                      subtitle: 'Special offers and discounts',
                      value: _promotions,
                      onChanged: (v) => setState(() => _promotions = v),
                    ),
                  ],
                ),
 
                // ── Privacy ───────────────────────────────────────────
                _Section(
                  title: 'Privacy',
                  children: [
                    _SwitchTile(
                      title: 'Opt Out of Analytics',
                      subtitle: 'Disable anonymous usage data collection',
                      value: _analyticsOptOut,
                      onChanged: (v) =>
                          setState(() => _analyticsOptOut = v),
                    ),
                  ],
                ),
 
                // ── Save ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.3),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// PERMISSIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
 
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
 
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}
 
class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, PermissionStatus> _statuses = {};
  bool _loading = true;
 
  static const _permDefs = [
    _PermDef(
      Permission.camera,
      'Camera',
      'Take photos of products or ID documents',
      CupertinoIcons.camera,
    ),
    _PermDef(
      Permission.photos,
      'Photo Library',
      'Upload product images and documents',
      CupertinoIcons.photo,
    ),
    _PermDef(
      Permission.location,
      'Location',
      'Delivery tracking and finding nearby stores',
      CupertinoIcons.location,
    ),
    _PermDef(
      Permission.notification,
      'Notifications',
      'Order updates and delivery alerts',
      CupertinoIcons.bell,
    ),
    _PermDef(
      Permission.storage,
      'Storage',
      'Save files and downloaded documents',
      CupertinoIcons.folder,
    ),
  ];
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _checkAll();
  }
 
  Future<void> _checkAll() async {
    setState(() => _loading = true);
    final map = <String, PermissionStatus>{};
    for (final p in _permDefs) {
      map[p.label] = await p.permission.status;
    }
    if (mounted) {
      setState(() {
        _statuses = map;
        _loading  = false;
      });
    }
  }
 
  Future<void> _request(_PermDef p) async {
    final result = await p.permission.request();
    if (result.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${p.label} is permanently denied — opening app settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await openAppSettings();
    }
    await _checkAll();
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _back,
          tooltip: 'Back',
        ),
        title: const Text(
          'App Permissions',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'China Stall Market Place only requests the permissions it needs. '
                    'You can change these at any time.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
 
                // Permission cards
                ..._permDefs.map((p) {
                  final status  = _statuses[p.label];
                  final granted = status?.isGranted ?? false;
                  final denied  = status?.isPermanentlyDenied ?? false;
 
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: granted
                              ? Colors.green.withValues(alpha: 0.12)
                              : AppColors.border.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          p.icon,
                          size: 20,
                          color:
                              granted ? Colors.green : AppColors.textTertiary,
                        ),
                      ),
                      title: Text(
                        p.label,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            p.description,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (denied) ...[
                            const SizedBox(height: 3),
                            const Text(
                              'Permanently denied — tap to open settings',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: CupertinoSwitch(
                        value: granted,
                        activeTrackColor: Colors.green,
                        onChanged: (_) => _request(p),
                      ),
                      isThreeLine: denied,
                    ),
                  );
                }),
 
                const SizedBox(height: 4),
                TextButton.icon(
                  icon: const Icon(CupertinoIcons.settings,
                      color: AppColors.primary, size: 18),
                  label: const Text(
                    'Open App Settings',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: openAppSettings,
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
 
class _PermDef {
  final Permission permission;
  final String     label;
  final String     description;
  final IconData   icon;
  const _PermDef(this.permission, this.label, this.description, this.icon);
}
 
// ─────────────────────────────────────────────────────────────────────────────
// DELETE ACCOUNT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
 
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
 
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}
 
class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  bool _confirmed = false;
  bool _obscure   = true;
  bool _deleting  = false;
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    // Rebuild button state as user types password.
    _passwordCtrl.addListener(() => setState(() {}));
  }
 
  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }
 
  // ── Delete ─────────────────────────────────────────────────────────────────
 
  bool get _canDelete =>
      _confirmed && _passwordCtrl.text.isNotEmpty && !_deleting;
 
  Future<void> _deleteAccount() async {
    // Second confirmation dialog — last chance before the irreversible call.
    final sure = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This cannot be undone. Your account and all associated data '
          'will be permanently deleted.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
 
    if (sure != true || !mounted) return;
    setState(() => _deleting = true);
 
    try {
      final ok = await context.read<AuthProvider>().deleteAccount(
            password: _passwordCtrl.text,
          );
      if (ok) {
        if (!mounted) return;
        context.go('/login');
        return;
      }

      final token = await AuthService.getAccessToken();
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/auth/delete-account/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': _passwordCtrl.text}),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        await AuthService.clearTokens();
        if (mounted) {
          context.go('/login');
        }
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _showError(
          body['error']?.toString() ??
          body['detail']?.toString() ??
          'Deletion failed. Please try again.',
        );
      }
    } catch (_) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
 
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _back,
          tooltip: 'Back',
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: Colors.red,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              color: Colors.red.withValues(alpha: 0.2), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ── Warning banner ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      size: 32, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'Delete Your Account?',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This action is permanent and cannot be undone.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 24),
 
            // ── Consequence list ──────────────────────────────────────
            const Text(
              'What will happen:',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
 
            ...[
              'Your profile and personal data will be deleted within 30 days',
              'Active orders will be cancelled immediately',
              'Store listings will be removed from the platform',
              'Your order history will be anonymised for legal compliance',
              'Pending payouts will be processed before deletion',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
 
            const SizedBox(height: 28),
 
            // ── Password ──────────────────────────────────────────────
            const Text(
              'Enter your password to confirm:',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.red, width: 1.5),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
 
            // ── Checkbox ──────────────────────────────────────────────
            CheckboxListTile.adaptive(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v!),
              activeColor: Colors.red,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand this is permanent and cannot be reversed.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
 
            const SizedBox(height: 28),
 
            // ── Delete button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canDelete ? _deleteAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withAlpha(76),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Permanently Delete Account',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
 
            const SizedBox(height: 12),
 
            // ── Cancel escape ─────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: _back,
                child: const Text(
                  'Cancel — keep my account',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Shared private widgets
// ─────────────────────────────────────────────────────────────────────────────
 
/// Section header + children + bottom divider.
class _Section extends StatelessWidget {
  final String        title;
  final List<Widget>  children;
  const _Section({required this.title, required this.children});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}
 
/// Adaptive switch row styled to match the app theme.
class _SwitchTile extends StatelessWidget {
  final String   title;
  final String?  subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;
 
  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
 
  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      value: value,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
 
/// Dropdown row styled to match the app theme.
class _DropdownTile<T> extends StatelessWidget {
  final String        title;
  final T             value;
  final List<T>       items;
  final ValueChanged<T> onChanged;
 
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });
 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        items: items
            .map((i) => DropdownMenuItem<T>(
                  value: i,
                  child: Text(i.toString()),
                ))
            .toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
