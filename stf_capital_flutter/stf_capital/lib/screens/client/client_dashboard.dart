// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/client_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/notification_icon.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }
    
    final svc = context.read<ApplicationService>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: const StfLogo(size: 32),
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const NotificationIcon(),
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () => _confirmLogout(context, context.read<AuthService>()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome
                  _WelcomeBanner(
                    title: 'Welcome back, ${user?.firstName ?? 'User'}!',
                    subtitle: 'Manage your applications and access services',
                    icon: Icons.dashboard,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 32),

                  // ── Services
                  Text('Our Services',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24, fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const GoldDivider(),
                  const SizedBox(height: 20),

                  // ── Service Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 500 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _ServiceCard(
                        title: 'Insurance Bonds & Guarantees',
                        icon: Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => context.push('/insurance-bonds'),
                      ),
                      _ServiceCard(
                        title: 'Financial Advisory',
                        icon: Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => context.push('/financial-advisory'),
                      ),
                      _ServiceCard(
                        title: 'General Insurance',
                        icon: Icons.health_and_safety,
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => context.push('/general-insurance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Applications
                  Text('My Applications',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24, fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const GoldDivider(),
                  const SizedBox(height: 20),

                  // ── Stream
                  StreamBuilder<List<ServiceApplication>>(
                    stream: svc.clientApplicationsStream(user?.uid ?? ''),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      final apps = snap.data ?? [];
                      if (apps.isEmpty) {
                        return _EmptyState();
                      }
                      return Column(
                        children: apps.map((app) => _ApplicationCard(
                          application: app,
                          onTap: () => context.push('/application/${app.id}'),
                        )).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // FAB clearance
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Sign Out',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700,
          ),
        ),
        content: Text('Are you sure you want to sign out?',
          style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const _WelcomeBanner({
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.gold.withOpacity(0.15),
              AppTheme.gold.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldGradient,
              ),
              child: Center(
                child: icon != null 
                    ? Icon(icon!, size: 24, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.montserrat(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: AppTheme.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text('No Applications Yet',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to submit your first application.',
            style: GoogleFonts.montserrat(
              fontSize: 13, color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/insurance-bonds'),
            child: const Text('Start Application'),
          ),
        ],
      ),
    ),
  );
}

// Application Card Widget (looks like service cards)
class _ApplicationCard extends StatelessWidget {
  final ServiceApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get status color
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (application.status) {
      case ApplicationStatus.pendingReview:
        statusColor = AppTheme.statusPending;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending Review';
        break;
      case ApplicationStatus.approved:
        statusColor = AppTheme.statusApproved;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case ApplicationStatus.returned:
        statusColor = AppTheme.statusReturned;
        statusIcon = Icons.keyboard_return;
        statusText = 'Returned';
        break;
      case ApplicationStatus.declined:
        statusColor = AppTheme.statusDeclined;
        statusIcon = Icons.cancel;
        statusText = 'Declined';
        break;
      default:
        statusColor = AppTheme.statusPending;
        statusIcon = Icons.help_outline;
        statusText = 'Unknown';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Service Type
                Text(
                  application.productCategoryName,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Client Name
                Text(
                  application.clientName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Company Name
                Text(
                  application.companyName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Submitted Date
                Text(
                  'Submitted: ${DateFormat('dd MMM yyyy').format(application.createdAt)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
