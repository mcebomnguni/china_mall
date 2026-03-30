// ─────────────────────────────────────────────────────────────────────────────
//  router.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/app_models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_flow_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_screens.dart';
import 'screens/client/client_dashboard.dart';
import 'screens/client/product_first_screen.dart';
import 'screens/client/insurance_bonds_screen.dart';
import 'screens/client/insurance_bonds_documents_screen.dart';
import 'screens/client/financial_advisory_screen.dart';
import 'screens/client/general_insurance_screen.dart';
import 'screens/client/onboarding_documents_screen.dart';
import 'screens/legal_screens.dart';
import 'screens/client/product_selection_screen.dart';
import 'screens/client/application_detail_screen.dart';
import 'screens/client/profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_document_review_screen.dart';
import 'screens/client/resubmit_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'services/auth_service.dart';

GoRouter buildRouter(AuthService auth) => GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final going    = state.matchedLocation;

    // Public routes
    final publicRoutes = [
      '/login', '/register', '/forgot-password',
      '/forgot-username', '/privacy-policy',
    ];
    if (!loggedIn && !publicRoutes.any((r) => going.startsWith(r))) {
      return '/login';
    }
    if (loggedIn && going == '/login') {
      return auth.isAdmin ? '/admin' : '/dashboard';
    }
    return null;
  },
  routes: [
    // ── Auth
    GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register',        builder: (_, __) => const RegistrationFlowScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/forgot-username', builder: (_, __) => const ForgotUsernameScreen()),

    // ── Legal Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/terms',
      name: 'Terms and Conditions',
      builder: (_, __) => const TermsAndConditionsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'Privacy Policy',
      builder: (_, __) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'About',
      builder: (_, __) => const AboutScreen(),
    ),
    GoRoute(
      path: '/locations',
      name: 'Locations',
      builder: (_, __) => const LocationsScreen(),
    ),
    GoRoute(
      path: '/sources',
      name: 'Sources & Licenses',
      builder: (_, __) => const SourcesAndLicensesScreen(),
    ),

    // ── New application (product first flow)
    GoRoute(
      path: '/apply',
      builder: (_, __) => const ProductFirstScreen(),
    ),
    GoRoute(
      path: '/onboarding/documents',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final category = extra['category'] as ProductCategory?;
        final item = extra['item'] as ProductItem?;
        return OnboardingDocumentsScreen(
          preselectedCategory: category,
          preselectedItem: item,
        );
      },
    ),

    // ── Client dashboard
    GoRoute(path: '/dashboard', builder: (_, __) => const ClientDashboard()),

    // ── Application detail
    GoRoute(
      path: '/application/:id',
      builder: (_, state) =>
          ApplicationDetailScreen(applicationId: state.pathParameters['id']!),
    ),

    // ── Profile
    GoRoute(path: '/profile',         builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),

    // ── Client
    GoRoute(path: '/dashboard',       builder: (_, __) => const ClientDashboard()),
    GoRoute(path: '/products',        builder: (_, __) => const ProductFirstScreen()),
    GoRoute(path: '/insurance-bonds', builder: (_, __) => const InsuranceBondsScreen()),
    GoRoute(path: '/insurance-bonds/documents', builder: (_, __) => const InsuranceBondsDocumentsScreen()),
    GoRoute(path: '/financial-advisory', builder: (_, __) => const FinancialAdvisoryScreen()),
    GoRoute(path: '/general-insurance', builder: (_, __) => const GeneralInsuranceScreen()),
    GoRoute(path: '/onboarding/documents', builder: (_, __) => const OnboardingDocumentsScreen()),

    // ── Admin
    GoRoute(path: '/admin',       builder: (_, __) => const AdminDashboard()),
    GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
    GoRoute(path: '/admin/document-review', builder: (_, __) => const AdminDocumentReviewScreen()),

    // ── Resubmit returned application
    GoRoute(
      path: '/resubmit/:id',
      builder: (_, state) =>
          ResubmitScreen(applicationId: state.pathParameters['id']!),
    ),

    // ── Privacy
    GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
  ],
);
