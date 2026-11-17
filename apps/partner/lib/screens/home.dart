import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class PartnerShell extends ConsumerStatefulWidget {
  const PartnerShell({super.key});

  @override
  ConsumerState<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<PartnerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Show a job offer as soon as one arrives.
    ref.listen<Booking?>(offerProvider, (prev, next) {
      if (next != null && prev == null) {
        showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          builder: (c) => OfferSheet(offer: next),
        );
      }
    });
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [HomeTab(), JobsTab(), EarningsTab(), ScheduleTab(), ProfileTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class OfferSheet extends ConsumerStatefulWidget {
  const OfferSheet({super.key, required this.offer});

  final Booking offer;

  @override
  ConsumerState<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<OfferSheet> {
  static const _window = 60; // seconds to respond (admin setting)
  int _left = _window;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        _decline();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _close() {
    _t?.cancel();
    ref.read(offerProvider.notifier).state = null;
    Navigator.of(context).pop();
  }

  void _decline() => _close();

  void _accept() {
    final b = widget.offer;
    ref.read(jobsProvider.notifier).add(b);
    ref.read(activeJobProvider.notifier).start(b);
    final router = GoRouter.of(context);
    _close();
    router.push('/job');
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.offer;
    final earn = Pricing.providerEarnings(b.quote);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NEW JOB OFFER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .7, color: SbColors.aquaDark)),
                Text('${b.service.label} · ${rand(b.quote.servicePrice)}', style: Theme.of(context).textTheme.headlineSmall),
              ]),
            ),
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: _left / _window, strokeWidth: 6, color: SbColors.yellow, backgroundColor: SbColors.grey),
                Text('0:${_left.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          SbCard(
            color: SbColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              KeyValue('Vehicle', '${b.vehicle.name} · ${b.vehicle.category.label}'),
              KeyValue('When', b.isImmediate ? 'Now · immediate booking' : when(b.scheduledAt)),
              KeyValue('Area', '${b.address.label} (exact address after you accept)'),
              KeyValue('Distance', '${b.quote.distanceKm} km'),
              const KeyValue('Resources', 'Customer allows water & power'),
              KeyValue('You earn', '${rand(earn)} after commission', valueColor: SbColors.green),
            ]),
          ),
          const SizedBox(height: 12),
          const Note('Customer note: “Car is in visitor bay 2. Please ring the bell at the gate.”', tone: SbTone.warning, icon: Icons.chat_bubble_outline),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: SbColors.red),
                onPressed: _decline,
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: FilledButton.icon(onPressed: _accept, icon: const Icon(Icons.check_circle_outline), label: const Text('Accept job'))),
          ]),
        ]),
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final online = ref.watch(onlineProvider);
    final jobs = ref.watch(jobsProvider);
    final active = ref.watch(activeJobProvider);
    final earnings = ref.watch(earningsProvider);
    return ListView(padding: EdgeInsets.zero, children: [
      Container(
        color: SbColors.navy,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SbLogo(variant: SbLogoVariant.mark, height: 46),
            const Spacer(),
            Avatar(me.initials, background: SbColors.yellow, foreground: SbColors.ink),
          ]),
          const SizedBox(height: 14),
          Text('Sawubona, ${me.name.split(' ').first}', style: const TextStyle(color: SbColors.sideText)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: SbColors.navy2, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(online ? 'You’re online' : 'You’re offline', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(online ? 'Receiving job offers within 15 km' : 'Go online to receive job offers',
                      style: const TextStyle(color: SbColors.sideText, fontSize: 12.5)),
                ]),
              ),
              Switch(value: online, activeColor: Colors.white, activeTrackColor: SbColors.green, onChanged: (v) => ref.read(onlineProvider.notifier).toggle(v)),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (active != null) ...[
            SbCard(
              highlighted: true,
              onTap: () => context.push('/job'),
              child: Row(children: [
                const Icon(Icons.local_car_wash, color: SbColors.aquaDark),
                const SizedBox(width: 12),
                Expanded(child: Text('Job in progress · ${active.stage.title}', style: const TextStyle(fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Row(children: [
            for (final (label, value, sub) in [
              ('This week', rand(earnings), 'Payout Fri'),
              ('Jobs today', '${jobs.length}', 'scheduled'),
              ('Rating', '${me.rating} ★', '${me.reviews} reviews'),
            ]) ...[
              if (label != 'This week') const SizedBox(width: 10),
              Expanded(
                child: SbCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(sub, style: const TextStyle(fontSize: 11.5, color: SbColors.ink3)),
                  ]),
                ),
              ),
            ],
          ]),
          const SectionLabel('Next jobs'),
          for (final j in jobs.take(3)) ...[JobTile(job: j), const SizedBox(height: 8)],
          if (!online) const Note('Go online to receive new offers. For the demo, an offer arrives about 4 seconds after you go online.'),
        ]),
      ),
    ]);
  }
}

