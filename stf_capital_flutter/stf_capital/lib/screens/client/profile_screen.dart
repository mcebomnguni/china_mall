// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/profile_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _editing  = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user   = context.read<AuthService>().currentUser;
    _firstCtrl   = TextEditingController(text: user?.firstName   ?? '');
    _lastCtrl    = TextEditingController(text: user?.lastName    ?? '');
    _phoneCtrl   = TextEditingController(text: user?.phone       ?? '');
    _companyCtrl = TextEditingController(text: user?.companyName ?? '');
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _phoneCtrl, _companyCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _success = null; });
    final auth = context.read<AuthService>();
    final err  = await auth.updateProfile(
      firstName:   _firstCtrl.text,
      lastName:    _lastCtrl.text,
      phone:       _phoneCtrl.text,
      companyName: _companyCtrl.text,
    );
    if (!mounted) return;
    if (err != null) setState(() => _error = err);
    else             setState(() { _editing = false; _success = 'Profile updated successfully.'; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    
    // Central color scheme pattern
    final theme = Theme.of(context).colorScheme;
    final bg = theme.background;
    final card = theme.surface;
    final primaryText = theme.onSurface;
    final secondaryText = theme.onSurface.withValues(alpha: 0.7);

    return StfScaffold(
      title: 'My Profile',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                      ),
                      child: Center(
                        child: Text(
                          user?.firstName.isNotEmpty == true
                              ? user!.firstName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 36, fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(user?.username ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 13, color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(user?.email ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_error != null)
                    ErrorBanner(
                      message:   _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),

                  if (_success != null)
                    InfoCard(
                      icon:    Icons.check_circle_outline_rounded,
                      message: _success!,
                      color:   AppTheme.statusApproved,
                    ),
                  if (_success != null) const SizedBox(height: 16),

                  // ── Fields
                  Row(
                    children: [
                      Expanded(
                        child: GoldTextField(
                          controller:         _firstCtrl,
                          label:              'First Name',
                          textCapitalization: TextCapitalization.words,
                          readOnly:           !_editing,
                          validator:          (v) =>
                              (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldTextField(
                          controller:         _lastCtrl,
                          label:              'Last Name',
                          textCapitalization: TextCapitalization.words,
                          readOnly:           !_editing,
                          validator:          (v) =>
                              (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GoldTextField(
                    controller:  _phoneCtrl,
                    label:       'Phone Number',
                    prefixIcon:  Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    readOnly:    !_editing,
                    validator:   (v) =>
                        (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  GoldTextField(
                    controller:         _companyCtrl,
                    label:              'Company Name',
                    prefixIcon:         Icons.business_outlined,
                    textCapitalization: TextCapitalization.words,
                    readOnly:           !_editing,
                    validator:          (v) =>
                        (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  if (_editing)
                    Row(
                      children: [
                        Expanded(
                          child: GoldButton(
                            label:    'Cancel',
                            outlined: true,
                            onPressed: () => setState(() => _editing = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GoldButton(
                            label:     'Save Changes',
                            onPressed: _saveProfile,
                            isLoading: auth.isLoading,
                          ),
                        ),
                      ],
                    )
                  else
                    GoldButton(
                      label:    'Edit Profile',
                      onPressed: () => setState(() => _editing = true),
                    ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),

                  // ── Security
                  _SectionLabel('Security'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon:    Icons.lock_reset_outlined,
                    label:   'Change Password',
                    onTap:   () => context.push('/change-password'),
                  ),
                  const SizedBox(height: 28),

                  const Divider(),
                  const SizedBox(height: 20),

                  _SectionLabel('Privacy'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon:    Icons.policy_outlined,
                    label:   'Privacy Policy',
                    onTap:   () => context.push('/privacy-policy'),
                  ),
                  const SizedBox(height: 28),

                  const Divider(),
                  const SizedBox(height: 20),

                  _SectionLabel('Appearance'),
                  const SizedBox(height: 12),
                  _ThemeToggleTile(),
                  const SizedBox(height: 28),

                  const Divider(),
                  const SizedBox(height: 20),

                  _SectionLabel('Danger Zone', color: AppTheme.error),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon:    Icons.delete_forever_outlined,
                    label:   'Delete Account',
                    color:   AppTheme.error,
                    onTap:   () => _showDeleteDialog(context, auth),
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

  void _showDeleteDialog(BuildContext context, AuthService auth) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Delete Account',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22, color: AppTheme.error, fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone. All your data will be permanently deleted.',
              style: GoogleFonts.montserrat(
                fontSize: 13, color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller:  passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm your password'),
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final err = await auth.deleteAccount(passCtrl.text);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              } else {
                context.go('/login');
              }
            },
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionLabel(this.text, {this.color});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: GoogleFonts.montserrat(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: color ?? AppTheme.goldLight, letterSpacing: 1.5,
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final Color?   color;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] // dark card
            : Colors.white,     // light card
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
              style: GoogleFonts.montserrat(
                fontSize: 13, color: color ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 18),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Change Password Screen
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;
  String? _error, _success;

  @override
  void dispose() { _currCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _success = null; });
    final err = await context.read<AuthService>().changePassword(
      currentPassword: _currCtrl.text,
      newPassword:     _newCtrl.text,
    );
    if (!mounted) return;
    if (err != null) setState(() => _error = err);
    else             setState(() => _success = 'Password changed successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return StfScaffold(
      title: 'Change Password',
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error   != null) ErrorBanner(message: _error!,
                        onDismiss: () => setState(() => _error = null)),
                    if (_success != null) InfoCard(
                        icon: Icons.check_circle_outline_rounded,
                        message: _success!, color: AppTheme.statusApproved),
                    if (_success != null) const SizedBox(height: 16),
                    GoldTextField(
                      controller:  _currCtrl,
                      label:       'Current Password',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscureText: _obscure1,
                      suffix: _visIcon(_obscure1, () => setState(() => _obscure1 = !_obscure1)),
                      validator:   (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    GoldTextField(
                      controller:  _newCtrl,
                      label:       'New Password',
                      prefixIcon:  Icons.lock_reset_outlined,
                      obscureText: _obscure2,
                      suffix: _visIcon(_obscure2, () => setState(() => _obscure2 = !_obscure2)),
                      validator:   (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (v!.length < 8) return 'At least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GoldTextField(
                      controller:  _confCtrl,
                      label:       'Confirm New Password',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscureText: _obscure3,
                      suffix: _visIcon(_obscure3, () => setState(() => _obscure3 = !_obscure3)),
                      validator:   (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 28),
                    GoldButton(
                      label:     'Update Password',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visIcon(bool hide, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Icon(
      hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 18, color: AppTheme.textSecondary,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Theme Toggle Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] // dark card
            : Colors.white,     // light card
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dark Mode',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => themeService.toggleTheme(),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
