import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

/// Page frame: title, subtitle, optional actions, scrolling content.
class _Page extends StatelessWidget {
  const _Page({required this.title, this.subtitle = '', this.actions = const [], required this.children});

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(32, 28, 32, 40), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              if (subtitle.isNotEmpty) Text(subtitle),
            ]),
          ),
          for (final a in actions) ...[const SizedBox(width: 10), a],
        ]),
        const SizedBox(height: 22),
        for (final c in children) ...[c, const SizedBox(height: 18)],
      ]);
}

Widget _table({required List<String> columns, required List<DataRow> rows}) => SbCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FBFB)),
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .6, color: SbColors.ink3),
          columns: [for (final c in columns) DataColumn(label: Text(c.toUpperCase()))],
          rows: rows,
        ),
      ),
    );

Widget _stat(String label, String value, String delta, {Color deltaColor = SbColors.green}) => Expanded(
      child: SbCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: SbColors.ink2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          Text(delta, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: deltaColor)),
        ]),
      ),
    );

DataRow _bookingRow(BuildContext context, Booking b) => DataRow(
      onSelectChanged: (_) => context.go('/bookings/${b.ref}'),
      cells: [
        DataCell(Text(b.ref, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(b.customer.name)),
        DataCell(Text('${b.service.label} · ${b.vehicle.category.label}')),
        DataCell(Text(b.isImmediate ? 'Now · ${hhmm(b.createdAt)}' : when(b.scheduledAt))),
        DataCell(Text(b.address.line.split(',').first)),
        DataCell(Text(b.provider?.name ?? '—')),
        DataCell(StatusBadge(b.status.label, tone: toneForStatus(b.status))),
        DataCell(Text(rand(b.quote.balance), style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );

const _bookingCols = ['Reference', 'Customer', 'Service', 'When', 'Area', 'Provider', 'Status', 'Balance'];

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(adminBookingsProvider);
    final apps = ref.watch(applicationsProvider).where((a) => a.status == ApplicationStatus.submitted).length;
    const week = [('Mon', 96), ('Tue', 112), ('Wed', 104), ('Thu', 121), ('Fri', 138), ('Sat', 164), ('Sun', 128)];
    return _Page(
      title: 'Good morning, Qiniso',
      subtitle: 'Here’s what’s happening across SpongeBubble today.',
      actions: [
        OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () {}, child: const Text('Export report')),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => context.go('/bookings'), child: const Text('View bookings')),
      ],
      children: [
        Row(children: [
          _stat('Bookings today', '128', '+12% vs last Sunday'),
          const SizedBox(width: 16),
          _stat('Waiting for a provider', '7', '2 over 10 minutes', deltaColor: SbColors.red),
          const SizedBox(width: 16),
          _stat('Washers online now', '46', 'of 61 approved providers', deltaColor: SbColors.ink3),
          const SizedBox(width: 16),
          _stat('Provider applications', '$apps', 'waiting for review', deltaColor: SbColors.yellowInk),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: SbCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bookings this week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Text('Completed and active bookings per day', style: TextStyle(fontSize: 12.5)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (final (d, v) in week)
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('$v', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SbColors.ink2)),
                          const SizedBox(height: 4),
                          Container(
                            height: v * 1.1,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: d == 'Sun' ? SbColors.yellow : SbColors.aqua,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(d, style: const TextStyle(fontSize: 12, color: SbColors.ink3)),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 360,
            child: SbCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Needs attention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final (text, sub, badge, tone, path) in [
                  ('7 bookings waiting for a provider', 'Allocation · oldest 14 min', 'Urgent', SbTone.danger, '/soon/allocation'),
                  ('$apps provider applications to review', 'Providers', 'Review', SbTone.warning, '/applications'),
                  ('3 disputes awaiting a response', 'Tickets · refund requests', 'Reply', SbTone.danger, '/tickets'),
                  ('Payout batch W46 ready', 'Finance · R61 400', 'Approve', SbTone.info, '/soon/payouts'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
                    trailing: StatusBadge(badge, tone: tone),
                    onTap: () => context.go(path),
                  ),
              ]),
            ),
          ),
        ]),
        const Text('Live bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        _table(columns: _bookingCols, rows: [for (final b in bookings) _bookingRow(context, b)]),
      ],
    );
  }
}

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  String _filter = 'All';

  bool _matches(Booking b) => switch (_filter) {
        'Waiting for provider' => b.status == BookingStatus.findingProvider,
        'In progress' => b.status.isActive && b.status != BookingStatus.findingProvider,
        'Completed' => b.status == BookingStatus.completed,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminBookingsProvider);
    final rows = all.where(_matches).toList();
    return _Page(
      title: 'Bookings',
      subtitle: 'Search by reference, customer, provider or location.',
      children: [
        Wrap(spacing: 8, children: [
          for (final f in ['All', 'Waiting for provider', 'In progress', 'Completed'])
            ChoiceChip(selected: _filter == f, label: Text(f), onSelected: (_) => setState(() => _filter = f)),
        ]),
        _table(columns: _bookingCols, rows: [for (final b in rows) _bookingRow(context, b)]),
      ],
    );
  }
}

