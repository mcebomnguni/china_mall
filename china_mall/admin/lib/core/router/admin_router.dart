import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/shell/admin_shell.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/vendor_approvals/vendor_list_screen.dart';
import '../../screens/vendor_approvals/vendor_detail_screen.dart';
import '../../screens/product_approvals/product_list_screen.dart';
import '../../screens/product_approvals/product_detail_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/payments/payments_screen.dart';
import '../../screens/helpdesk/ticket_list_screen.dart';
import '../../screens/helpdesk/ticket_detail_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/financials/financials_screen.dart';
import '../../screens/admin_mgmt/admin_mgmt_screen.dart';
import '../services/supabase_service.dart';

final adminRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final loggedIn = AdminSupabase.isLoggedIn;
    final onLogin  = state.matchedLocation == '/login';
    if (!loggedIn && !onLogin) return '/login';
    if (loggedIn  &&  onLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
        GoRoute(
          path: '/vendors',
          builder: (_, __) => const VendorListScreen(),
          routes: [
            GoRoute(path: ':id', builder: (_, state) =>
                VendorDetailScreen(id: int.parse(state.pathParameters['id']!))),
          ],
        ),
        GoRoute(
          path: '/products',
          builder: (_, __) => const ProductListScreen(),
          routes: [
            GoRoute(path: ':id', builder: (_, state) =>
                ProductDetailScreen(id: int.parse(state.pathParameters['id']!))),
          ],
        ),
        GoRoute(path: '/orders',     builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/payments',   builder: (_, __) => const PaymentsScreen()),
        GoRoute(
          path: '/helpdesk',
          builder: (_, __) => const TicketListScreen(),
          routes: [
            GoRoute(path: ':id', builder: (_, state) =>
                TicketDetailScreen(id: int.parse(state.pathParameters['id']!))),
          ],
        ),
        GoRoute(path: '/inventory',  builder: (_, __) => const InventoryScreen()),
        GoRoute(path: '/analytics',  builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/financials', builder: (_, __) => const FinancialsScreen()),
        GoRoute(path: '/admin-mgmt', builder: (_, __) => const AdminMgmtScreen()),
      ],
    ),
  ],
);
