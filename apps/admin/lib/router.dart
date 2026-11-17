import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth.dart';
import 'screens/pages.dart';
import 'screens/shell.dart';
import 'state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final signedIn = ref.read(adminSignedInProvider);
      final authPage = state.matchedLocation == '/signin' || state.matchedLocation == '/verify';
      if (!signedIn && !authPage) return '/signin';
      return null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (c, s) => const AdminSignInScreen()),
      GoRoute(path: '/verify', builder: (c, s) => const AdminVerifyScreen()),
      ShellRoute(
        builder: (c, s, child) => AdminShell(path: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
          GoRoute(path: '/bookings', builder: (c, s) => const BookingsPage()),
          GoRoute(path: '/bookings/:ref', builder: (c, s) => BookingDetailPage(bookingRef: s.pathParameters['ref']!)),
          GoRoute(path: '/applications', builder: (c, s) => const ApplicationsPage()),
          GoRoute(path: '/providers', builder: (c, s) => const ProvidersPage()),
          GoRoute(path: '/customers', builder: (c, s) => const CustomersPage()),
          GoRoute(path: '/tickets', builder: (c, s) => const TicketsPage()),
          GoRoute(path: '/pricing', builder: (c, s) => const PricingPage()),
          GoRoute(path: '/soon/:name', builder: (c, s) => ComingSoonPage(name: s.pathParameters['name']!)),
        ],
      ),
    ],
    errorBuilder: (c, s) => Scaffold(body: Center(child: Text('Page not found: ${s.uri}'))),
  );
});
