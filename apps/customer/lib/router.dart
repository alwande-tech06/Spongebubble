import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/account.dart';
import 'screens/auth.dart';
import 'screens/booking_flow.dart';
import 'screens/bookings.dart';
import 'screens/home_shell.dart';
import 'screens/live_booking.dart';
import 'screens/vehicles.dart';
import 'state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Read once: signing in or out navigates explicitly.
  final signedIn = ref.read(sessionProvider);
  return GoRouter(
    initialLocation: signedIn ? '/home' : '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignUpScreen()),
      GoRoute(path: '/otp', builder: (c, s) => const OtpScreen()),
      GoRoute(path: '/signin', builder: (c, s) => const SignInScreen()),
      GoRoute(
        path: '/home',
        builder: (c, s) => HomeShell(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0),
      ),
      GoRoute(path: '/vehicles/add', builder: (c, s) => const AddVehicleScreen()),
      GoRoute(path: '/book/service', builder: (c, s) => BookServiceScreen(scheduleFirst: s.uri.queryParameters['schedule'] == '1')),
      GoRoute(path: '/book/when', builder: (c, s) => BookWhenScreen(scheduleFirst: s.uri.queryParameters['schedule'] == '1')),
      GoRoute(path: '/book/where', builder: (c, s) => const BookWhereScreen()),
      GoRoute(path: '/book/review', builder: (c, s) => const BookReviewScreen()),
      GoRoute(path: '/booking/:ref', builder: (c, s) => LiveBookingScreen(bookingRef: s.pathParameters['ref']!)),
      GoRoute(path: '/booking/:ref/chat', builder: (c, s) => ChatScreen(bookingRef: s.pathParameters['ref']!)),
      GoRoute(path: '/receipt/:ref', builder: (c, s) => ReceiptScreen(bookingRef: s.pathParameters['ref']!)),
      GoRoute(path: '/report/:ref', builder: (c, s) => ReportProblemScreen(bookingRef: s.pathParameters['ref']!)),
    ],
    errorBuilder: (c, s) => Scaffold(body: Center(child: Text('Page not found: ${s.uri}'))),
  );
});
