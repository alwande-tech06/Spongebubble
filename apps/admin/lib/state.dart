import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sb_core/sb_core.dart';

/// Admin sign-in (password + two-step code). Session only in the prototype.
final adminSignedInProvider = StateProvider<bool>((ref) => false);

class ApplicationsNotifier extends Notifier<List<ProviderApplication>> {
  @override
  List<ProviderApplication> build() => [...MockData.applications];

  void setStatus(String id, ApplicationStatus s) {
    state = [for (final a in state) a.id == id ? a.copyWith(status: s) : a];
  }
}

final applicationsProvider = NotifierProvider<ApplicationsNotifier, List<ProviderApplication>>(ApplicationsNotifier.new);

final adminBookingsProvider = Provider<List<Booking>>((ref) => MockData.todayBookings);

final providersListProvider = Provider<List<ServiceProvider>>((ref) => MockData.providers);
