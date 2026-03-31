import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Row(
        children: [
          _Sidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatefulWidget {
  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isSA = await AdminApi.isSuperAdmin();
    if (mounted) setState(() => _isSuperAdmin = isSA);
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 240,
      color: AC.sidebar,
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AC.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🐉', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('China Stall',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        )),
                    Text(_isSuperAdmin ? 'Super Admin' : 'Admin Portal',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Nav items ──────────────────────────────
                  _NavSection(label: 'MANAGEMENT', items: [
                    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                      path: '/dashboard', active: loc == '/dashboard'),
                    _NavItem(icon: Icons.store_rounded, label: 'Store Approvals',
                      path: '/vendors', active: loc.startsWith('/vendors')),
                    _NavItem(icon: Icons.inventory_2_rounded, label: 'Product Approvals',
                      path: '/products', active: loc.startsWith('/products')),
                  ]),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  _NavSection(label: 'OPERATIONS', items: [
                    _NavItem(icon: Icons.local_shipping_rounded, label: 'Orders',
                      path: '/orders', active: loc.startsWith('/orders')),
                    _NavItem(icon: Icons.payments_rounded, label: 'Payments',
                      path: '/payments', active: loc.startsWith('/payments')),
                    _NavItem(icon: Icons.support_agent_rounded, label: 'Help Desk',
                      path: '/helpdesk', active: loc.startsWith('/helpdesk')),
                    _NavItem(icon: Icons.inventory_rounded, label: 'Inventory',
                      path: '/inventory', active: loc.startsWith('/inventory')),
                  ]),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  _NavSection(label: 'INSIGHTS', items: [
                    _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics',
                      path: '/analytics', active: loc == '/analytics'),
                  ]),

                  if (_isSuperAdmin) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),

                    _NavSection(label: 'SUPER ADMIN', items: [
                      _NavItem(icon: Icons.account_balance_rounded, label: 'Financials',
                        path: '/financials', active: loc.startsWith('/financials')),
                      _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin Team',
                        path: '/admin-mgmt', active: loc.startsWith('/admin-mgmt')),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // ── Logout ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await AdminApi.signOut();
                if (context.mounted) context.go('/login');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
                    SizedBox(width: 12),
                    Text('Sign Out',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String label;
  final List<_NavItem> items;
  const _NavSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white30, fontSize: 10, letterSpacing: 1.2)),
        ),
        ...items,
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   path;
  final bool     active;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AC.primary.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18,
                  color: active ? Colors.white : Colors.white60),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  )),
              if (active) ...[
                const Spacer(),
                Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