class BookingDetailPage extends ConsumerWidget {
  const BookingDetailPage({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(adminBookingsProvider).where((x) => x.ref == bookingRef).firstOrNull;
    if (b == null) return const Center(child: Text('Booking not found'));
    return _Page(
      title: '${b.ref} · ${b.service.label}',
      subtitle: '${b.customer.name} · ${b.address.line}',
      actions: [
        StatusBadge(b.status.label, tone: toneForStatus(b.status)),
        OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => context.go('/bookings'), child: const Text('Back')),
      ],
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: SbCard(
              child: Column(children: [
                if (b.status.milestone >= 0) ...[Milestones(current: b.status.milestone), const SizedBox(height: 16)],
                KeyValue('Customer', '${b.customer.name} · ${b.customer.mobile}'),
                KeyValue('Vehicle', '${b.vehicle.name} · ${b.vehicle.registration} · ${b.vehicle.category.label}'),
                KeyValue('When', b.isImmediate ? 'Immediate · created ${hhmm(b.createdAt)}' : when(b.scheduledAt)),
                KeyValue('Provider', b.provider?.name ?? 'Not assigned'),
                KeyValue('Water & power', '${b.waterAllowed ? 'Yes' : 'No'} · ${b.powerAllowed ? 'Yes' : 'No'}'),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: SbCard(
              child: Column(children: [
                KeyValue('Service price', rand(b.quote.servicePrice)),
                KeyValue('Travel fee (${b.quote.distanceKm} km)', rand(b.quote.travelFee)),
                KeyValue('Booking fee', '${rand(b.quote.bookingFee)} · paid'),
                const Divider(),
                KeyValue('Balance to provider', rand(b.quote.balance), strong: true),
                KeyValue('Platform commission', rand((b.quote.servicePrice * Pricing.commissionRate).round())),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () {}, child: const Text('Issue refund')),
              ]),
            ),
          ),
        ]),
      ],
    );
  }
}

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(applicationsProvider);
    final n = ref.read(applicationsProvider.notifier);
    (String, SbTone) badge(ApplicationStatus s) => switch (s) {
          ApplicationStatus.submitted => ('New', SbTone.info),
          ApplicationStatus.moreInfo => ('More info requested', SbTone.warning),
          ApplicationStatus.approved => ('Approved', SbTone.success),
          ApplicationStatus.rejected => ('Rejected', SbTone.danger),
        };
    return _Page(
      title: 'Provider applications',
      subtitle: 'Only approved providers receive jobs. Check documents and bank details before approving.',
      children: [
        _table(
          columns: const ['Applicant', 'Type', 'Areas', 'Documents', 'Submitted', 'Status', 'Actions'],
          rows: [
            for (final a in apps)
              DataRow(cells: [
                DataCell(Text(a.applicant, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(a.type == ProviderType.business ? 'Business' : 'Individual')),
                DataCell(Text(a.areas.join(', '))),
                DataCell(Text('${a.documents} of ${a.documentsTotal}',
                    style: TextStyle(color: a.documents < a.documentsTotal ? SbColors.red : SbColors.ink))),
                DataCell(Text(when(a.submitted))),
                DataCell(StatusBadge(badge(a.status).$1, tone: badge(a.status).$2)),
                DataCell(a.status != ApplicationStatus.submitted
                    ? const Text('—')
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        TextButton(
                          onPressed: a.documents < a.documentsTotal ? null : () => n.setStatus(a.id, ApplicationStatus.approved),
                          child: const Text('Approve'),
                        ),
                        TextButton(onPressed: () => n.setStatus(a.id, ApplicationStatus.moreInfo), child: const Text('Ask for info')),
                        TextButton(
                          onPressed: () => n.setStatus(a.id, ApplicationStatus.rejected),
                          child: const Text('Reject', style: TextStyle(color: SbColors.red)),
                        ),
                      ])),
              ]),
          ],
        ),
        const Note('Approve is disabled until every required document is uploaded. Each decision is written to the audit log.'),
      ],
    );
  }
}

