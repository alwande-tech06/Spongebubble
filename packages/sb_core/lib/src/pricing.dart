import 'models.dart';

/// Pricing and refund rules from the client blueprint.
///
/// Values marked TBC are placeholders until the client confirms them.
/// Change them here only: every app reads from this class.
class Pricing {
  const Pricing._();

  /// Service catalogue in rands: service x vehicle category.
  static const Map<ServiceType, Map<VehicleCategory, int>> catalogue = {
    ServiceType.fullWash: {
      VehicleCategory.small: 250,
      VehicleCategory.medium: 350,
      VehicleCategory.large: 450,
    },
    ServiceType.internal: {
      VehicleCategory.small: 150,
      VehicleCategory.medium: 250,
      VehicleCategory.large: 350,
    },
    ServiceType.external: {
      VehicleCategory.small: 150,
      VehicleCategory.medium: 250,
      VehicleCategory.large: 350,
    },
  };

  /// Booking fee paid in the app before a washer is found. TBC.
  static const int bookingFee = 25;

  /// Travel fee rate per km (ZAR x km). TBC.
  static const int travelRatePerKm = 10;

  /// Balances at or above this must be paid by card in the app.
  static const int cardOnlyFrom = 500;

  /// Provider commission on the service price (commission plan). TBC.
  static const double commissionRate = 0.20;

  /// Weekly subscription fee (subscription plan). TBC.
  static const int subscriptionPerWeek = 60;

  /// A provider later than this lets the customer cancel for a full refund.
  static const Duration lateAfter = Duration(minutes: 15);

  /// Free cancellation window for scheduled bookings.
  static const Duration freeCancelBefore = Duration(hours: 12);

  static int servicePrice(ServiceType s, VehicleCategory c) => catalogue[s]![c]!;

  static int travelFee(double km) => (km * travelRatePerKm).round();

  static PriceQuote quote(ServiceType s, VehicleCategory c, double km) => PriceQuote(
        servicePrice: servicePrice(s, c),
        travelFee: travelFee(km),
        bookingFee: bookingFee,
        distanceKm: km,
      );

  static bool cardRequired(int amount) => amount >= cardOnlyFrom;

  /// Provider earnings for a completed job on the commission plan.
  /// Commission is charged on the service price; the travel fee and tips
  /// go to the provider in full.
  static int providerEarnings(PriceQuote q, {int tip = 0, ProviderPlan plan = ProviderPlan.commission}) {
    final commission = plan == ProviderPlan.commission ? (q.servicePrice * commissionRate).round() : 0;
    return q.servicePrice - commission + q.travelFee + tip;
  }

  /// Share of the booking fee refunded when the customer cancels.
  ///
  /// - before the washer starts travelling: 100%
  /// - washer travelling: 50%, or 100% if the washer is more than 15 min late
  /// - washer arrived or later: 0%
  /// - scheduled booking cancelled 12 hours or more before the slot: 100%
  /// - scheduled booking cancelled less than 12 hours before: 50% (TBC)
  /// - washer cancels, or nobody accepts: always 100% (handled by caller)
  static double customerCancelRefundShare(
    Booking b, {
    required DateTime now,
    bool providerLate = false,
  }) {
    if (b.status.index >= BookingStatus.arrived.index) return 0;
    if (b.status == BookingStatus.travelling) return providerLate ? 1 : 0.5;
    final at = b.scheduledAt;
    if (at != null && b.status.index <= BookingStatus.accepted.index) {
      return at.difference(now) >= freeCancelBefore ? 1 : 0.5; // TBC
    }
    return 1;
  }

  static double refundAmount(Booking b, {required DateTime now, bool providerLate = false}) =>
      b.quote.bookingFee * customerCancelRefundShare(b, now: now, providerLate: providerLate);
}
