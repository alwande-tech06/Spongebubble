import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      body: Row(children: [
        if (wide)
          Container(
            width: 560,
            color: SbColors.navy,
            padding: const EdgeInsets.all(56),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SbLogo(height: 200),
              Text('ADMIN PORTAL', style: TextStyle(color: SbColors.sideText, fontWeight: FontWeight.w600, letterSpacing: 3.6)),
              Spacer(),
              Text('Run every booking, washer and rand from one place.',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, height: 1.3)),
              SizedBox(height: 14),
              Text('Approve providers, watch allocation live, settle payouts and resolve disputes.',
                  style: TextStyle(color: SbColors.sideText, fontSize: 15, height: 1.5)),
              Spacer(),
              Text('Secure access · two-step verification · every action audited', style: TextStyle(color: SbColors.sideText, fontSize: 13)),
            ]),
          ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 440,
              child: SbCard(padding: const EdgeInsets.all(36), child: child),
            ),
          ),
        ),
      ]),
    );
  }
}

class AdminSignInScreen extends StatelessWidget {
  const AdminSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
        const Text('Sign in to the SpongeBubble admin portal.'),
        const SizedBox(height: 20),
        TextFormField(initialValue: 'qiniso@spongebubble.co.za', decoration: const InputDecoration(labelText: 'Work email')),
        const SizedBox(height: 14),
        TextFormField(initialValue: 'password', obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => context.go('/verify'), child: const Text('Sign in')),
        const SizedBox(height: 10),
        const Text('You will confirm with a 6-digit code next. Five wrong passwords lock the account.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}

class AdminVerifyScreen extends ConsumerWidget {
  const AdminVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthLayout(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Two-step verification', style: Theme.of(context).textTheme.headlineSmall),
        const Text('Enter the 6-digit code from your authenticator app. Any code works in the prototype.'),
        const SizedBox(height: 20),
        const TextField(
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 10),
          decoration: InputDecoration(counterText: ''),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            ref.read(adminSignedInProvider.notifier).state = true;
            context.go('/dashboard');
          },
          child: const Text('Verify and continue'),
        ),
        TextButton(onPressed: () => context.go('/signin'), child: const Text('Back to sign in')),
      ]),
    );
  }
}
