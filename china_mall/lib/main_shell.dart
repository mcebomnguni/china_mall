import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _buyerTabs = [
    _TabItem(icon: CupertinoIcons.house_fill,      label: 'Main',     path: '/'),
    _TabItem(icon: CupertinoIcons.square_grid_2x2_fill, label: 'Feed', path: '/products'),
    _TabItem(icon: CupertinoIcons.bag_fill,        label: 'Activity', path: '/cart'),
    _TabItem(icon: CupertinoIcons.person_fill,     label: 'You',      path: '/profile'),
  ];

  static const _vendorTabs = [
    _TabItem(icon: CupertinoIcons.house_fill,      label: 'Main',     path: '/'),
    _TabItem(icon: CupertinoIcons.square_grid_2x2_fill, label: 'Stock', path: '/vendor/products'),
    _TabItem(icon: CupertinoIcons.cube_box_fill,   label: 'Orders',   path: '/vendor/orders'),
    _TabItem(icon: CupertinoIcons.person_fill,     label: 'You',      path: '/profile'),
  ];

  static const _courierTabs = [
    _TabItem(icon: CupertinoIcons.house_fill,      label: 'Home',     path: '/courier'),
    _TabItem(icon: Icons.inventory_2_outlined,     label: 'Pickups',  path: '/courier/pickups'),
    _TabItem(icon: Icons.local_shipping_outlined,  label: 'Deliver',  path: '/courier/deliveries'),
    _TabItem(icon: CupertinoIcons.person_fill,     label: 'You',      path: '/profile'),
  ];

  static const _staffTabs = [
    _TabItem(icon: CupertinoIcons.house_fill,      label: 'Main',     path: '/'),
    _TabItem(icon: CupertinoIcons.chart_pie_fill,  label: 'Ops',      path: '/admin'),
    _TabItem(icon: CupertinoIcons.house_fill, label: 'Stores',   path: '/stores'),
    _TabItem(icon: CupertinoIcons.person_fill,     label: 'You',      path: '/profile'),
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
      bottomNavigationBar: _OsNavBar(
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

// ─── Black pill bottom nav matching React prototype ──────────────────────────
class _OsNavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _OsNavBar({
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
          height: 64,
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
              final showBadge = tab.path == '/cart' && cartCount > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with optional badge
                        showBadge
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
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.white
                                      : const Color(0x4DFFFFFF),
                                ),
                              )
                            : Icon(
                                tab.icon,
                                size: 20,
                                color: isSelected
                                    ? AppColors.white
                                    : const Color(0x4DFFFFFF),
                              ),

                        // Active dot indicator (white dot below active icon)
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 4 : 0,
                          height: isSelected ? 4 : 0,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
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
