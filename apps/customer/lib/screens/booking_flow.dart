import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

Scaffold _step({
  required BuildContext context,
  required String title,
  required int step,
  required List<Widget> children,
  required Widget action,
}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [Padding(padding: const EdgeInsets.only(right: 20), child: Text('$step of 4', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)))],
    ),
    body: ResponsiveBody(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
        StepDots(step: step, total: 4),
        const SizedBox(height: 16),
        ...children,
      ]),
    ),
    bottomNavigationBar: ResponsiveBody(child: BottomAction(children: [action])),
  );
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({required this.selected, required this.onTap, required this.title, this.subtitle = '', this.trailing});

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SbCard(
          highlighted: selected,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? SbColors.aquaDark : SbColors.ink3),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                if (subtitle.isNotEmpty) Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      );
}

// ---------------- 1. Vehicle & service ----------------
class BookServiceScreen extends ConsumerWidget {
  const BookServiceScreen({super.key, this.scheduleFirst = false});

  final bool scheduleFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(draftProvider);
    final vehicles = ref.watch(vehiclesProvider);
    final notifier = ref.read(draftProvider.notifier);
    return _step(
      context: context,
      title: 'Book a wash',
      step: 1,
      children: [
        const SectionLabel('Vehicle'),
        for (final v in vehicles)
          _RadioCard(
            selected: d.vehicle?.id == v.id,
            onTap: () => notifier.set(d.copyWith(vehicle: v)),
            title: '${v.name} · ${v.registration}',
            subtitle: 'Category: ${v.category.label}',
          ),
        TextButton.icon(onPressed: () => context.push('/vehicles/add'), icon: const Icon(Icons.add), label: const Text('Add vehicle')),
        const SectionLabel('Service'),
        for (final s in ServiceType.values)
          _RadioCard(
            selected: d.service == s,
            onTap: () => notifier.set(d.copyWith(service: s)),
            title: s.label,
            subtitle: '${s.description} · about ${s.minutes} min',
            trailing: d.vehicle == null
                ? null
                : Text(rand(Pricing.servicePrice(s, d.vehicle!.category)), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
      ],
      action: FilledButton(
        onPressed: d.vehicle == null ? null : () => context.push(scheduleFirst ? '/book/when?schedule=1' : '/book/when'),
        child: const Text('Continue'),
      ),
    );
  }
}

// ---------------- 2. When ----------------
class BookWhenScreen extends ConsumerStatefulWidget {
  const BookWhenScreen({super.key, this.scheduleFirst = false});

  final bool scheduleFirst;

  @override
  ConsumerState<BookWhenScreen> createState() => _BookWhenScreenState();
}

class _BookWhenScreenState extends ConsumerState<BookWhenScreen> {
  late bool _now;
  late final DateTime _start;
  late DateTime _day;
  int _hour = 10;

  @override
  void initState() {
    super.initState();
    final d = ref.read(draftProvider);
    _now = d.scheduledAt == null && !widget.scheduleFirst;
    final t = DateTime.now().add(const Duration(days: 1));
    _start = DateTime(t.year, t.month, t.day);
    _day = _start;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _start.add(Duration(days: i)));
    const hours = [8, 9, 10, 11, 12, 13, 14, 15, 16];
    final picked = DateTime(_day.year, _day.month, _day.day, _hour);
    return _step(
      context: context,
      title: 'When?',
      step: 2,
      children: [
        Row(children: [
          Expanded(child: _RadioCard(selected: _now, onTap: () => setState(() => _now = true), title: 'Now', subtitle: 'Washer comes ASAP')),
          const SizedBox(width: 10),
          Expanded(child: _RadioCard(selected: !_now, onTap: () => setState(() => _now = false), title: 'Schedule', subtitle: 'Pick date & time')),
        ]),
        if (!_now) ...[
          const SectionLabel('Day'),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final day = days[i];
                final on = day.day == _day.day && day.month == _day.month;
                return ChoiceChip(
                  selected: on,
                  showCheckmark: false,
                  label: Text(shortDate(day).replaceFirst(' ', '\n'), textAlign: TextAlign.center),
                  onSelected: (_) => setState(() => _day = day),
                );
              },
            ),
          ),
          const SectionLabel('Available times'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in hours)
              ChoiceChip(
                selected: h == _hour,
                showCheckmark: false,
                label: Text('${h.toString().padLeft(2, '0')}:00'),
                onSelected: (_) => setState(() => _hour = h),
              ),
          ]),
          const SizedBox(height: 16),
          const Note('Free cancellation up to 12 hours before your slot.', icon: Icons.event_available),
        ],
      ],
      action: FilledButton(
        onPressed: () {
          final d = ref.read(draftProvider);
          ref.read(draftProvider.notifier).set(_now ? d.copyWith(clearSchedule: true) : d.copyWith(scheduledAt: picked));
          context.push('/book/where');
        },
        child: Text(_now ? 'Continue · wash now' : 'Continue · ${when(picked)}'),
      ),
    );
  }
}

