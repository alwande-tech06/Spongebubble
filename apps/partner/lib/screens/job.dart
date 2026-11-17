import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

/// The service workflow from the blueprint, one stage at a time:
/// accept → travel → arrive & before photos → confirm service and
/// resources → checklist → after photos → collect payment → done.
class JobScreen extends ConsumerWidget {
  const JobScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(activeJobProvider);
    if (job == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No active job'),
            TextButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
          ]),
        ),
      );
    }
    final n = ref.read(activeJobProvider.notifier);
    final b = job.booking;
    final stage = job.stage;
    final total = JobStage.values.length - 1;

    final (Widget body, Widget action) = switch (stage) {
      JobStage.accepted => (
          _Details(b: b),
          FilledButton.icon(onPressed: n.next, icon: const Icon(Icons.navigation_outlined), label: const Text('Start travelling')),
        ),
      JobStage.travelling => (
          Column(children: [
            const MapPlaceholder(height: 300, label: 'Navigation · 7 min · 2.2 km', showRoute: true),
            const SizedBox(height: 12),
            Note('Customer can see your live location. If you’re more than ${Pricing.lateAfter.inMinutes} min late, they can cancel for free.',
                icon: Icons.location_on_outlined),
          ]),
          FilledButton.icon(onPressed: n.next, icon: const Icon(Icons.where_to_vote_outlined), label: const Text('I’ve arrived')),
        ),
      JobStage.beforePhotos => (
          _Photos(
            title: 'Inspect the vehicle',
            sub: 'Take photos of every side. They protect you and the customer.',
            taken: job.beforePhotos,
            onTake: (s) => n.update((j) => j.copyWith(beforePhotos: {...j.beforePhotos, s})),
            extra: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: job.damageNoted,
              onChanged: (v) => n.update((j) => j.copyWith(damageNoted: v)),
              title: const Text('Existing damage found'),
              subtitle: const Text('Photograph it; the customer is notified'),
            ),
          ),
          FilledButton(
            onPressed: job.beforePhotos.length == ActiveJob.sides.length ? n.next : null,
            child: Text(job.beforePhotos.length == ActiveJob.sides.length
                ? 'Continue'
                : 'Continue (${ActiveJob.sides.length - job.beforePhotos.length} photos left)'),
          ),
        ),
      JobStage.confirm => (
          _Confirm(b: b),
          FilledButton.icon(onPressed: n.next, icon: const Icon(Icons.auto_awesome), label: const Text('Start service')),
        ),
      JobStage.checklist => (
          _Checklist(job: job, onToggle: (i) {
            final s = {...job.checklist};
            s.contains(i) ? s.remove(i) : s.add(i);
            n.update((j) => j.copyWith(checklist: s));
          }),
          FilledButton(
            onPressed: job.checklist.length == b.service.checklist.length ? n.next : null,
            child: Text(job.checklist.length == b.service.checklist.length ? 'Continue to after photos' : 'Finish checklist first'),
          ),
        ),
      JobStage.afterPhotos => (
          _Photos(
            title: 'Show the finished work',
            sub: 'The customer sees these before they approve the job.',
            taken: job.afterPhotos,
            onTake: (s) => n.update((j) => j.copyWith(afterPhotos: {...j.afterPhotos, s})),
          ),
          FilledButton.icon(
            onPressed: job.afterPhotos.length == ActiveJob.sides.length ? n.next : null,
            icon: const Icon(Icons.send),
            label: const Text('Submit completion'),
          ),
        ),
      JobStage.payment => (
          _Payment(job: job, onMethod: (m) => n.update((j) => j.copyWith(method: m))),
          FilledButton.icon(
            onPressed: n.next,
            icon: const Icon(Icons.payments_outlined),
            label: Text(job.method == PaymentMethod.cash ? 'Confirm ${rand(b.quote.balance)} cash received' : 'Customer paid by card'),
          ),
        ),
      JobStage.done => (
          _Done(b: b),
          FilledButton(
            onPressed: () {
              n.finish();
              context.go('/home');
            },
            child: const Text('Back to home'),
          ),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(stage.title),
        actions: [
          if (stage != JobStage.done)
            Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: StatusBadge('Step ${stage.index + 1} of $total'))),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          if (stage != JobStage.done) ...[
            SbCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text('${b.ref} · ${b.service.label} · ${b.vehicle.name} (${b.vehicle.category.label}) · ${b.address.label}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
          ],
          body,
        ]),
      ),
      bottomNavigationBar: ResponsiveBody(child: BottomAction(children: [action])),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) => Column(children: [
        SbCard(
          child: Row(children: [
            Avatar(b.customer.initials, size: 48),
            const SizedBox(width: 12),
            Expanded(child: Text(b.customer.name, style: Theme.of(context).textTheme.titleMedium)),
            IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
            const SizedBox(width: 6),
            IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
          ]),
        ),
        const SizedBox(height: 12),
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            KeyValue('Service', b.service.label),
            KeyValue('Vehicle', '${b.vehicle.name} · ${b.vehicle.registration}'),
            KeyValue('Size', b.vehicle.category.label),
            KeyValue('Address', b.address.line),
            KeyValue('Water & power', b.waterAllowed && b.powerAllowed ? 'Customer’s, permission given' : 'Bring your own'),
          ]),
        ),
        const SizedBox(height: 12),
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            KeyValue('Service price', rand(b.quote.servicePrice)),
            KeyValue('Travel fee', rand(b.quote.travelFee)),
            const KeyValue('Booking fee', 'Paid in app'),
            const Divider(),
            KeyValue('Customer pays you', '${rand(b.quote.balance)} · card or cash', strong: true),
          ]),
        ),
      ]);
}

