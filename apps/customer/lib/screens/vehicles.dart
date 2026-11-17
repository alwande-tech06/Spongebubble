import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sb_core/sb_core.dart';
import 'package:sb_ui/sb_ui.dart';

import '../state.dart';

class VehiclesTab extends ConsumerWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My vehicles'),
        actions: [IconButton.filled(onPressed: () => context.push('/vehicles/add'), icon: const Icon(Icons.add)), const SizedBox(width: 12)],
      ),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
          for (final v in vehicles) ...[
            SbCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: SbColors.grey, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.directions_car_outlined, color: SbColors.ink2, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${v.name} ${v.year}', style: Theme.of(context).textTheme.titleMedium),
                      Text('${v.registration} · ${v.colour}', style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                  StatusBadge(v.category.label),
                ]),
                const Divider(height: 24),
                Row(children: [
                  if (v.isDefault)
                    const Text('Default vehicle', style: TextStyle(fontSize: 12, color: SbColors.ink3))
                  else
                    TextButton(onPressed: () => ref.read(vehiclesProvider.notifier).makeDefault(v.id), child: const Text('Make default')),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final d = ref.read(draftProvider);
                      ref.read(draftProvider.notifier).set(d.copyWith(vehicle: v, clearSchedule: true));
                      context.push('/book/service');
                    },
                    child: const Text('Book wash'),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          const Note('Your vehicle size sets the price. If the washer finds the size is wrong, they ask you to approve the change before starting.'),
        ]),
      ),
    );
  }
}

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _make = TextEditingController(text: 'Toyota');
  final _model = TextEditingController(text: 'Hilux');
  final _year = TextEditingController(text: '2022');
  final _colour = TextEditingController(text: 'Silver');
  final _reg = TextEditingController(text: 'NPN 45-118');
  bool _default = false;

  @override
  void dispose() {
    for (final c in [_make, _model, _year, _colour, _reg]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = guessCategory(_make.text, _model.text);
    Widget field(String label, TextEditingController c, {TextInputType? type}) => TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Add a vehicle')),
      body: ResponsiveBody(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [Expanded(child: field('Make', _make)), const SizedBox(width: 10), Expanded(child: field('Model', _model))]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: field('Year', _year, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: field('Colour', _colour)),
          ]),
          const SizedBox(height: 14),
          field('Registration number', _reg),
          const SizedBox(height: 16),
          SbCard(
            color: SbColors.aquaSoft,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Size category (set automatically)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SbColors.aquaDark)),
                  Text(category.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(
                    '${category.examples}. Full Wash ${rand(Pricing.servicePrice(ServiceType.fullWash, category))}',
                    style: const TextStyle(fontSize: 12, color: SbColors.ink2),
                  ),
                ]),
              ),
              const Icon(Icons.verified_outlined, color: SbColors.aquaDark, size: 26),
            ]),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _default,
            onChanged: (v) => setState(() => _default = v ?? false),
            title: const Text('Make this my default vehicle'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              ref.read(vehiclesProvider.notifier).add(Vehicle(
                    id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
                    make: _make.text.trim(),
                    model: _model.text.trim(),
                    year: int.tryParse(_year.text) ?? 0,
                    colour: _colour.text.trim(),
                    registration: _reg.text.trim().toUpperCase(),
                    category: category,
                    isDefault: _default,
                  ));
              context.pop();
            },
            child: const Text('Save vehicle'),
          ),
        ]),
      ),
    );
  }
}
