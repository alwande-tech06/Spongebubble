import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.path, {this.count});

  final String label;
  final IconData icon;
  final String path;
  final int? count;
}

const _nav = <(String?, List<_NavItem>)>[
  (null, [
    _NavItem('Dashboard', Icons.home_outlined, '/dashboard'),
    _NavItem('Bookings', Icons.calendar_month_outlined, '/bookings'),
    _NavItem('Allocation', Icons.bolt_outlined, '/soon/allocation', count: 7),
    _NavItem('Customers', Icons.people_outline, '/customers'),
    _NavItem('Providers', Icons.badge_outlined, '/providers'),
    _NavItem('Applications', Icons.how_to_reg_outlined, '/applications', count: 3),
    _NavItem('Services & pricing', Icons.sell_outlined, '/pricing'),
  ]),
  ('FINANCE', [
    _NavItem('Transactions', Icons.credit_card, '/soon/transactions'),
    _NavItem('Refunds', Icons.undo, '/soon/refunds'),
    _NavItem('Payouts', Icons.account_balance_wallet_outlined, '/soon/payouts'),
  ]),
  ('SUPPORT', [
    _NavItem('Tickets', Icons.chat_bubble_outline, '/tickets', count: 19),
    _NavItem('Reviews', Icons.star_outline, '/soon/reviews'),
    _NavItem('Incidents', Icons.warning_amber_outlined, '/soon/incidents'),
  ]),
  ('GOVERNANCE', [
    _NavItem('Compliance', Icons.verified_user_outlined, '/soon/compliance'),
    _NavItem('Reports', Icons.bar_chart, '/soon/reports'),
    _NavItem('Admin users', Icons.manage_accounts_outlined, '/soon/admin-users'),
    _NavItem('Audit log', Icons.receipt_long_outlined, '/soon/audit-log'),
  ]),
];

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.path, required this.child});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final sidebar = _Sidebar(path: path);
    return Scaffold(
      drawer: wide ? null : Drawer(backgroundColor: SbColors.navy, child: sidebar),
      body: Row(children: [
        if (wide) sidebar,
        Expanded(
          child: Column(children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: SbColors.line))),
              child: Row(children: [
                if (!wide) Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu))),
                const SizedBox(
                  width: 420,
                  child: TextField(decoration: InputDecoration(isDense: true, hintText: 'Search bookings, customers, providers…', prefixIcon: Icon(Icons.search))),
                ),
                const Spacer(),
                const StatusBadge('Durban & surrounds', tone: SbTone.warning, icon: Icons.place_outlined),
                const SizedBox(width: 12),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                const Avatar('QN', size: 36, background: SbColors.yellow, foreground: SbColors.ink),
              ]),
            ),
            Expanded(child: child),
          ]),
        ),
      ]),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 248,
      color: SbColors.navy,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), children: [
        const SbLogo(height: 110),
        const Center(child: Text('ADMIN PORTAL', style: TextStyle(color: SbColors.sideText, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4))),
        const Divider(color: SbColors.navy2, height: 24),
        for (final (group, items) in _nav) ...[
          if (group != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
              child: Text(group, style: const TextStyle(color: Color(0xFF6F8E96), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ),
          for (final it in items)
            Builder(builder: (context) {
              final on = path == it.path || (it.path != '/dashboard' && path.startsWith('${it.path}/'));
              return Material(
                color: on ? SbColors.navy2 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Scaffold.maybeOf(context)?.closeDrawer();
                    context.go(it.path);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(children: [
                      Icon(it.icon, size: 18, color: on ? SbColors.yellow : SbColors.sideText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(it.label,
                            style: TextStyle(color: on ? Colors.white : SbColors.sideText, fontSize: 13.5, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
                      ),
                      if (it.count != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFF24505C), borderRadius: BorderRadius.circular(999)),
                          child: Text('${it.count}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),
              );
            }),
        ],
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            ref.read(adminSignedInProvider.notifier).state = false;
            context.go('/signin');
          },
          icon: const Icon(Icons.logout, color: SbColors.sideText, size: 18),
          label: const Text('Sign out', style: TextStyle(color: SbColors.sideText)),
        ),
      ]),
    );
  }
}
