import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sb_core/sb_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Where the provider is in their account life cycle.
/// Only approved providers can go online and receive jobs.
enum AccountStage { signedOut, onboarding, inReview, approved }

class AccountNotifier extends Notifier<AccountStage> {
  static const _key = 'partner_stage';

  @override
  AccountStage build() => AccountStage.values[ref.read(prefsProvider).getInt(_key) ?? 0];

  Future<void> set(AccountStage s) async {
    await ref.read(prefsProvider).setInt(_key, s.index);
    state = s;
  }
}

final accountProvider = NotifierProvider<AccountNotifier, AccountStage>(AccountNotifier.new);

final meProvider = Provider<ServiceProvider>((ref) => MockData.lwazi);

// ---------------- Jobs ----------------
Booking _job(String r, Vehicle v, ServiceType s, String area, double km, DateTime? at, {String customer = 'Thandeka Mthembu'}) =>
    MockData.booking(
      ref: r,
      vehicle: v,
      service: s,
      status: BookingStatus.accepted,
      createdAt: DateTime.now(),
      scheduledAt: at,
      provider: MockData.lwazi,
      km: km,
      customer: Customer(id: 'c_$r', name: customer, mobile: '', email: ''),
      address: Address(label: area, line: area),
    );

class JobsNotifier extends Notifier<List<Booking>> {
  @override
  List<Booking> build() {
    final today = DateTime.now();
    DateTime at(int d, int h, [int m = 0]) => DateTime(today.year, today.month, today.day + d, h, m);
    return [
      _job('SB-104381', const Vehicle(id: 'a', make: 'VW', model: 'Polo', year: 2018, colour: 'Blue', registration: 'NU 12-904', category: VehicleCategory.small),
          ServiceType.external, 'Kloof', 3.4, at(0, 11, 30), customer: 'Ayanda Zulu'),
      _job('SB-104390', const Vehicle(id: 'b', make: 'Hyundai', model: 'i20', year: 2020, colour: 'Grey', registration: 'ND 81-220', category: VehicleCategory.small),
          ServiceType.fullWash, 'Gillitts', 5, at(0, 14), customer: 'Kayla Govender'),
      _job('SB-104402', const Vehicle(id: 'c', make: 'Ford', model: 'Ranger', year: 2022, colour: 'Grey', registration: 'NPN 71-441', category: VehicleCategory.medium),
          ServiceType.internal, 'Westville', 6, at(1, 9), customer: 'Sipho Ngcobo'),
    ];
  }

  void add(Booking b) => state = [b, ...state];

  void complete(String r) => state = state.where((b) => b.ref != r).toList();
}

final jobsProvider = NotifierProvider<JobsNotifier, List<Booking>>(JobsNotifier.new);

// ---------------- Online status and job offers ----------------
class OnlineNotifier extends Notifier<bool> {
  Timer? _offerTimer;

  @override
  bool build() {
    ref.onDispose(() => _offerTimer?.cancel());
    return false;
  }

  void toggle(bool on) {
    state = on;
    _offerTimer?.cancel();
    if (on) {
      // Demo: an offer arrives a few seconds after going online.
      _offerTimer = Timer(const Duration(seconds: 4), () {
        if (state) ref.read(offerProvider.notifier).state = _newOffer();
      });
    }
  }

  Booking _newOffer() => _job(
        'SB-104382',
        MockData.vehicles[0],
        ServiceType.fullWash,
        'Pinetown',
        2.2,
        null,
      );
}

final onlineProvider = NotifierProvider<OnlineNotifier, bool>(OnlineNotifier.new);

/// The offer currently on screen (null when none).
final offerProvider = StateProvider<Booking?>((ref) => null);

// ---------------- Active job workflow ----------------
enum JobStage { accepted, travelling, beforePhotos, confirm, checklist, afterPhotos, payment, done }

extension JobStageX on JobStage {
  String get title => switch (this) {
        JobStage.accepted => 'Job accepted',
        JobStage.travelling => 'Travelling',
        JobStage.beforePhotos => 'Before you start',
        JobStage.confirm => 'Confirm the job',
        JobStage.checklist => 'Checklist',
        JobStage.afterPhotos => 'After photos',
        JobStage.payment => 'Collect payment',
        JobStage.done => 'Job complete',
      };
}

class ActiveJob {
  const ActiveJob({
    required this.booking,
    this.stage = JobStage.accepted,
    this.beforePhotos = const {},
    this.afterPhotos = const {},
    this.checklist = const {},
    this.damageNoted = false,
    this.method = PaymentMethod.cash,
  });

  final Booking booking;
  final JobStage stage;
  final Set<String> beforePhotos;
  final Set<String> afterPhotos;
  final Set<int> checklist;
  final bool damageNoted;
  final PaymentMethod method;

  static const sides = ['Front', 'Back', 'Left side', 'Right side', 'Interior'];

  ActiveJob copyWith({
    JobStage? stage,
    Set<String>? beforePhotos,
    Set<String>? afterPhotos,
    Set<int>? checklist,
    bool? damageNoted,
    PaymentMethod? method,
  }) =>
      ActiveJob(
        booking: booking,
        stage: stage ?? this.stage,
        beforePhotos: beforePhotos ?? this.beforePhotos,
        afterPhotos: afterPhotos ?? this.afterPhotos,
        checklist: checklist ?? this.checklist,
        damageNoted: damageNoted ?? this.damageNoted,
        method: method ?? this.method,
      );
}

class ActiveJobNotifier extends Notifier<ActiveJob?> {
  @override
  ActiveJob? build() => null;

  void start(Booking b) => state = ActiveJob(booking: b);

  void update(ActiveJob Function(ActiveJob j) change) {
    final j = state;
    if (j != null) state = change(j);
  }

  void next() => update((j) => j.copyWith(stage: JobStage.values[(j.stage.index + 1).clamp(0, JobStage.values.length - 1)]));

  void finish() {
    final j = state;
    if (j == null) return;
    ref.read(jobsProvider.notifier).complete(j.booking.ref);
    ref.read(earningsProvider.notifier).add(Pricing.providerEarnings(j.booking.quote));
    state = null;
  }
}

final activeJobProvider = NotifierProvider<ActiveJobNotifier, ActiveJob?>(ActiveJobNotifier.new);

/// Net earnings this week in rands (demo starting value).
class EarningsNotifier extends Notifier<int> {
  @override
  int build() => 3240;

  void add(int amount) => state = state + amount;
}

final earningsProvider = NotifierProvider<EarningsNotifier, int>(EarningsNotifier.new);