class JobTile extends ConsumerWidget {
  const JobTile({super.key, required this.job});

  final Booking job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = job;
    return SbCard(
      onTap: () {
        if (ref.read(activeJobProvider) == null) ref.read(activeJobProvider.notifier).start(j);
        context.push('/job');
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: SbColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.directions_car, color: SbColors.yellowInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${j.service.label} · ${j.vehicle.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${j.ref} · ${j.vehicle.category.label} · ${j.address.label} · ${when(j.scheduledAt)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        Text(rand(j.quote.balance), style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class JobsTab extends ConsumerWidget {
  const JobsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My jobs')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        for (final j in jobs) ...[JobTile(job: j), const SizedBox(height: 8)],
        if (jobs.isEmpty) const Text('No upcoming jobs. Go online to receive offers.'),
      ]),
    );
  }
}

class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(earningsProvider);
    const days = [('Mon', 420), ('Tue', 650), ('Wed', 0), ('Thu', 380), ('Fri', 790), ('Sat', 1000), ('Sun', 780)];
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SbCard(
          color: SbColors.navy,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Net earnings this week', style: TextStyle(color: SbColors.sideText)),
            Text(rand(total), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final (d, v) in days)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        height: (v / 1000 * 80).clamp(2, 80).toDouble(),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: d == 'Sun' ? SbColors.yellow : SbColors.aqua, borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 6),
                      Text(d, style: const TextStyle(color: SbColors.sideText, fontSize: 11)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            const KeyValue('Gross service revenue', 'R3 860'),
            const KeyValue('Travel fees (yours in full)', 'R420'),
            KeyValue('Commission (${(Pricing.commissionRate * 100).round()}%)', '−R772'),
            const KeyValue('Tips', 'R105'),
            const Divider(),
            const KeyValue('Card · paid out Friday', 'R1 960'),
            const KeyValue('Cash · already collected', 'R1 280'),
          ]),
        ),
        const SectionLabel('Payouts'),
        for (final (week, amount, status, tone) in const [
          ('Week 46 · pays Fri 20 Nov', 'R1 960', 'Pending', SbTone.info),
          ('Week 45 · paid 13 Nov', 'R2 480', 'Paid', SbTone.success),
          ('Week 44 · paid 6 Nov', 'R1 630', 'Paid', SbTone.success),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SbCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Icon(Icons.account_balance_outlined, color: SbColors.ink2),
                const SizedBox(width: 12),
                Expanded(child: Text(week, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                StatusBadge(status, tone: tone),
              ]),
            ),
          ),
      ]),
    );
  }
}

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final _on = {'Mon': true, 'Tue': true, 'Wed': false, 'Thu': true, 'Fri': true, 'Sat': true, 'Sun': true};
  bool _immediate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SbCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            value: _immediate,
            onChanged: (v) => setState(() => _immediate = v),
            title: const Text('Accept immediate bookings', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Offers for “wash me now” while online'),
          ),
        ),
        const SectionLabel('Working hours'),
        SbCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final d in _on.keys)
              SwitchListTile(
                value: _on[d]!,
                onChanged: (v) => setState(() => _on[d] = v),
                title: Text(d, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_on[d]! ? (d == 'Sat' ? '07:00–15:00' : '08:00–17:00') : 'Off'),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Block dates or pause')),
      ]),
    );
  }
}

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SbCard(
          child: Row(children: [
            Avatar(me.initials, size: 60, background: SbColors.yellow, foreground: SbColors.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me.name, style: Theme.of(context).textTheme.titleMedium),
                Text('Individual provider · ${me.areas.first}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                const StatusBadge('Verified', tone: SbTone.success, icon: Icons.verified),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SbCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final (icon, title, sub) in [
              (Icons.auto_awesome_outlined, 'Services & vehicle sizes', 'Full Wash, External · Small, Medium'),
              (Icons.place_outlined, 'Service area', '15 km from Kloof · ${me.areas.length} areas'),
              (Icons.account_balance_outlined, 'Bank account', 'Capitec ••93 · verified'),
              (Icons.description_outlined, 'Documents', 'All approved'),
              (Icons.workspace_premium_outlined, 'Plan', 'Commission ${(Pricing.commissionRate * 100).round()}%'),
              (Icons.report_outlined, 'Report an incident', 'Damage, theft, safety'),
            ])
              ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          ]),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            await ref.read(accountProvider.notifier).set(AccountStage.signedOut);
            if (context.mounted) context.go('/welcome');
          },
          icon: const Icon(Icons.logout, color: SbColors.red),
          label: const Text('Sign out (resets the demo)', style: TextStyle(color: SbColors.red)),
        ),
      ]),
    );
  }
}
