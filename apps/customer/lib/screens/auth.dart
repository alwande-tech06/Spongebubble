import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SbColors.navy,
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(children: [
              const Spacer(),
              const SbLogo(height: 190),
              const SizedBox(height: 40),
              const Text('A spotless car,\nwithout leaving home.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 10),
              const Text('Book a wash, and a verified washer comes to you. Track them live and pay in the app.',
                  textAlign: TextAlign.center, style: TextStyle(color: SbColors.sideText, fontSize: 14, height: 1.5)),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SbColors.yellow, foregroundColor: SbColors.ink),
                onPressed: () => context.push('/signup'),
                child: const Text('Create an account'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SbColors.navy2),
                onPressed: () => context.push('/signin'),
                child: const Text('Sign in'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  bool _terms = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveBody(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
            Text('Create your account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('You only do this once. You’ll stay signed in on this phone.'),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: 'Thandeka Mthembu',
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: '082 555 0141',
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+27 ', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v ?? '').replaceAll(' ', '').length < 9 ? 'Enter a valid SA mobile number' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: 'thandeka.m@gmail.com',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: 'password1',
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', helperText: 'At least 8 characters, with a number', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) {
                final s = v ?? '';
                if (s.length < 8 || !s.contains(RegExp(r'\d'))) return 'At least 8 characters, with a number';
                return null;
              },
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _terms,
              onChanged: (v) => setState(() => _terms = v ?? false),
              title: const Text('I agree to the Terms and Privacy Notice (POPIA).', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _terms
                  ? () {
                      if (_form.currentState!.validate()) context.push('/otp');
                    }
                  : null,
              child: const Text('Create account'),
            ),
            TextButton(onPressed: () => context.pushReplacement('/signin'), child: const Text('Already have an account? Sign in')),
          ]),
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Check your SMS', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Enter the 6-digit code we sent to +27 82 555 0141. For this prototype any 6 digits work.'),
          const SizedBox(height: 22),
          TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 12),
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            onChanged: (v) => setState(() => _code = v),
          ),
          const SizedBox(height: 10),
          const Text('Five wrong codes lock sign-in for 15 minutes.', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _code.length == 6
                ? () async {
                    await ref.read(sessionProvider.notifier).signIn();
                    if (context.mounted) context.go('/home');
                  }
                : null,
            child: const Text('Verify'),
          ),
        ]),
      ),
    );
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _keep = true;

  void _forgot() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reset link sent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('We emailed thandeka.m@gmail.com a link with a temporary password. It expires in 30 minutes, then you choose a new password.'),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Sign in to book and track your washes.'),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: 'Mobile number or email', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 14),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
          Row(children: [
            Checkbox(value: _keep, onChanged: (v) => setState(() => _keep = v ?? true)),
            const Expanded(child: Text('Keep me signed in')),
            TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
          ]),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await ref.read(sessionProvider.notifier).signIn();
              if (context.mounted) context.go('/home');
            },
            child: const Text('Sign in'),
          ),
          TextButton(onPressed: () => context.pushReplacement('/signup'), child: const Text('New here? Create an account')),
        ]),
      ),
    );
  }
}
