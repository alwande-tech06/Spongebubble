import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

/// One screen for the whole active booking; the body changes with the
/// booking status (finding → accepted → travelling → washing → approve →
/// pay → rate).
class LiveBookingScreen extends ConsumerWidget {
  const LiveBookingScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(bookingProvider(bookingRef));
    if (b == null) return const Scaffold(body: Center(child: Text('Booking not found')));
    final body = switch (b.status) {
      BookingStatus.pendingPayment || BookingStatus.findingProvider => _Finding(b: b),
      BookingStatus.accepted || BookingStatus.travelling || BookingStatus.arrived => _OnTheWay(b: b),
      BookingStatus.inProgress => _Washing(b: b),
      BookingStatus.awaitingApproval => _Approve(b: b),
      BookingStatus.awaitingPayment => _Pay(b: b),
      BookingStatus.completed => _Done(b: b),
      BookingStatus.cancelled => _Cancelled(b: b),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(b.ref),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: StatusBadge(b.status.label, tone: toneForStatus(b.status))))],
      ),
      body: ResponsiveBody(child: body),
    );
  }
}

Future<void> showCancelSheet(BuildContext context, WidgetRef ref, Booking b) {
  final refund = Pricing.refundAmount(b, now: DateTime.now());
  final share = (Pricing.customerCancelRefundShare(b, now: DateTime.now()) * 100).round();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Cancel this booking?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SbCard(
          color: SbColors.bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            KeyValue('Stage', b.status.label),
            KeyValue('Booking fee paid', rand(b.quote.bookingFee)),
            KeyValue('Refund ($share%)', rand(refund)),
            const KeyValue('Back to', 'Visa •••• 4471, 3–5 days'),
          ]),
        ),
        const SizedBox(height: 12),
        const Note('If your washer is more than 15 minutes late, you get the full booking fee back.', icon: Icons.schedule),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Keep booking'))),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: SbColors.red),
              onPressed: () {
                ref.read(bookingsProvider.notifier).cancel(b.ref, refund);
                Navigator.pop(c);
              },
              child: Text('Cancel · ${rand(refund)} back'),
            ),
          ),
        ]),
      ]),
    ),
  );
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final p = b.provider!;
    return Row(children: [
      Avatar(p.initials, size: 48, background: SbColors.yellow, foreground: SbColors.ink),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p.shortName} · ★ ${p.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(p.vehicle.isEmpty ? '${p.reviews} reviews · verified' : p.vehicle, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      IconButton.outlined(onPressed: () => context.push('/booking/${b.ref}/chat'), icon: const Icon(Icons.chat_bubble_outline)),
      const SizedBox(width: 6),
      IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
    ]);
  }
}

class _Finding extends ConsumerWidget {
  const _Finding({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 20),
      Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: SbColors.aquaSoft),
          child: const Center(child: SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 5))),
        ),
      ),
      const SizedBox(height: 20),
      Text('Finding your washer', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text('Payment received. We’re offering your booking to verified washers nearby.', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      SbCard(
        child: Column(children: [
          KeyValue('Booking fee', '${rand(b.quote.bookingFee)} paid'),
          KeyValue('Service', '${b.service.label} · ${b.vehicle.name}'),
          KeyValue('When', when(b.scheduledAt)),
        ]),
      ),
      const SizedBox(height: 20),
      OutlinedButton(onPressed: () => showCancelSheet(context, ref, b), child: Text('Cancel · full ${rand(b.quote.bookingFee)} refund')),
    ]);
  }
}

class _OnTheWay extends ConsumerWidget {
  const _OnTheWay({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headline = switch (b.status) {
      BookingStatus.accepted => '${b.provider!.shortName} accepted your booking',
      BookingStatus.travelling => '${b.etaMinutes} min away',
      _ => '${b.provider!.shortName} has arrived',
    };
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
      MapPlaceholder(height: 260, label: b.status == BookingStatus.travelling ? 'Live location' : 'Google Maps', showRoute: true),
      const SizedBox(height: 14),
      Text(headline, style: Theme.of(context).textTheme.headlineSmall),
      Text(b.status == BookingStatus.arrived ? 'They’re taking before photos now.' : '${b.address.line} · ${b.service.label}',
          style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      SbCard(child: Milestones(current: b.status.milestone)),
      const SizedBox(height: 12),
      SbCard(child: _ProviderRow(b: b)),
      const SizedBox(height: 12),
      const Note('Chat is open while the booking is active. Your phone number stays private.', icon: Icons.shield_outlined),
      const SizedBox(height: 16),
      if (b.status != BookingStatus.arrived)
        OutlinedButton.icon(
          onPressed: () => showCancelSheet(context, ref, b),
          icon: const Icon(Icons.cancel_outlined, color: SbColors.red),
          label: const Text('Cancel booking'),
        ),
    ]);
  }
}

