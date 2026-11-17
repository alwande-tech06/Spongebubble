import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/home.dart';
import 'screens/job.dart';
import 'screens/onboarding.dart';
import 'state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final stage = ref.read(accountProvider);
  final start = switch (stage) {
    AccountStage.signedOut => '/welcome',
    AccountStage.onboarding => '/onboarding',
    AccountStage.inReview => '/review',
    AccountStage.approved => '/home',
  };
  return GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const PartnerWelcomeScreen()),
      GoRoute(path: '/phone', builder: (c, s) => const PhoneSignInScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/review', builder: (c, s) => const InReviewScreen()),
      GoRoute(path: '/home', builder: (c, s) => const PartnerShell()),
      GoRoute(path: '/job', builder: (c, s) => const JobScreen()),
    ],
    errorBuilder: (c, s) => Scaffold(body: Center(child: Text('Page not found: ${s.uri}'))),
  );
});
