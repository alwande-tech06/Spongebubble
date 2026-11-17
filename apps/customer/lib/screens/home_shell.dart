import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';
import 'account.dart';
import 'bookings.dart';
import 'vehicles.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onTab: (i) => setState(() => _tab = i)),
      const BookingsTab(),
      const VehiclesTab(),
      const SupportTab(),
      const AccountTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.headset_mic_outlined), label: 'Support'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  void _startBooking(BuildContext context, WidgetRef ref, {required bool now, ServiceType? service}) {
    ref.read(draftProvider.notifier).reset();
    final d = ref.read(draftProvider);
    ref.read(draftProvider.notifier).set(d.copyWith(service: service, clearSchedule: now));
    context.push(now ? '/book/service' : '/book/service?schedule=1');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider);
    final vehicles = ref.watch(vehiclesProvider);
    ref.watch(bookingsProvider);
    final active = ref.read(bookingsProvider.notifier).active;
    const medium = VehicleCategory.medium;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Container(
          color: SbColors.navy,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 24),
          child: ResponsiveBody(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const SbLogo(variant: SbLogoVariant.mark, height: 46),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
                Avatar(customer.initials, background: SbColors.yellow, foreground: SbColors.ink),
              ]),
              const SizedBox(height: 16),
              Text('Sawubona, ${customer.firstName}', style: const TextStyle(color: SbColors.sideText, fontSize: 14)),
              const SizedBox(height: 2),
              const Text('Ready for a clean car?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: SbColors.yellow, foregroundColor: SbColors.ink),
                    onPressed: () => _startBooking(context, ref, now: true),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Wash now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: SbColors.navy2),
                    onPressed: () => _startBooking(context, ref, now: false),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Schedule'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: ResponsiveBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (active != null) ...[
                ActiveBookingCard(booking: active),
                const SizedBox(height: 16),
              ],
              SectionLabel('Services', trailing: Text('Prices for ${medium.label}', style: const TextStyle(fontSize: 12, color: SbColors.ink3))),
              Row(children: [
                for (final s in ServiceType.values) ...[
                  if (s != ServiceType.values.first) const SizedBox(width: 10),
                  Expanded(
                    child: SbCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => _startBooking(context, ref, now: true, service: s),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(s == ServiceType.internal ? Icons.cleaning_services_outlined : Icons.water_drop_outlined, color: SbColors.aquaDark),
                        const SizedBox(height: 8),
                        Text(s.label.split(' ').first, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(rand(Pricing.servicePrice(s, medium)), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              SectionLabel('Your vehicles', trailing: TextButton(onPressed: () => onTab(2), child: const Text('Manage'))),
              for (final v in vehicles) ...[
                SbCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.directions_car_outlined, color: SbColors.ink2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${v.registration} · ${v.category.label}', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    if (v.isDefault) const StatusBadge('Default'),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }
}

class ActiveBookingCard extends StatelessWidget {
  const ActiveBookingCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final title = switch (b.status) {
      BookingStatus.findingProvider => 'Finding your washer…',
      BookingStatus.travelling => '${b.provider?.shortName ?? 'Your washer'} is ${b.etaMinutes} min away',
      _ => b.status.label,
    };
    return SbCard(
      highlighted: true,
      onTap: () => context.push('/booking/${b.ref}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACTIVE BOOKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .7, color: SbColors.aquaDark)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        Text('${b.ref} · ${b.service.label} · ${b.vehicle.model}', style: Theme.of(context).textTheme.bodySmall),
        if (b.status.milestone >= 0) ...[const SizedBox(height: 12), Milestones(current: b.status.milestone)],
        const SizedBox(height: 12),
        FilledButton(onPressed: () => context.push('/booking/${b.ref}'), child: const Text('Open booking')),
      ]),
    );
  }
}
