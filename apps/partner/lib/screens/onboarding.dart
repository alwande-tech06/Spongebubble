import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class PartnerWelcomeScreen extends StatelessWidget {
  const PartnerWelcomeScreen({super.key});

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
              const SbLogo(height: 180),
              const Text('PARTNER APP', style: TextStyle(color: SbColors.sideText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3.6)),
              const SizedBox(height: 36),
              const Text('Get booked for washes\nnear you. Get paid weekly.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 10),
              const Text('For independent washers and car wash businesses in Durban & surrounds.',
                  textAlign: TextAlign.center, style: TextStyle(color: SbColors.sideText, height: 1.5)),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SbColors.yellow, foregroundColor: SbColors.ink),
                onPressed: () => context.push('/phone'),
                child: const Text('Become a provider'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SbColors.navy2),
                onPressed: () => context.push('/phone'),
                child: const Text('I already have an account'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  bool _sent = false;
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Enter your phone number', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('We’ll send a 6-digit code by SMS. You stay signed in on this phone.'),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: '72 418 9930',
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+27 '),
          ),
          const SizedBox(height: 16),
          if (_sent) ...[
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 10),
              decoration: const InputDecoration(labelText: 'SMS code (any 6 digits)', counterText: ''),
              onChanged: (v) => setState(() => _code = v),
            ),
            const SizedBox(height: 8),
            const Note('Five wrong codes lock sign-in for 15 minutes.', icon: Icons.shield_outlined),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: !_sent
                ? () => setState(() => _sent = true)
                : _code.length == 6
                    ? () async {
                        await ref.read(accountProvider.notifier).set(AccountStage.onboarding);
                        if (context.mounted) context.go('/onboarding');
                      }
                    : null,
            child: Text(_sent ? 'Continue' : 'Send code'),
          ),
        ]),
      ),
    );
  }
}

