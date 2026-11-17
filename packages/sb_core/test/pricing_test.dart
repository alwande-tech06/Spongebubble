import 'package:sb_core/sb_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 11, 16, 9);

  Booking b(BookingStatus s, {DateTime? at}) => MockData.booking(
        ref: 'T',
        vehicle: MockData.vehicles[0],
        service: ServiceType.fullWash,
        status: s,
        createdAt: now,
        scheduledAt: at,
      );

  test('quote: Full Wash, Medium, 4 km', () {
    final q = Pricing.quote(ServiceType.fullWash, VehicleCategory.medium, 4);
    expect(q.servicePrice, 350);
    expect(q.travelFee, 40);
    expect(q.balance, 390);
    expect(q.total, 390 + Pricing.bookingFee);
  });

  test('card is required from R500', () {
    expect(Pricing.cardRequired(499), isFalse);
    expect(Pricing.cardRequired(500), isTrue);
  });

  test('provider earnings: 20% commission on service only', () {
    final q = Pricing.quote(ServiceType.fullWash, VehicleCategory.medium, 4);
    expect(Pricing.providerEarnings(q), 350 - 70 + 40);
  });

  test('refunds by stage', () {
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.findingProvider), now: now), 1);
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.travelling), now: now), 0.5);
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.travelling), now: now, providerLate: true), 1);
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.arrived), now: now), 0);
  });

  test('scheduled: 12-hour window', () {
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.accepted, at: now.add(const Duration(hours: 13))), now: now), 1);
    expect(Pricing.customerCancelRefundShare(b(BookingStatus.accepted, at: now.add(const Duration(hours: 3))), now: now), 0.5);
  });

  test('rand format', () {
    expect(rand(3240), 'R3 240');
    expect(rand(12.5), 'R12.50');
    expect(rand(25), 'R25');
  });
}
