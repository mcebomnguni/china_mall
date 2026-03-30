import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'linked_devices_screen.dart';
import 'account_settings_screens.dart';
import 'static_screens.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences key for biometric state
// ─────────────────────────────────────────────────────────────────────────────
const _kBiometricKey = 'biometric_enabled';
 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _biometricEnabled = false;
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }
 
  /// Load persisted biometric toggle state so it survives cold restarts.
  Future<void> _loadBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _biometricEnabled = prefs.getBool(_kBiometricKey) ?? false);
    }
  }
 
  // ── Biometric toggle ───────────────────────────────────────────────────────
 
  Future<void> _toggleBiometrics(bool enabled) async {
    if (enabled) {
      try {
        final bool canAuth =
            await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (!canAuth) {
          _showSnackBar('Biometrics not supported on this device', isError: true);
          return;
        }
 
        final bool didAuth = await _auth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
        );
 
        if (didAuth) {
          await _saveBiometricPref(true);
          if (mounted) setState(() => _biometricEnabled = true);
          _showSnackBar('Biometrics enabled successfully');
        }
      } catch (e) {
        _showSnackBar('Authentication failed: $e', isError: true);
      }
    } else {
      await _saveBiometricPref(false);
      if (mounted) setState(() => _biometricEnabled = false);
      _showSnackBar('Biometrics disabled');
    }
  }
 
  Future<void> _saveBiometricPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricKey, value);
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  /// Push a screen using Navigator so the back button always works correctly
  /// regardless of whether go_router has a matching named route.
  void _push(Widget screen) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => screen),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? {};
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final username = user['username'] ?? 'User';
    final role = user['role'] ?? 'buyer';
    final email = user['email'] ?? '';
 
    final Color roleColor = switch (role) {
      'vendor' => AppColors.storeColor,
      'courier' => AppColors.courierColor,
      'staff' || 'admin' => AppColors.adminColor,
      _ => AppColors.black,
    };
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── OS Top Bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('OS / ${role.toUpperCase()}',
                        style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('ACTIVE',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
 
              const SizedBox(height: 24),
 
              // ── Avatar ─────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Center(
                  child: Icon(
                    switch (role) {
                      'vendor' => CupertinoIcons.house_fill,
                      'courier' => CupertinoIcons.car_fill,
                      'staff' || 'admin' => CupertinoIcons.shield_lefthalf_fill,
                      _ => CupertinoIcons.person_fill,
                    },
                    size: 36,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name.isNotEmpty ? name : username,
                style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black),
              ),
              const SizedBox(height: 2),
              Text(
                role.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: roleColor),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: AppColors.textTertiary)),
              ],
 
              const SizedBox(height: 32),
 
              // ── Menu sections ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account ───────────────────────────────────────
                    const SectionLabel(title: 'Account'),
                    const SizedBox(height: 8),
                    OsCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: CupertinoIcons.person,
                            label: 'Edit Profile',
                            onTap: () => _push(const EditProfileScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.lock,
                            label: 'Change Password',
                            onTap: () => _push(const ChangePasswordScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.bell,
                            label: 'Notifications',
                            onTap: () => _push(const NotificationsScreen()),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 20),
 
                    // ── Security ──────────────────────────────────────
                    const SectionLabel(title: 'Security'),
                    const SizedBox(height: 8),
                    OsCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // Biometric toggle row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(9)),
                                  child: const Icon(
                                      CupertinoIcons.device_phone_portrait,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Biometric Login',
                                      style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                ),
                                Switch.adaptive(
                                  value: _biometricEnabled,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (v) => _toggleBiometrics(v),
                                ),
                              ],
                            ),
                          ),
                          _Divider(),
                            _MenuItem(
                            icon: CupertinoIcons.device_phone_portrait,
                            label: 'Linked Devices',
                            onTap: () => _push(const LinkedDevicesScreen()),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 20),
 
                    // ── Store (vendor only) ───────────────────────────
                    if (auth.isVendor) ...[
                      const SectionLabel(title: 'Store'),
                      const SizedBox(height: 8),
                      OsCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _MenuItem(
                              icon: CupertinoIcons.house_fill,
                              label: 'My Store',
                              onTap: () => context.go('/vendor/store'),
                            ),
                            _Divider(),
                            _MenuItem(
                              icon: CupertinoIcons.cube_box,
                              label: 'My Products',
                              onTap: () => context.go('/vendor/products'),
                            ),
                            _Divider(),
                            _MenuItem(
                              icon: CupertinoIcons.chart_bar_fill,
                              label: 'Payouts',
                              onTap: () => context.go('/vendor/payouts'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
 
                    // ── Preferences ───────────────────────────────────
                    const SectionLabel(title: 'Preferences'),
                    const SizedBox(height: 8),
                    OsCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: CupertinoIcons.slider_horizontal_3,
                            label: 'App Preferences',
                            onTap: () => _push(const PreferencesScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.checkmark_shield,
                            label: 'App Permissions',
                            onTap: () => _push(const PermissionsScreen()),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 20),
 
                    // ── App ───────────────────────────────────────────
                    const SectionLabel(title: 'App'),
                    const SizedBox(height: 8),
                    OsCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: CupertinoIcons.question_circle,
                            label: 'Help & Support',
                            onTap: () => _push(const HelpSupportScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.chat_bubble_text,
                            label: 'Contact Us',
                            onTap: () => _push(const ContactUsScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.arrow_2_circlepath,
                            label: 'Return & Refund Policy',
                            onTap: () => _push(const ReturnRefundScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.doc_text,
                            label: 'Privacy Policy',
                            onTap: () => _push(const PrivacyPolicyScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.doc_text,
                            label: 'Terms of Service',
                            onTap: () =>
                                _push(const TermsAndConditionsScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.info_circle,
                            label: 'About China Stall Market Place',
                            onTap: () => _showAbout(context),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 20),
 
                    // ── Danger zone ───────────────────────────────────
                    OsCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: CupertinoIcons.square_arrow_left,
                            label: 'Sign Out',
                            labelColor: AppColors.error,
                            iconColor: AppColors.error,
                            showChevron: false,
                            onTap: () => _confirmLogout(context, auth),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: CupertinoIcons.trash,
                            label: 'Delete Account',
                            labelColor: AppColors.error,
                            iconColor: AppColors.error,
                            onTap: () => _push(const DeleteAccountScreen()),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'China Stall Market Place v1.0.0',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            color: AppColors.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // ── Dialogs ────────────────────────────────────────────────────────────────
 
  void _showAbout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('China Stall Market Place'),
        content: const Text(
            'Version 1.0.0\nBuilt by Bountiful AI Labs\n\nYour local marketplace.'),
        actions: [
          CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }
 
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await Future.delayed(Duration.zero);
              auth.logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────
 
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;
 
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon,
                  size: 15, color: iconColor ?? AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: labelColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (showChevron)
              const Icon(CupertinoIcons.chevron_right,
                  size: 13, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
 
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 60, endIndent: 0, color: AppColors.border);
  }
}