/// The 7 onboarding steps from the blueprint, in one screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  ProviderType _type = ProviderType.individual;
  final Set<ServiceType> _services = {ServiceType.fullWash, ServiceType.external};
  final Set<VehicleCategory> _sizes = {VehicleCategory.small, VehicleCategory.medium};
  final Set<String> _equipment = {'Pressure washer', 'Vacuum', 'Shampoo & chemicals'};
  final Set<String> _docs = {'Copy of SA ID', 'Selfie holding your ID'};
  double _km = 15;
  ProviderPlan _plan = ProviderPlan.commission;
  bool _agree = false;

  static const _titles = ['How will you work?', 'Personal details', 'Verification documents', 'What you offer', 'Equipment', 'Where you work', 'Payout & plan'];
  static const _requiredDocs = ['Copy of SA ID', 'Selfie holding your ID', 'Proof of address', 'Bank confirmation letter'];

  bool get _canContinue => switch (_step) {
        2 => _requiredDocs.every(_docs.contains),
        3 => _services.isNotEmpty && _sizes.isNotEmpty,
        6 => _agree,
        _ => true,
      };

  Widget _content() {
    switch (_step) {
      case 0:
        return Column(children: [
          for (final (t, title, sub) in const [
            (ProviderType.individual, 'Individual provider', 'You do the washes yourself and get paid to your own bank account.'),
            (ProviderType.business, 'Registered business', 'You have staff and teams. Each washer gets their own login.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SbCard(
                highlighted: _type == t,
                onTap: () => setState(() => _type = t),
                child: Row(children: [
                  Icon(t == ProviderType.individual ? Icons.person_outline : Icons.business_outlined, color: SbColors.aquaDark, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(sub, style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                ]),
              ),
            ),
        ]);
      case 1:
        return Column(children: [
          for (final (label, value) in [
            ('Full name', 'Lwazi Dlamini'),
            (_type == ProviderType.individual ? 'SA ID number' : 'CIPC registration number', _type == ProviderType.individual ? '9203 1456 0870 84' : '2019/123456/07'),
            ('Email', 'lwazi.dlamini@gmail.com'),
            ('Home or business address', '22 Old Main Rd, Kloof, 3610'),
          ]) ...[
            TextFormField(initialValue: value, decoration: InputDecoration(labelText: label)),
            const SizedBox(height: 14),
          ],
        ]);
      case 2:
        return Column(children: [
          const Text('Clear photos or PDFs. An administrator checks them before you can receive jobs.'),
          const SizedBox(height: 12),
          for (final d in [..._requiredDocs, 'Police clearance (optional)'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SbCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.description_outlined, color: SbColors.ink2),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600))),
                  _docs.contains(d)
                      ? const StatusBadge('Uploaded', tone: SbTone.success, icon: Icons.check)
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                          onPressed: () => setState(() => _docs.add(d)),
                          child: const Text('Upload'),
                        ),
                ]),
              ),
            ),
          const Note('Your documents are encrypted and only seen by verification staff.', icon: Icons.lock_outline),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('Services'),
          for (final s in ServiceType.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _services.contains(s),
              onChanged: (v) => setState(() => v! ? _services.add(s) : _services.remove(s)),
              title: Text(s.label),
              subtitle: Text(s.description),
            ),
          const SectionLabel('Vehicle sizes'),
          Wrap(spacing: 8, children: [
            for (final c in VehicleCategory.values)
              FilterChip(
                selected: _sizes.contains(c),
                label: Text(c.label),
                onSelected: (v) => setState(() => v ? _sizes.add(c) : _sizes.remove(c)),
              ),
          ]),
        ]);
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in ['Pressure washer', 'Vacuum', '500 L water tank', 'Generator', 'Shampoo & chemicals', 'Microfibre cloths'])
              FilterChip(selected: _equipment.contains(e), label: Text(e), onSelected: (v) => setState(() => v ? _equipment.add(e) : _equipment.remove(e))),
          ]),
          const SizedBox(height: 16),
          const Note('If you need the customer’s water or electricity, the app asks them first. You confirm on arrival.', tone: SbTone.warning),
        ]);
      case 5:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MapPlaceholder(height: 200, label: 'Base: Kloof'),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Maximum travel distance', style: TextStyle(fontWeight: FontWeight.w700))),
            Text('${_km.round()} km', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SbColors.aquaDark)),
          ]),
          Slider(value: _km, min: 5, max: 30, divisions: 25, onChanged: (v) => setState(() => _km = v)),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(initialValue: 'Capitec Bank', decoration: const InputDecoration(labelText: 'Bank')),
          const SizedBox(height: 14),
          TextFormField(initialValue: '1520 4471 93', decoration: const InputDecoration(labelText: 'Account number')),
          const SectionLabel('How you pay SpongeBubble'),
          for (final (p, title, sub) in [
            (ProviderPlan.commission, 'Commission · ${(Pricing.commissionRate * 100).round()}%', 'Only pay when you work · no monthly fee'),
            (ProviderPlan.subscription, 'Subscription · ${rand(Pricing.subscriptionPerWeek)}/week', 'Keep 100% of the job value'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SbCard(
                highlighted: _plan == p,
                onTap: () => setState(() => _plan = p),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(sub, style: const TextStyle(fontSize: 12.5)),
                    ]),
                  ),
                  if (_plan == p) const Icon(Icons.check_circle, color: SbColors.aquaDark),
                ]),
              ),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            title: const Text('I accept the Independent Service Provider Agreement and Privacy Notice.', style: TextStyle(fontSize: 13)),
          ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _titles.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_step]),
        leading: _step == 0 ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--)),
        actions: [Padding(padding: const EdgeInsets.only(right: 20), child: Center(child: Text('${_step + 1} of ${_titles.length}')))],
      ),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          StepDots(step: _step + 1, total: _titles.length),
          const SizedBox(height: 18),
          _content(),
        ]),
      ),
      bottomNavigationBar: ResponsiveBody(
        child: BottomAction(children: [
          FilledButton(
            onPressed: !_canContinue
                ? null
                : () async {
                    if (!last) {
                      setState(() => _step++);
                      return;
                    }
                    await ref.read(accountProvider.notifier).set(AccountStage.inReview);
                    if (context.mounted) context.go('/review');
                  },
            child: Text(last ? 'Submit for review' : (_canContinue ? 'Continue' : 'Complete this step')),
          ),
        ]),
      ),
    );
  }
}

class InReviewScreen extends ConsumerWidget {
  const InReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const steps = [
      ('Profile and documents', 'Submitted', true),
      ('Document check', 'In progress · Provider Administrator', false),
      ('Bank account verification', 'Waiting', false),
      ('Approved: go online', 'You can start receiving jobs', false),
    ];
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 20),
            const Icon(Icons.schedule, size: 64, color: SbColors.yellowInk),
            const SizedBox(height: 10),
            Text('Application submitted', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const Text('We usually review applications within 2 working days. We’ll notify you by SMS and in the app.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SbCard(
              child: Column(children: [
                for (final (title, sub, done) in steps)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? SbColors.green : SbColors.ink3),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sub),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            const Note('Prototype: tap below to simulate an administrator approving your application.', tone: SbTone.warning),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await ref.read(accountProvider.notifier).set(AccountStage.approved);
                if (context.mounted) context.go('/home');
              },
              child: const Text('Simulate approval'),
            ),
          ]),
        ),
      ),
    );
  }
}
