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
          GoRoute(
            path: '/',
            builder: (_, __) {
              if (auth.isVendor) return const VendorDashboardScreen();
              if (auth.isCourier) return const CourierDashboardScreen();
              if (auth.isStaff) return const AdminDashboardScreen();
              return const HomeScreen();
            },
          ),
          GoRoute(
              path: '/products',
              builder: (_, __) => const ProductsScreen()),
          GoRoute(
              path: '/products/:id',
              builder: (_, state) => ProductDetailScreen(
                  id: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/stores',
              builder: (_, __) => const StoresScreen()),
          GoRoute(
              path: '/stores/:id',
              builder: (_, state) => StoreDetailScreen(
                  id: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/trends',
              builder: (_, __) => const TrendsScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(
              path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(
              path: '/orders/:id',
              builder: (_, state) => OrderDetailScreen(
                  id: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/orders/:id/track',
              builder: (_, state) => OrderTrackingScreen(
                  id: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/checkout',
              builder: (_, __) => const CheckoutScreen()),
          GoRoute(
              path: '/payment/:orderId',
              builder: (_, state) => PaymentScreen(
                  orderId: int.parse(state.pathParameters['orderId']!))),
          GoRoute(
              path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/vendor',
              builder: (_, __) => const VendorDashboardScreen()),
          GoRoute(
              path: '/vendor/products',
              builder: (_, __) => const VendorProductsScreen()),
          GoRoute(
              path: '/vendor/products/add',
              builder: (_, __) => const AddProductScreen()),
          GoRoute(
              path: '/courier',
              builder: (_, __) => const CourierHomeScreen()),
          GoRoute(
              path: '/courier/pickups',
              builder: (_, __) => const PickupAssignmentsScreen()),
          GoRoute(
              path: '/courier/pickup/:id',
              builder: (_, state) => PickupDetailScreen(
                  assignmentId: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/courier/deliveries',
              builder: (_, __) => const ActiveDeliveriesScreen()),
          GoRoute(
              path: '/courier/deliver/:id',
              builder: (_, state) => DeliveryHandoffScreen(
                  deliveryId: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/courier/history',
              builder: (_, __) => const CourierHistoryScreen()),
          GoRoute(
              path: '/courier/earnings',
              builder: (_, __) => const CourierEarningsScreen()),
          GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: '/profile/edit',
              builder: (_, __) => const EditProfileScreen()),
          GoRoute(
              path: '/profile/password',
              builder: (_, __) => const ChangePasswordScreen()),
          GoRoute(
              path: '/orders/returns',
              builder: (_, __) => const ReturnsScreen()),
          GoRoute(
              path: '/orders/disputes',
              builder: (_, __) => const DisputesScreen()),
          GoRoute(
              path: '/payments/history',
              builder: (_, __) => const PaymentHistoryScreen()),
          GoRoute(
              path: '/vendor/orders',
              builder: (_, __) => const VendorOrdersScreen()),
          GoRoute(
              path: '/vendor/payouts',
              builder: (_, __) => const VendorPayoutsScreen()),
          GoRoute(
              path: '/vendor/store',
              builder: (_, __) => const ManageStoreScreen()),
          GoRoute(
              path: '/vendor/store/register',
              builder: (_, __) => const RegisterStoreScreen()),
          GoRoute(
              path: '/vendor/setup',
              builder: (_, __) => const VendorTypeScreen()),
          GoRoute(
              path: '/vendor/onboarding/formal',
              builder: (_, __) => const VendorOnboardingFormalScreen()),
          GoRoute(
              path: '/vendor/onboarding/informal',
              builder: (_, __) => const VendorOnboardingInformalScreen()),
          GoRoute(
              path: '/vendor/products/:id/edit',
              builder: (_, state) => EditProductScreen(
                  productId: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/vendor/orders/:id',
              builder: (_, state) => VendorOrderDetailScreen(
                  orderId: int.parse(state.pathParameters['id']!))),
          GoRoute(
              path: '/vendor/ads',
              builder: (_, __) => const VendorAdsScreen()),
          GoRoute(
              path: '/vendor/analytics',
              builder: (_, __) => const VendorAnalyticsScreen()),
          GoRoute(
              path: '/search',
              builder: (_, __) => const SearchScreen()),
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const BuyerDashboardScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: '/support',
              builder: (_, __) => const SupportTicketsScreen()),
          GoRoute(
              path: '/support/new',
              builder: (_, __) => const CreateTicketScreen()),
          GoRoute(
              path: '/support/:id',
              builder: (_, state) => TicketChatScreen(
                  ticketId: int.parse(state.pathParameters['id']!))),
        ],
      ),
    ],
  );
}