class ProvidersPage extends ConsumerWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(providersListProvider);
    return _Page(
      title: 'Providers',
      subtitle: '${list.length} approved providers in this prototype',
      actions: [OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: () => context.go('/applications'), child: const Text('Applications'))],
      children: [
        _table(
          columns: const ['Provider', 'Type', 'Areas', 'Rating', 'Plan', 'Status'],
          rows: [
            for (final p in list)
              DataRow(cells: [
                DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(p.type == ProviderType.business ? 'Business' : 'Individual')),
                DataCell(Text(p.areas.join(', '))),
                DataCell(Text('★ ${p.rating} (${p.reviews})')),
                DataCell(Text(p.plan == ProviderPlan.commission ? 'Commission' : 'Subscription')),
                DataCell(StatusBadge(p.online ? 'Online' : 'Offline', tone: p.online ? SbTone.success : SbTone.neutral)),
              ]),
          ],
        ),
      ],
    );
  }
}

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = {for (final b in [...ref.watch(adminBookingsProvider), ...MockData.pastBookings]) b.customer.id: b.customer}.values;
    return _Page(
      title: 'Customers',
      subtitle: 'Profiles, vehicles and booking history.',
      children: [
        _table(
          columns: const ['Customer', 'Email', 'Mobile', 'Status'],
          rows: [
            for (final c in customers)
              DataRow(cells: [
                DataCell(Row(children: [Avatar(c.initials, size: 30), const SizedBox(width: 10), Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))])),
                DataCell(Text(c.email)),
                DataCell(Text(c.mobile)),
                const DataCell(StatusBadge('Active', tone: SbTone.success)),
              ]),
          ],
        ),
      ],
    );
  }
}

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    (String, SbTone) badge(TicketStatus s) => switch (s) {
          TicketStatus.open => ('Open', SbTone.warning),
          TicketStatus.investigating => ('Investigating', SbTone.info),
          TicketStatus.awaitingResponse => ('Awaiting response', SbTone.warning),
          TicketStatus.resolved => ('Resolved', SbTone.success),
        };
    return _Page(
      title: 'Support tickets',
      subtitle: 'First-response target 2 hours · disputes need evidence before a refund.',
      children: [
        _table(
          columns: const ['Ticket', 'Subject', 'From', 'Booking', 'Priority', 'Status', 'Updated'],
          rows: [
            for (final t in MockData.tickets)
              DataRow(cells: [
                DataCell(Text(t.id, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(t.subject)),
                DataCell(Text(t.from)),
                DataCell(Text(t.bookingRef)),
                DataCell(Text(t.priority, style: TextStyle(color: t.priority == 'High' ? SbColors.red : SbColors.ink))),
                DataCell(StatusBadge(badge(t.status).$1, tone: badge(t.status).$2)),
                DataCell(Text(t.updated)),
              ]),
          ],
        ),
      ],
    );
  }
}

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Services & pricing',
      subtitle: 'Prices by service and vehicle size. Changes apply to new bookings only.',
      children: [
        _table(
          columns: ['Service', for (final c in VehicleCategory.values) c.label],
          rows: [
            for (final s in ServiceType.values)
              DataRow(cells: [
                DataCell(Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                for (final c in VehicleCategory.values) DataCell(Text(rand(Pricing.servicePrice(s, c)))),
              ]),
          ],
        ),
        SbCard(
          child: Column(children: [
            KeyValue('Booking fee', '${rand(Pricing.bookingFee)} · TBC'),
            KeyValue('Travel fee', 'R${Pricing.travelRatePerKm} per km · TBC'),
            KeyValue('Card required from', rand(Pricing.cardOnlyFrom)),
            KeyValue('Provider commission', '${(Pricing.commissionRate * 100).round()}% of service price · TBC'),
            KeyValue('Provider subscription', '${rand(Pricing.subscriptionPerWeek)} per week · TBC'),
            KeyValue('Free cancellation (scheduled)', '${Pricing.freeCancelBefore.inHours} hours before the slot'),
            KeyValue('Late provider: full refund after', '${Pricing.lateAfter.inMinutes} minutes'),
          ]),
        ),
        const Note('Prototype: values come from Pricing in packages/sb_core. In the backend phase they move to the database and are edited here.'),
      ],
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final title = name.replaceAll('-', ' ');
    return _Page(
      title: '${title[0].toUpperCase()}${title.substring(1)}',
      subtitle: 'Designed in the wireframes; built in the next prototype.',
      children: const [Note('This page is in the clickable prototype and the Figma wireframes. It is not wired up in this Flutter build yet.')],
    );
  }
}
