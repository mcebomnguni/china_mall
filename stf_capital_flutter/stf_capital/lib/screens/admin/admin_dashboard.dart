// ─────────────────────────────────────────────────────────────────────────────
//  screens/admin/admin_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _filter = 'all';
  String _search = '';

  static const _filters = [
    ('all',             'All'),
    ('pending_review',  'Pending'),
    ('opened',          'Opened'),
    ('pending_outcome', 'Pending Outcome'),
    ('returned',        'Returned'),
    ('approved',        'Approved'),
    ('declined',        'Declined'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc  = context.watch<ApplicationService>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const StfLogo(size: 32),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeService>().isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => context.read<ThemeService>().toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: () => context.push('/admin/users'),
            tooltip: 'Manage Users',
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => context.push('/admin/document-review'),
            tooltip: 'Document Review',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Dashboard',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 4),
                            Text('Manage all client applications',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // Stats quick view using StreamBuilder
                      StreamBuilder<List<ServiceApplication>>(
                        stream: svc.allApplicationsStream(),
                        builder: (ctx, snap) {
                          final apps = snap.data ?? [];
                          final pending = apps.where((a) =>
                              a.status == ApplicationStatus.pendingReview).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color:  AppTheme.statusPending.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.statusPending.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Text('$pending',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 24, fontWeight: FontWeight.w700,
                                    color: AppTheme.statusPending,
                                  ),
                                ),
                                Text('Pending',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10, color: AppTheme.statusPending,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const GoldDivider(),
                  const SizedBox(height: 16),

                  // ── Search
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.montserrat(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText:    'Search by client name, company or product...',
                      prefixIcon:  const Icon(Icons.search_rounded, size: 18),
                      filled:      true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border:      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:   BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:   BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:   const BorderSide(color: AppTheme.goldLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.goldLight.withOpacity(0.15)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active
                                      ? AppTheme.goldLight
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Text(f.$2,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: active
                                      ? AppTheme.goldLight
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Applications list
            Expanded(
              child: StreamBuilder<List<ServiceApplication>>(
                stream: svc.allApplicationsStream(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.goldLight),
                    );
                  }
                  var apps = snap.data ?? [];

                  // Filter
                  if (_filter != 'all') {
                    apps = apps.where((a) => a.status.firestoreValue == _filter).toList();
                  }

                  // Search
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    apps = apps.where((a) =>
                      a.clientName.toLowerCase().contains(q) ||
                      a.companyName.toLowerCase().contains(q) ||
                      a.selectedProductName.toLowerCase().contains(q) ||
                      a.productCategoryName.toLowerCase().contains(q)
                    ).toList();
                  }

                  if (apps.isEmpty) {
                    return Center(
                      child: Text('No applications found.',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: apps.length,
                    itemBuilder: (ctx, i) => ApplicationTile(
                      app:     apps[i],
                      isAdmin: true,
                      onTap:   () => context.push('/application/${apps[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Users Screen
// ─────────────────────────────────────────────────────────────────────────────
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ApplicationService>();

    return StfScaffold(
      title: 'Registered Clients',
      body: StreamBuilder<List<AppUser>>(
        stream: svc.allUsersStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.goldLight),
            );
          }
          final users = (snap.data ?? [])
              .where((u) => u.role == UserRole.client)
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Text('No registered clients.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final user = users[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.darkSurface2,
                      ),
                      child: Center(
                        child: Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                            style: GoogleFonts.montserrat(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(user.companyName,
                            style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppTheme.textGold,
                            ),
                          ),
                          Text(user.email,
                            style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('@${user.username}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11, color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
