import 'models.dart';
import 'pricing.dart';

/// Example data for the prototype. Replace with API calls in the
/// backend phase; screens only depend on the models.
class MockData {
  const MockData._();

  static const customer = Customer(
    id: 'cus_001',
    name: 'Thandeka Mthembu',
    mobile: '+27 82 555 0141',
    email: 'thandeka.m@gmail.com',
  );

  static const vehicles = [
    Vehicle(
      id: 'veh_001',
      make: 'Toyota',
      model: 'Fortuner',
      year: 2021,
      colour: 'White',
      registration: 'ND 456-789',
      category: VehicleCategory.medium,
      isDefault: true,
    ),
    Vehicle(
      id: 'veh_002',
      make: 'Kia',
      model: 'Picanto',
      year: 2019,
      colour: 'Red',
      registration: 'NPN 22-118',
      category: VehicleCategory.small,
    ),
  ];

  static const addresses = [
    Address(label: 'Home', line: '14 Ridge Rd, Pinetown, 3610', notes: 'Visitor bay 2. Gate code 4471, ring the bell.'),
    Address(label: 'Work', line: '3 Kingsmead Way, Durban, 4001', lat: -29.8530, lng: 31.0280),
  ];

  static const lwazi = ServiceProvider(
    id: 'prv_014',
    name: 'Lwazi Dlamini',
    type: ProviderType.individual,
    rating: 4.9,
    reviews: 86,
    areas: ['Kloof', 'Pinetown', 'Westville', 'Hillcrest', 'Gillitts'],
    plan: ProviderPlan.commission,
    vehicle: 'White Toyota Avanza · ND 77-302',
    online: true,
  );

  static const providers = [
    ServiceProvider(
      id: 'prv_003',
      name: 'Sizwe Wash Co.',
      type: ProviderType.business,
      rating: 4.8,
      reviews: 212,
      areas: ['Pinetown', 'Westville', 'Durban CBD'],
      plan: ProviderPlan.subscription,
      online: true,
    ),
    lwazi,
    ServiceProvider(
      id: 'prv_021',
      name: 'Clean Ride KZN',
      type: ProviderType.business,
      rating: 4.6,
      reviews: 98,
      areas: ['Umhlanga', 'Durban North'],
      plan: ProviderPlan.commission,
    ),
    ServiceProvider(
      id: 'prv_027',
      name: 'Bongani Zuma',
      type: ProviderType.individual,
      rating: 4.7,
      reviews: 41,
      areas: ['Chatsworth', 'Umlazi'],
      plan: ProviderPlan.commission,
      online: true,
    ),
  ];

  static final applications = [
    ProviderApplication(
      id: 'app_118',
      applicant: 'Sizwe Wash Co.',
      type: ProviderType.business,
      areas: const ['Pinetown', 'Westville'],
      documents: 5,
      documentsTotal: 5,
      submitted: DateTime(2026, 11, 13, 9, 10),
    ),
    ProviderApplication(
      id: 'app_121',
      applicant: 'Lwandle Mkhize',
      type: ProviderType.individual,
      areas: const ['Kloof', 'Gillitts'],
      documents: 3,
      documentsTotal: 3,
      submitted: DateTime(2026, 11, 14, 13, 40),
    ),
    ProviderApplication(
      id: 'app_124',
      applicant: 'Shine Squad (Pty) Ltd',
      type: ProviderType.business,
      areas: const ['Umhlanga', 'Ballito'],
      documents: 4,
      documentsTotal: 5,
      submitted: DateTime(2026, 11, 15, 8, 5),
    ),
  ];

  static Booking booking({
    required String ref,
    required Vehicle vehicle,
    required ServiceType service,
    required BookingStatus status,
    required DateTime createdAt,
    DateTime? scheduledAt,
    ServiceProvider? provider,
    double km = 4,
    Customer customer = MockData.customer,
    Address address = const Address(label: 'Home', line: '14 Ridge Rd, Pinetown, 3610'),
    int? rating,
    int tip = 0,
    PaymentMethod? method,
  }) =>
      Booking(
        ref: ref,
        customer: customer,
        vehicle: vehicle,
        service: service,
        address: address,
        quote: Pricing.quote(service, vehicle.category, km),
        status: status,
        createdAt: createdAt,
        scheduledAt: scheduledAt,
        provider: provider,
        rating: rating,
        tip: tip,
        paymentMethod: method,
      );