class _Washing extends StatelessWidget {
  const _Washing({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final total = b.service.checklist.length;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
      SbCard(
        color: SbColors.navy,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About ${b.service.minutes} min', style: const TextStyle(color: SbColors.sideText, fontSize: 13)),
          const Text('Your car is being washed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: b.checklistDone / total, minHeight: 8, color: SbColors.yellow, backgroundColor: SbColors.navy2),
          ),
          const SizedBox(height: 6),
          Text('${b.checklistDone} of $total checklist steps done', style: const TextStyle(color: SbColors.sideText, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 12),
      SbCard(child: Milestones(current: b.status.milestone)),
      const SectionLabel('Before photos'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: const [
          PhotoSlot(label: 'Front'),
          PhotoSlot(label: 'Back'),
          PhotoSlot(label: 'Left'),
          PhotoSlot(label: 'Right'),
          PhotoSlot(label: 'Interior'),
          PhotoSlot(label: 'Damage', sub: 'Bumper scratch', damage: true),
        ],
      ),
      const SizedBox(height: 12),
      const Note('Your washer noted an existing scratch on the rear bumper before starting.', tone: SbTone.warning, icon: Icons.error_outline),
    ]);
  }
}

class _Approve extends ConsumerWidget {
  const _Approve({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
      Text('${b.provider!.shortName} has finished', style: Theme.of(context).textTheme.headlineSmall),
      const Text('Compare the before and after photos, then approve.'),
      const SizedBox(height: 14),
      const Row(children: [
        Expanded(child: PhotoSlot(label: 'Before · front', height: 120)),
        SizedBox(width: 8),
        Expanded(child: PhotoSlot(label: 'After · front', height: 120)),
      ]),
      const SizedBox(height: 8),
      const Row(children: [
        Expanded(child: PhotoSlot(label: 'After · back', height: 70)),
        SizedBox(width: 8),
        Expanded(child: PhotoSlot(label: 'After · interior', height: 70)),
      ]),
      const SizedBox(height: 12),
      const SbCard(child: Text('“Tyre shine applied. Mats left to dry in the boot.”')),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => ref.read(bookingsProvider.notifier).approve(b.ref),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Looks great, approve'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: SbColors.red),
        onPressed: () => context.push('/report/${b.ref}'),
        child: const Text('Something’s not right'),
      ),
    ]);
  }
}

class _Pay extends ConsumerStatefulWidget {
  const _Pay({required this.b});

  final Booking b;

  @override
  ConsumerState<_Pay> createState() => _PayState();
}