// ---------------- 3. Where ----------------
class BookWhereScreen extends ConsumerStatefulWidget {
  const BookWhereScreen({super.key});

  @override
  ConsumerState<BookWhereScreen> createState() => _BookWhereScreenState();
}

class _BookWhereScreenState extends ConsumerState<BookWhereScreen> {
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: ref.read(draftProvider).address?.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final n = ref.read(draftProvider.notifier);
    return _step(
      context: context,
      title: 'Where?',
      step: 3,
      children: [
        const MapPlaceholder(height: 180, label: 'Drop a pin · Google Maps'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final a in MockData.addresses)
            ChoiceChip(
              selected: d.address?.label == a.label,
              label: Text(a.label),
              onSelected: (_) {
                n.set(d.copyWith(address: a));
                _notes.text = a.notes;
              },
            ),
          ActionChip(avatar: const Icon(Icons.my_location, size: 16), label: const Text('Current location'), onPressed: () {}),
        ]),
        const SizedBox(height: 10),
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.place_outlined, color: SbColors.aquaDark),
            const SizedBox(width: 10),
            Expanded(child: Text(d.address?.line ?? 'Choose an address', style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 10),
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(children: [
            SwitchListTile(
              value: d.water,
              onChanged: (v) => n.set(d.copyWith(water: v)),
              secondary: const Icon(Icons.water_drop_outlined, color: SbColors.aquaDark),
              title: const Text('Washer may use my water tap'),
            ),
            SwitchListTile(
              value: d.power,
              onChanged: (v) => n.set(d.copyWith(power: v)),
              secondary: const Icon(Icons.power_outlined, color: SbColors.aquaDark),
              title: const Text('Washer may use my plug point'),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Access instructions & notes', hintText: 'Gate code, parking bay…'),
        ),
      ],
      action: FilledButton(
        onPressed: d.address == null
            ? null
            : () {
                n.set(ref.read(draftProvider).copyWith(notes: _notes.text));
                context.push('/book/review');
              },
        child: const Text('Continue'),
      ),
    );
  }
}

// ---------------- 4. Review & pay ----------------
class BookReviewScreen extends ConsumerStatefulWidget {
  const BookReviewScreen({super.key});

  @override
  ConsumerState<BookReviewScreen> createState() => _BookReviewScreenState();
}

class _BookReviewScreenState extends ConsumerState<BookReviewScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    // Prototype: the real app opens the payment gateway (3-D Secure) and
    // the server confirms the payment before a washer is searched for.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final r = ref.read(bookingsProvider.notifier).create(ref.read(draftProvider), ref.read(customerProvider));
    context.go('/booking/$r');
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final q = d.quote!;
    return _step(
      context: context,
      title: 'Review & pay',
      step: 4,
      children: [
        SbCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            KeyValue('Vehicle', '${d.vehicle!.name} · ${d.vehicle!.category.label}'),
            KeyValue('Service', d.service.label),
            KeyValue('When', when(d.scheduledAt)),
            KeyValue('Where', d.address!.line),
            KeyValue('Water & power', '${d.water ? 'Yes' : 'No'} · ${d.power ? 'Yes' : 'No'}'),
          ]),
        ),
        const SizedBox(height: 12),
        PriceBreakdown(quote: q, service: d.service, category: d.vehicle!.category),
        const SizedBox(height: 12),
        const Note('The booking fee secures your washer and is separate from the wash price. Fully refunded if no washer accepts.'),
        const SizedBox(height: 12),
        const SbCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(Icons.credit_card, color: SbColors.ink2),
            SizedBox(width: 12),
            Expanded(child: Text('Visa •••• 4471', style: TextStyle(fontWeight: FontWeight.w600))),
            Text('Change', style: TextStyle(color: SbColors.aquaDark, fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
      action: FilledButton.icon(
        onPressed: _paying ? null : _pay,
        icon: _paying
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.lock_outline, size: 18),
        label: Text(_paying ? 'Confirming with your bank…' : 'Pay ${rand(q.bookingFee)} booking fee'),
      ),
    );
  }
}
