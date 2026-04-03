import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/buyer_dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/stores/screens/stores_screen.dart';
import '../../features/stores/screens/store_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/orders/screens/returns_screen.dart';
import '../../features/orders/screens/disputes_screen.dart';
import '../../features/payments/screens/checkout_screen.dart';
import '../../features/payments/screens/payment_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/screens/vendor_products_screen.dart';
import '../../features/vendor/screens/vendor_orders_screen.dart';
import '../../features/vendor/screens/vendor_payouts_screen.dart';
import '../../features/vendor/screens/add_product_screen.dart';
import '../../features/vendor/screens/vendor_type_screen.dart';
import '../../features/vendor/screens/vendor_onboarding_formal_screen.dart';
import '../../features/vendor/screens/vendor_onboarding_informal_screen.dart';
import '../../features/courier/screens/courier_dashboard_screen.dart';
import '../../features/courier/screens/courier_home_screen.dart';
import '../../features/courier/screens/pickup_assignments_screen.dart';
import '../../features/courier/screens/pickup_detail_screen.dart';
import '../../features/courier/screens/active_deliveries_screen.dart';
import '../../features/courier/screens/delivery_handoff_screen.dart';
import '../../features/courier/screens/courier_history_screen.dart';
import '../../features/courier/screens/courier_earnings_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/trends/screens/trends_screen.dart';
import '../../main_shell.dart';
import '../../core/widgets/error_widgets.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/vendor/screens/register_store_screen.dart';
import '../../features/vendor/screens/edit_product_screen.dart';
import '../../features/vendor/screens/manage_store_screen.dart';
import '../../features/vendor/screens/vendor_ads_screen.dart';
import '../../features/vendor/screens/vendor_analytics_screen.dart';
import '../../features/vendor/screens/vendor_order_detail_screen.dart';
import '../../features/products/screens/search_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/support/screens/support_tickets_screen.dart';
import '../../features/support/screens/create_ticket_screen.dart';
import '../../features/support/screens/ticket_chat_screen.dart';
import '../../features/auth/screens/security_setup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/customer/screens/referral_screen.dart';

// ── Custom page transition helpers ──────────────────────────────────────────
CustomTransitionPage<void> _slideTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}

