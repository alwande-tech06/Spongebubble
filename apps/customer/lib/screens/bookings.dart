import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class BookingsTab extends ConsumerWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(bookingsProvider);
    final upcoming = all.where((b) => b.status.isActive).toList();
    final past = all.where((b) => b.status == BookingStatus.completed).toList();
    final cancelled = all.where((b) => b.status == BookingStatus.cancelled).toList();

    Widget list(List<Booking> items, String empty) => items.isEmpty
        ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(empty, textAlign: TextAlign.center)))
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (c, i) => BookingTile(booking: items[i]),
          );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: TabBar(tabs: [
            Tab(text: 'Upcoming ${upcoming.length}'),
            const Tab(text: 'Past'),
            const Tab(text: 'Cancelled'),
          ]),
        ),
        body: ResponsiveBody(
          child: TabBarView(children: [
            list(upcoming, 'No upcoming washes. Book one from Home.'),
            list(past, 'Your completed washes will show here.'),
            list(cancelled, 'No cancelled bookings.'),
          ]),
        ),
      ),
    );
  }
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final done = b.status == BookingStatus.completed;
    return SbCard(
      onTap: () => context.push(b.status.isActive ? '/booking/${b.ref}' : '/receipt/${b.ref}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${b.service.label} · ${b.vehicle.model}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              Text('${b.ref} · ${when(b.scheduledAt ?? b.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          StatusBadge(b.status.label, tone: toneForStatus(b.status)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(b.provider == null ? 'No washer assigned' : b.provider!.shortName, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (done)
            Text(rand(b.quote.total + b.tip), style: const TextStyle(fontWeight: FontWeight.w700))
          else
            const Icon(Icons.chevron_right, color: SbColors.ink3),
        ]),
      ]),
    );
  }
}

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(bookingProvider(bookingRef));
    if (b == null) return const Scaffold(body: Center(child: Text('Booking not found')));
    final paid = b.status == BookingStatus.completed;
    return Scaffold(
      appBar: AppBar(title: Text(b.ref), actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: StatusBadge(b.status.label, tone: toneForStatus(b.status)))),
      ]),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          SbCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [
              KeyValue('Date', when(b.scheduledAt ?? b.createdAt)),
              KeyValue('Vehicle', '${b.vehicle.name} · ${b.vehicle.category.label}'),
              KeyValue('Washer', b.provider?.shortName ?? '—'),
              KeyValue('Address', b.address.line),
              if (b.rating != null) KeyValue('Your rating', '★' * b.rating!),
            ]),
          ),
          const SizedBox(height: 12),
          SbCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [
              KeyValue('${b.service.label} (${b.vehicle.category.label})', rand(b.quote.servicePrice)),
              KeyValue('Travel fee', rand(b.quote.travelFee)),
              if (b.tip > 0) KeyValue('Tip', rand(b.tip)),
              KeyValue('Booking fee', rand(b.quote.bookingFee)),
              const Divider(),
              if (paid)
                KeyValue('Total paid', rand(b.quote.total + b.tip), strong: true)
              else
                KeyValue('Refunded', rand(b.refundAmount ?? b.quote.bookingFee), strong: true),
              if (paid) KeyValue('Paid by', b.paymentMethod == PaymentMethod.cash ? 'Cash + card (fee)' : 'Visa •••• 4471'),
            ]),
          ),
          if (paid) ...[
            const SectionLabel('Photos'),
            const Row(children: [
              Expanded(child: PhotoSlot(label: 'Before', height: 80)),
              SizedBox(width: 8),
              Expanded(child: PhotoSlot(label: 'After', height: 80)),
              SizedBox(width: 8),
              Expanded(child: PhotoSlot(label: 'After', height: 80)),
            ]),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final d = ref.read(draftProvider);
              ref.read(draftProvider.notifier).set(d.copyWith(vehicle: b.vehicle, service: b.service, clearSchedule: true));
              context.push('/book/service');
            },
            child: const Text('Book again (today’s prices)'),
          ),
          if (paid)
            TextButton(
              onPressed: () => context.push('/report/${b.ref}'),
              child: const Text('Problem with this wash? Report it', style: TextStyle(color: SbColors.red)),
            ),
        ]),
      ),
    );
  }
}