  static final pastBookings = [
    booking(
      ref: 'SB-103961',
      vehicle: vehicles[0],
      service: ServiceType.fullWash,
      status: BookingStatus.completed,
      createdAt: DateTime(2026, 11, 8, 9, 40),
      scheduledAt: DateTime(2026, 11, 8, 10),
      provider: lwazi,
      rating: 5,
      tip: 20,
      method: PaymentMethod.card,
    ),
    booking(
      ref: 'SB-103420',
      vehicle: vehicles[1],
      service: ServiceType.external,
      status: BookingStatus.completed,
      createdAt: DateTime(2026, 10, 30, 13),
      scheduledAt: DateTime(2026, 10, 30, 14),
      provider: providers[0],
      km: 2.5,
      rating: 4,
      method: PaymentMethod.cash,
    ),
    booking(
      ref: 'SB-102877',
      vehicle: vehicles[0],
      service: ServiceType.fullWash,
      status: BookingStatus.cancelled,
      createdAt: DateTime(2026, 10, 18, 20),
      scheduledAt: DateTime(2026, 10, 19, 9),
    ),
  ];

  /// Bookings as the admin portal sees them today.
  static final todayBookings = [
    booking(
      ref: 'SB-104382',
      vehicle: vehicles[0],
      service: ServiceType.fullWash,
      status: BookingStatus.inProgress,
      createdAt: DateTime(2026, 11, 15, 8, 40),
      provider: providers[0],
    ),
    booking(
      ref: 'SB-104381',
      vehicle: const Vehicle(id: 'v9', make: 'VW', model: 'Polo', year: 2018, colour: 'Blue', registration: 'NU 12-904', category: VehicleCategory.small),
      service: ServiceType.external,
      status: BookingStatus.travelling,
      createdAt: DateTime(2026, 11, 15, 9, 5),
      provider: lwazi,
      customer: const Customer(id: 'cus_014', name: 'Ayanda Zulu', mobile: '+27 71 555 0192', email: 'ayanda.zulu@outlook.com'),
      address: const Address(label: 'Home', line: '8 Abrey Rd, Kloof'),
      km: 3.4,
    ),
    booking(
      ref: 'SB-104380',
      vehicle: const Vehicle(id: 'v10', make: 'Toyota', model: 'Quantum', year: 2020, colour: 'Silver', registration: 'ND 330-212', category: VehicleCategory.large),
      service: ServiceType.fullWash,
      status: BookingStatus.findingProvider,
      createdAt: DateTime(2026, 11, 15, 9, 12),
      customer: const Customer(id: 'cus_031', name: 'Priya Naidoo', mobile: '+27 83 555 0177', email: 'priya.naidoo@icloud.com'),
      address: const Address(label: 'Work', line: '120 Anton Lembede St, Durban CBD'),
      km: 6,
    ),
    booking(
      ref: 'SB-104377',
      vehicle: const Vehicle(id: 'v11', make: 'Ford', model: 'Ranger', year: 2022, colour: 'Grey', registration: 'NPN 71-441', category: VehicleCategory.medium),
      service: ServiceType.internal,
      status: BookingStatus.completed,
      createdAt: DateTime(2026, 11, 15, 7, 30),
      provider: providers[3],
      customer: const Customer(id: 'cus_044', name: 'Sipho Ngcobo', mobile: '+27 76 555 0110', email: 'sipho.n@gmail.com'),
      address: const Address(label: 'Home', line: '27 Mangosuthu Hwy, Umlazi'),
      km: 5,
      method: PaymentMethod.cash,
    ),
  ];

  static const tickets = [
    SupportTicket(id: 'TK-5512', subject: 'Poor service claim', from: 'Fatima Essop · customer', bookingRef: 'SB-104366', priority: 'High', status: TicketStatus.investigating, updated: '12 min'),
    SupportTicket(id: 'TK-5511', subject: 'Payout not received', from: 'Thabo Mokoena · provider', bookingRef: 'Batch W45', priority: 'High', status: TicketStatus.open, updated: '40 min'),
    SupportTicket(id: 'TK-5509', subject: 'Charged twice for one booking', from: 'Ayanda Zulu · customer', bookingRef: 'SB-104201', priority: 'Medium', status: TicketStatus.awaitingResponse, updated: '2 h'),
    SupportTicket(id: 'TK-5502', subject: 'Washer arrived 30 min late', from: 'Priya Naidoo · customer', bookingRef: 'SB-104090', priority: 'Low', status: TicketStatus.resolved, updated: 'Yesterday'),
  ];
}