class _Photos extends StatelessWidget {
  const _Photos({required this.title, required this.sub, required this.taken, required this.onTake, this.extra});

  final String title;
  final String sub;
  final Set<String> taken;
  final ValueChanged<String> onTake;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(sub),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final s in ActiveJob.sides)
              PhotoSlot(label: s, sub: taken.contains(s) ? 'Taken' : 'Tap to take', taken: taken.contains(s), onTap: () => onTake(s)),
          ],
        ),
        if (extra != null) extra!,
      ]);
}

class _Confirm extends StatelessWidget {
  const _Confirm({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Is this what was booked?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            KeyValue('Service', b.service.label),
            KeyValue('Vehicle', b.vehicle.name),
            KeyValue('Size category', b.vehicle.category.label),
            TextButton(onPressed: () {}, child: const Text('Size is wrong? Ask the customer to approve a change')),
          ]),
        ),
        const SizedBox(height: 12),
        SbCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Water & electricity', style: Theme.of(context).textTheme.titleMedium),
            KeyValue('Customer’s water', b.waterAllowed ? 'Allowed' : 'Not allowed', valueColor: b.waterAllowed ? SbColors.green : SbColors.red),
            KeyValue('Customer’s electricity', b.powerAllowed ? 'Allowed' : 'Not allowed', valueColor: b.powerAllowed ? SbColors.green : SbColors.red),
          ]),
        ),
        const SizedBox(height: 12),
        const Note('Can’t do the service (no water, unsafe location)? Report it: the customer gets a full booking-fee refund.', tone: SbTone.warning),
      ]);
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.job, required this.onToggle});

  final ActiveJob job;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final items = job.booking.service.checklist;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${job.checklist.length} of ${items.length} done', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: job.checklist.length / items.length, minHeight: 8, borderRadius: BorderRadius.circular(4)),
      const SizedBox(height: 12),
      SbCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < items.length; i++)
            CheckboxListTile(value: job.checklist.contains(i), onChanged: (_) => onToggle(i), title: Text(items[i])),
        ]),
      ),
    ]);
  }
}

class _Payment extends StatelessWidget {
  const _Payment({required this.job, required this.onMethod});

  final ActiveJob job;
  final ValueChanged<PaymentMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final b = job.booking;
    final cardOnly = Pricing.cardRequired(b.quote.balance);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SbCard(
        color: SbColors.navy,
        child: Column(children: [
          const Text('Balance due from customer', style: TextStyle(color: SbColors.sideText)),
          Text(rand(b.quote.balance), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
          Text('${b.service.label} ${rand(b.quote.servicePrice)} + travel ${rand(b.quote.travelFee)} · booking fee already paid',
              textAlign: TextAlign.center, style: const TextStyle(color: SbColors.sideText, fontSize: 12.5)),
        ]),
      ),
      const SizedBox(height: 12),
      const StatusBadge('Customer approved the work', tone: SbTone.success, icon: Icons.check_circle),
      const SectionLabel('How did the customer pay?'),
      for (final m in PaymentMethod.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SbCard(
            highlighted: job.method == m,
            onTap: cardOnly && m == PaymentMethod.cash ? null : () => onMethod(m),
            child: Row(children: [
              Icon(m == PaymentMethod.card ? Icons.credit_card : Icons.payments_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  m == PaymentMethod.card
                      ? 'Card in the app · goes to your weekly payout'
                      : 'Cash · you keep it; ${rand((b.quote.servicePrice * Pricing.commissionRate).round())} commission goes on your statement',
                ),
              ),
            ]),
          ),
        ),
      Note('Balances of ${rand(Pricing.cardOnlyFrom)} or more must be paid by card in the app.', tone: SbTone.warning),
    ]);
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final commission = (b.quote.servicePrice * Pricing.commissionRate).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      const Icon(Icons.check_circle, color: SbColors.green, size: 80),
      Text('Job complete!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      Text('${b.ref} is closed. Nice work.', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      SbCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: [
          KeyValue('Job value', rand(b.quote.balance)),
          KeyValue('Commission (${(Pricing.commissionRate * 100).round()}% of service)', '−${rand(commission)}'),
          KeyValue('Travel fee', '${rand(b.quote.travelFee)} (yours)'),
          const Divider(),
          KeyValue('You earned', rand(Pricing.providerEarnings(b.quote)), strong: true, valueColor: SbColors.green),
        ]),
      ),
    ]);
  }
}