CustomTransitionPage<void> _fadeTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
  );
}

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/splash',
    refreshListenable: auth, // Critical: This tells the router to rebuild when auth status changes
    errorBuilder: (context, state) => NotFoundWidget(
      onGoHome: () => context.go('/'),
    ),
    redirect: (context, state) {
      final status = auth.status;
      final location = state.uri.path;

      // 1. If we are still checking (Unknown), stay on splash
      if (status == AuthStatus.unknown) return '/splash';

      // 2. First-time launch → show onboarding
      if (!auth.onboardingDone && location != '/onboarding') {
        return '/onboarding';
      }

      // 3. Define routes that anyone can see
      final publicRoutes = ['/splash', '/login', '/register', '/onboarding', '/security-setup', '/forgot-password'];

      // 4. If NOT logged in, and trying to go to a private area → Force Login
      if (status == AuthStatus.unauthenticated) {
        if (!publicRoutes.contains(location)) {
          return '/login';
        }
        // Also, if we are stuck on splash but we ARE unauthenticated, move to login
        if (location == '/splash') {
          return '/login';
        }
      }

      // 5. If authenticated, check if security setup is needed
      if (status == AuthStatus.authenticated && auth.needsSecuritySetup && location != '/security-setup') {
        // Only prompt once per login — skip if coming from setup
        if (publicRoutes.contains(location)) {
          return '/security-setup';
        }
      }

      // 6. If ALREADY logged in, don't let them see the login/register/splash pages
      if (status == AuthStatus.authenticated && publicRoutes.contains(location)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/security-setup',
        builder: (_, __) => const SecuritySetupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // ── Tab-level routes (fade transition) ──────────────────
          GoRoute(
            path: '/',
            pageBuilder: (_, state) {
              Widget screen;
              if (auth.isVendor) {
                screen = const VendorDashboardScreen();
              } else if (auth.isCourier) {
                screen = const CourierDashboardScreen();
              } else if (auth.isStaff) {
                screen = const AdminDashboardScreen();
              } else {
                screen = const HomeScreen();
              }
              return _fadeTransitionPage(child: screen, state: state);
            },
          ),
          GoRoute(
              path: '/products',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const ProductsScreen(), state: state)),
          GoRoute(
              path: '/trends',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const TrendsScreen(), state: state)),
          GoRoute(
              path: '/cart',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const CartScreen(), state: state)),
          GoRoute(
              path: '/profile',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const ProfileScreen(), state: state)),
          GoRoute(
              path: '/vendor',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const VendorDashboardScreen(), state: state)),
          GoRoute(
              path: '/courier',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const CourierHomeScreen(), state: state)),
          GoRoute(
              path: '/admin',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const AdminDashboardScreen(), state: state)),

          // ── Push-level routes (slide + fade transition) ────────
          GoRoute(
              path: '/products/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: ProductDetailScreen(id: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/stores',
              pageBuilder: (_, state) => _slideTransitionPage(child: const StoresScreen(), state: state)),
          GoRoute(
              path: '/stores/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: StoreDetailScreen(id: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/orders',
              pageBuilder: (_, state) => _slideTransitionPage(child: const OrdersScreen(), state: state)),
          GoRoute(
              path: '/orders/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: OrderDetailScreen(id: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/orders/:id/track',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: OrderTrackingScreen(id: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/checkout',
              pageBuilder: (_, state) => _slideTransitionPage(child: const CheckoutScreen(), state: state)),
          GoRoute(
              path: '/payment/:orderId',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: PaymentScreen(orderId: int.parse(state.pathParameters['orderId']!)), state: state)),
          GoRoute(
              path: '/vendor/products',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const VendorProductsScreen(), state: state)),
          GoRoute(
              path: '/vendor/products/add',
              pageBuilder: (_, state) => _slideTransitionPage(child: const AddProductScreen(), state: state)),
          GoRoute(
              path: '/courier/pickups',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const PickupAssignmentsScreen(), state: state)),
          GoRoute(
              path: '/courier/pickup/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: PickupDetailScreen(assignmentId: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/courier/deliveries',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const ActiveDeliveriesScreen(), state: state)),
          GoRoute(
              path: '/courier/deliver/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: DeliveryHandoffScreen(deliveryId: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/courier/history',
              pageBuilder: (_, state) => _slideTransitionPage(child: const CourierHistoryScreen(), state: state)),
          GoRoute(
              path: '/courier/earnings',
              pageBuilder: (_, state) => _slideTransitionPage(child: const CourierEarningsScreen(), state: state)),
          GoRoute(
              path: '/referral',
              pageBuilder: (_, state) => _slideTransitionPage(child: const ReferralScreen(), state: state)),
          GoRoute(
              path: '/profile/edit',
              pageBuilder: (_, state) => _slideTransitionPage(child: const EditProfileScreen(), state: state)),
          GoRoute(
              path: '/profile/password',
              pageBuilder: (_, state) => _slideTransitionPage(child: const ChangePasswordScreen(), state: state)),
          GoRoute(
              path: '/orders/returns',
              pageBuilder: (_, state) => _slideTransitionPage(child: const ReturnsScreen(), state: state)),
          GoRoute(
              path: '/orders/disputes',
              pageBuilder: (_, state) => _slideTransitionPage(child: const DisputesScreen(), state: state)),
          GoRoute(
              path: '/payments/history',
              pageBuilder: (_, state) => _slideTransitionPage(child: const PaymentHistoryScreen(), state: state)),
          GoRoute(
              path: '/vendor/orders',
              pageBuilder: (_, state) => _fadeTransitionPage(child: const VendorOrdersScreen(), state: state)),
          GoRoute(
              path: '/vendor/payouts',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorPayoutsScreen(), state: state)),
          GoRoute(
              path: '/vendor/store',
              pageBuilder: (_, state) => _slideTransitionPage(child: const ManageStoreScreen(), state: state)),
          GoRoute(
              path: '/vendor/store/register',
              pageBuilder: (_, state) => _slideTransitionPage(child: const RegisterStoreScreen(), state: state)),
          GoRoute(
              path: '/vendor/setup',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorTypeScreen(), state: state)),
          GoRoute(
              path: '/vendor/onboarding/formal',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorOnboardingFormalScreen(), state: state)),
          GoRoute(
              path: '/vendor/onboarding/informal',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorOnboardingInformalScreen(), state: state)),
          GoRoute(
              path: '/vendor/products/:id/edit',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: EditProductScreen(productId: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/vendor/orders/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: VendorOrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)), state: state)),
          GoRoute(
              path: '/vendor/ads',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorAdsScreen(), state: state)),
          GoRoute(
              path: '/vendor/analytics',
              pageBuilder: (_, state) => _slideTransitionPage(child: const VendorAnalyticsScreen(), state: state)),
          GoRoute(
              path: '/search',
              pageBuilder: (_, state) => _slideTransitionPage(child: const SearchScreen(), state: state)),
          GoRoute(
              path: '/dashboard',
              pageBuilder: (_, state) => _slideTransitionPage(child: const BuyerDashboardScreen(), state: state)),
          GoRoute(
              path: '/notifications',
              pageBuilder: (_, state) => _slideTransitionPage(child: const NotificationsScreen(), state: state)),
          GoRoute(
              path: '/support',
              pageBuilder: (_, state) => _slideTransitionPage(child: const SupportTicketsScreen(), state: state)),
          GoRoute(
              path: '/support/new',
              pageBuilder: (_, state) => _slideTransitionPage(child: const CreateTicketScreen(), state: state)),
          GoRoute(
              path: '/support/:id',
              pageBuilder: (_, state) => _slideTransitionPage(
                  child: TicketChatScreen(ticketId: int.parse(state.pathParameters['id']!)), state: state)),
        ],
      ),
    ],
  );
}
