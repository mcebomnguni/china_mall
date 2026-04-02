import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:lucide_icons/lucide_icons.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static final _buyerTabs = [
    _TabItem(icon: LucideIcons.home,        label: 'Home',   path: '/'),
    _TabItem(icon: LucideIcons.search,      label: 'Shop',   path: '/products'),
    _TabItem(icon: LucideIcons.trendingUp,  label: 'Trends', path: '/trends'),
    _TabItem(icon: LucideIcons.shoppingBag, label: 'Cart',   path: '/cart'),
    _TabItem(icon: LucideIcons.user,        label: 'Me',     path: '/profile'),
  ];

  static final _vendorTabs = [
    _TabItem(icon: LucideIcons.home,     label: 'Main',   path: '/'),
    _TabItem(icon: LucideIcons.package2, label: 'Stock',  path: '/vendor/products'),
    _TabItem(icon: LucideIcons.clipboardList, label: 'Orders', path: '/vendor/orders'),
    _TabItem(icon: LucideIcons.user,     label: 'Me',     path: '/profile'),
  ];

  static final _courierTabs = [
    _TabItem(icon: LucideIcons.home,      label: 'Home',    path: '/courier'),
    _TabItem(icon: LucideIcons.package2,  label: 'Pickups', path: '/courier/pickups'),
    _TabItem(icon: LucideIcons.truck,     label: 'Deliver', path: '/courier/deliveries'),
    _TabItem(icon: LucideIcons.user,      label: 'Me',      path: '/profile'),
  ];

  static final _staffTabs = [
    _TabItem(icon: LucideIcons.home,       label: 'Main',   path: '/'),
    _TabItem(icon: LucideIcons.barChart3,  label: 'Ops',    path: '/admin'),
    _TabItem(icon: LucideIcons.store,      label: 'Stores', path: '/stores'),
    _TabItem(icon: LucideIcons.user,       label: 'Me',     path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final cart  = context.watch<CartProvider>();
    final location = GoRouterState.of(context).uri.path;

    List<_TabItem> tabs;
    if (auth.isVendor) {
      tabs = _vendorTabs;
    } else if (auth.isCourier) {
      tabs = _courierTabs;
    } else if (auth.isStaff) {
      tabs = _staffTabs;
    } else {
      tabs = _buyerTabs;
    }

    int currentIndex = 0;
    int bestMatchLength = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].path == '/' && location == '/') {
        currentIndex = 0;
      } else if (tabs[i].path != '/' && location.startsWith(tabs[i].path)) {
        if (tabs[i].path.length > bestMatchLength) {
          bestMatchLength = tabs[i].path.length;
          currentIndex = i;
        }
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _ChinaStallNavBar(
        tabs: tabs,
        currentIndex: currentIndex,
        cartCount: cart.count,
        onTap: (i) {
          context.go(tabs[i].path);
        },
      ),
    );
  }
}

// ─── Floating dark pill bottom nav ──────────────────────────────────────────
class _ChinaStallNavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _ChinaStallNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isSelected = i == currentIndex;
              final isCart = tab.path == '/cart';
              final showBadge = isCart && cartCount > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active glow pill behind icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: showBadge
                              ? badges.Badge(
                                  badgeContent: Text(
                                    '$cartCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  badgeStyle: const badges.BadgeStyle(
                                    badgeColor: AppColors.primary,
                                    padding: EdgeInsets.all(3),
                                  ),
                                  child: Icon(
                                    tab.icon,
                                    size: 24,
                                    color: isSelected
                                        ? AppColors.white
                                        : const Color(0x80FFFFFF),
                                  ),
                                )
                              : Icon(
                                  tab.icon,
                                  size: 24,
                                  color: isSelected
                                      ? AppColors.white
                                      : const Color(0x80FFFFFF),
                                ),
                        ),
                      ),
                      // Label
                      const SizedBox(height: 2),
                      if (isSelected)
                        Text(
                          tab.label,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