class _PayState extends ConsumerState<_Pay> {
  PaymentMethod _method = PaymentMethod.card;
  int _tip = 20;

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final total = b.quote.balance + _tip;
    final cardOnly = Pricing.cardRequired(total);
    if (cardOnly) _method = PaymentMethod.card;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
      SbCard(
        child: Column(children: [
          Text('Amount due to ${b.provider!.shortName}', style: Theme.of(context).textTheme.bodySmall),
          Text(rand(b.quote.balance), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
          Text('${b.service.label} ${rand(b.quote.servicePrice)} + travel ${rand(b.quote.travelFee)}', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      const SectionLabel('Pay with'),
      for (final m in PaymentMethod.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SbCard(
            highlighted: _method == m,
            onTap: cardOnly && m == PaymentMethod.cash ? null : () => setState(() => _method = m),
            child: Row(children: [
              Icon(m == PaymentMethod.card ? Icons.credit_card : Icons.payments_outlined, color: SbColors.ink2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m == PaymentMethod.card ? 'Card · Visa •••• 4471' : 'Cash to ${b.provider!.shortName}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: cardOnly && m == PaymentMethod.cash ? SbColors.ink3 : SbColors.ink)),
              ),
              if (_method == m) const Icon(Icons.check_circle, color: SbColors.aquaDark),
            ]),
          ),
        ),
      const SectionLabel('Tip (optional)'),
      Wrap(spacing: 8, children: [
        for (final t in [0, 20, 50])
          ChoiceChip(selected: _tip == t, label: Text(t == 0 ? 'None' : rand(t)), onSelected: (_) => setState(() => _tip = t)),
      ]),
      const SizedBox(height: 12),
      Note('Totals of ${rand(Pricing.cardOnlyFrom)} or more must be paid by card in the app.', tone: SbTone.warning),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => ref.read(bookingsProvider.notifier).pay(b.ref, _method, _tip),
        icon: const Icon(Icons.lock_outline, size: 18),
        label: Text(_method == PaymentMethod.card ? 'Pay ${rand(total)}' : 'I paid ${rand(total)} in cash'),
      ),
    ]);
  }
}

class _Done extends ConsumerStatefulWidget {
  const _Done({required this.b});

  final Booking b;

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done> {
  int _stars = 5;
  final _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final rated = b.rating != null;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.check_circle, color: SbColors.green, size: 72),
      const SizedBox(height: 8),
      Text('All done!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      Text('${rand(b.quote.balance + b.tip)} paid · receipt sent to your email', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      if (!rated) ...[
        SbCard(
          child: Column(children: [
            Text('How was ${b.provider?.shortName ?? 'your washer'}?', style: Theme.of(context).textTheme.titleMedium),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: SbColors.yellow, size: 36),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(controller: _review, maxLines: 3, decoration: const InputDecoration(labelText: 'Tell others (optional)')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => ref.read(bookingsProvider.notifier).rate(b.ref, _stars, _review.text),
          child: const Text('Submit review'),
        ),
      ] else ...[
        const Note('Thanks for your review!', tone: SbTone.success, icon: Icons.favorite_outline),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => context.push('/receipt/${b.ref}'), child: const Text('View receipt')),
      ],
      const SizedBox(height: 10),
      TextButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
    ]);
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.cancel_outlined, color: SbColors.red, size: 64),
        const SizedBox(height: 8),
        Text('Booking cancelled', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        Text('${rand(b.refundAmount ?? 0)} is on its way back to your card (3–5 working days).', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
      ]);
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _messages = <(bool, String)>[
    (false, 'Hi, I’m on my way. About 7 minutes.'),
    (true, 'Great thanks! Gate code is 4471, car is in visitor bay 2.'),
    (false, 'Got it. I’ll use your outside tap and plug, is that ok?'),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String t) {
    if (t.trim().isEmpty) return;
    setState(() => _messages.add((true, t.trim())));
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(bookingProvider(widget.bookingRef));
    final open = b != null && b.status.isActive;
    return Scaffold(
      appBar: AppBar(title: Text(b?.provider?.shortName ?? 'Chat')),
      body: ResponsiveBody(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Chat closes after your wash · numbers stay private', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: SbColors.ink3)),
              const SizedBox(height: 10),
              for (final (mine, t) in _messages)
                Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: mine ? SbColors.aquaDark : Colors.white,
                      border: mine ? null : Border.all(color: SbColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(t, style: TextStyle(color: mine ? Colors.white : SbColors.ink, fontSize: 13.5)),
                  ),
                ),
            ]),
          ),
          if (open)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Column(children: [
                  Wrap(spacing: 6, children: [
                    for (final q in ['I’m outside', 'Gate is open', 'Please call me']) ActionChip(label: Text(q), onPressed: () => _send(q)),
                  ]),
                  Row(children: [
                    Expanded(child: TextField(controller: _text, decoration: const InputDecoration(hintText: 'Message…'), onSubmitted: _send)),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: () => _send(_text.text), icon: const Icon(Icons.send)),
                  ]),
                ]),
              ),
            )
          else
            const Padding(padding: EdgeInsets.all(16), child: Note('This chat is closed because the booking has ended.')),
        ]),
      ),
    );
  }
}
