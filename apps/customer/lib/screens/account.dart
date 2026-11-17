import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = MockData.tickets.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
          const TextField(decoration: InputDecoration(hintText: 'Search help articles', prefixIcon: Icon(Icons.search))),
          const SectionLabel('Your tickets'),
          SbCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w700))),
                const StatusBadge('Under investigation'),
              ]),
              Text('${t.id} · ${t.bookingRef} · updated ${t.updated} ago', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              const Note('Zanele (Support): “We’re checking the washer’s after photos and checklist.”', tone: SbTone.neutral, icon: Icons.chat_bubble_outline),
            ]),
          ),
          const SectionLabel('Get help with'),
          SbCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (icon, label) in const [
                (Icons.calendar_month_outlined, 'A booking'),
                (Icons.credit_card, 'Payments & refunds'),
                (Icons.auto_awesome_outlined, 'Service quality'),
                (Icons.person_outline, 'My account'),
              ])
                ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline), label: const Text('Chat with support')),
        ]),
      ),
    );
  }
}

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  ConsumerState<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  String _type = 'Poor service';
  String _want = 'Refund';
  int _photos = 0;

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(bookingProvider(widget.bookingRef));
    final needsPhoto = _want == 'Refund';
    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          if (b != null)
            SbCard(child: Text('${b.ref} · ${b.service.label} · ${b.vehicle.name}', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SectionLabel('What went wrong?'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in ['Poor service', 'Damage to my car', 'Payment issue', 'Washer behaviour', 'Other'])
              ChoiceChip(selected: _type == t, label: Text(t), onSelected: (_) => setState(() => _type = t)),
          ]),
          const SizedBox(height: 14),
          const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Describe it')),
          SectionLabel(needsPhoto ? 'Photo proof (required for a refund)' : 'Photos (optional)'),
          Row(children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: PhotoSlot(
                  label: i < _photos ? 'Photo ${i + 1}' : 'Add',
                  taken: i < _photos,
                  height: 80,
                  onTap: () => setState(() => _photos = (_photos + 1).clamp(0, 3)),
                ),
              ),
            ],
          ]),
          const SectionLabel('What would you like?'),
          Wrap(spacing: 8, children: [
            for (final w in ['Refund', 'Re-wash', 'Just report'])
              ChoiceChip(selected: _want == w, label: Text(w), onSelected: (_) => setState(() => _want = w)),
          ]),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: needsPhoto && _photos == 0
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to support · ticket TK-5513 created')));
                    context.go('/home?tab=3');
                  },
            child: Text(needsPhoto && _photos == 0 ? 'Add at least one photo' : 'Send to support'),
          ),
        ]),
      ),
    );
  }
}

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(customerProvider);
    final sections = [
      [
        (Icons.place_outlined, 'Saved addresses', 'Home · Work'),
        (Icons.credit_card, 'Payment cards', 'Visa •••• 4471'),
        (Icons.directions_car_outlined, 'Vehicles', '${ref.watch(vehiclesProvider).length} vehicles'),
      ],
      [
        (Icons.notifications_none, 'Notifications', 'Push, SMS, email'),
        (Icons.lock_outline, 'Password & security', 'Changed 2 months ago'),
        (Icons.privacy_tip_outlined, 'Privacy & data', 'Download or delete my data'),
      ],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
          SbCard(
            child: Row(children: [
              Avatar(c.initials, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${c.mobile} · ${c.email}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ]),
          ),
          for (final s in sections) ...[
            const SizedBox(height: 12),
            SbCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (icon, title, sub) in s)
                  ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right), onTap: () {}),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await ref.read(sessionProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout, color: SbColors.red),
            label: const Text('Sign out', style: TextStyle(color: SbColors.red)),
          ),
        ]),
      ),
    );
  }
}
