import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sb_core/sb_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the real instance.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// "Sign up once, stay signed in" (like Uber). In the backend phase this
/// becomes a refresh token in secure storage.
class SessionNotifier extends Notifier<bool> {
  static const _key = 'signed_in';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  Future<void> signIn() async {
    await ref.read(prefsProvider).setBool(_key, true);
    state = true;
  }

  Future<void> signOut() async {
    await ref.read(prefsProvider).setBool(_key, false);
    state = false;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, bool>(SessionNotifier.new);

final customerProvider = Provider<Customer>((ref) => MockData.customer);

// ---------------- Vehicles ----------------
class VehiclesNotifier extends Notifier<List<Vehicle>> {
  @override
  List<Vehicle> build() => [...MockData.vehicles];

  void add(Vehicle v) {
    state = [
      for (final x in state) v.isDefault ? x.copyWith(isDefault: false) : x,
      v,
    ];
  }

  void makeDefault(String id) {
    state = [for (final x in state) x.copyWith(isDefault: x.id == id)];
  }

  void remove(String id) {
    state = state.where((x) => x.id != id).toList();
  }
}

final vehiclesProvider = NotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

/// Simple make/model lookup that sets the size category. The real app
/// calls a vehicle-data service; the customer confirms the result.
VehicleCategory guessCategory(String make, String model) {
  final m = model.toLowerCase();
  const large = ['quantum', 'hiace', 'staria', 'v-class', 'carnival', 'innova'];
  const medium = ['fortuner', 'hilux', 'ranger', 'everest', 'rav4', 'tiguan', 'x-trail', 'navara', 'd-max', 'bt-50', 'creta', 'tucson'];
  if (large.any(m.contains)) return VehicleCategory.large;
  if (medium.any(m.contains)) return VehicleCategory.medium;
  return VehicleCategory.small;
}

// ---------------- Booking draft ----------------
class BookingDraft {
  const BookingDraft({
    this.vehicle,
    this.service = ServiceType.fullWash,
    this.scheduledAt,
    this.address,
    this.water = true,
    this.power = true,
    this.notes = '',
    this.km = 4,
  });

  final Vehicle? vehicle;
  final ServiceType service;
  final DateTime? scheduledAt; // null = wash now
  final Address? address;
  final bool water;
  final bool power;
  final String notes;
  final double km;

  PriceQuote? get quote => vehicle == null ? null : Pricing.quote(service, vehicle!.category, km);

  BookingDraft copyWith({
    Vehicle? vehicle,
    ServiceType? service,
    DateTime? scheduledAt,
    bool clearSchedule = false,
    Address? address,
    bool? water,
    bool? power,
    String? notes,
  }) =>
      BookingDraft(
        vehicle: vehicle ?? this.vehicle,
        service: service ?? this.service,
        scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
        address: address ?? this.address,
        water: water ?? this.water,
        power: power ?? this.power,
        notes: notes ?? this.notes,
        km: km,
      );
}

class DraftNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() {
    final vehicles = ref.read(vehiclesProvider);
    final def = vehicles.where((v) => v.isDefault).firstOrNull ?? vehicles.firstOrNull;
    return BookingDraft(vehicle: def, address: MockData.addresses.first);
  }

  void set(BookingDraft d) => state = d;
  void reset() => ref.invalidateSelf();
}

final draftProvider = NotifierProvider<DraftNotifier, BookingDraft>(DraftNotifier.new);

// ---------------- Bookings ----------------
class BookingsNotifier extends Notifier<List<Booking>> {
  var _seq = 104382;

  @override
  List<Booking> build() => [...MockData.pastBookings];

  Booking? byRef(String ref) => state.where((b) => b.ref == ref).firstOrNull;

  Booking? get active => state.where((b) => b.status.isActive).firstOrNull;

  void _update(String r, Booking Function(Booking b) change) {
    state = [for (final b in state) b.ref == r ? change(b) : b];
  }

  /// Called after the booking fee is paid. Returns the booking reference.
  String create(BookingDraft d, Customer c) {
    final r = 'SB-${_seq++}';
    final b = Booking(
      ref: r,
      customer: c,
      vehicle: d.vehicle!,
      service: d.service,
      address: Address(label: d.address!.label, line: d.address!.line, notes: d.notes),
      quote: d.quote!,
      status: BookingStatus.findingProvider,
      createdAt: DateTime.now(),
      scheduledAt: d.scheduledAt,
      waterAllowed: d.water,
      powerAllowed: d.power,
    );
    state = [b, ...state];
    unawaited(_simulate(r));
    return r;
  }

  bool _stopped(String r) {
    final b = byRef(r);
    return b == null || b.status == BookingStatus.cancelled;
  }

  /// Demo only: plays the provider side so the customer flow can be shown
  /// end to end. The backend replaces this with real-time events.
  Future<void> _simulate(String r) async {
    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
    await wait(3500);
    if (_stopped(r)) return;
    _update(r, (b) => b.copyWith(status: BookingStatus.accepted, provider: MockData.lwazi, etaMinutes: 7));
    await wait(3000);
    if (_stopped(r)) return;
    _update(r, (b) => b.copyWith(status: BookingStatus.travelling));
    for (var eta = 6; eta >= 1; eta--) {
      await wait(1500);
      if (_stopped(r)) return;
      _update(r, (b) => b.copyWith(etaMinutes: eta));
    }
    await wait(1500);
    if (_stopped(r)) return;
    _update(r, (b) => b.copyWith(status: BookingStatus.arrived, etaMinutes: 0));
    await wait(3000);
    if (_stopped(r)) return;
    _update(r, (b) => b.copyWith(status: BookingStatus.inProgress));
    final steps = byRef(r)!.service.checklist.length;
    for (var i = 1; i <= steps; i++) {
      await wait(1200);
      if (_stopped(r)) return;
      _update(r, (b) => b.copyWith(checklistDone: i));
    }
    await wait(1000);
    if (_stopped(r)) return;
    _update(r, (b) => b.copyWith(status: BookingStatus.awaitingApproval));
  }

  void cancel(String r, double refund) =>
      _update(r, (b) => b.copyWith(status: BookingStatus.cancelled, refundAmount: refund));

  void approve(String r) => _update(r, (b) => b.copyWith(status: BookingStatus.awaitingPayment));

  void pay(String r, PaymentMethod m, int tip) =>
      _update(r, (b) => b.copyWith(status: BookingStatus.completed, paymentMethod: m, tip: tip));

  void rate(String r, int stars, String review) => _update(r, (b) => b.copyWith(rating: stars, review: review));
}

final bookingsProvider = NotifierProvider<BookingsNotifier, List<Booking>>(BookingsNotifier.new);

final bookingProvider = Provider.family<Booking?, String>(
  (ref, r) => ref.watch(bookingsProvider).where((b) => b.ref == r).firstOrNull,
);
