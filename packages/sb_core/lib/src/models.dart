/// Domain models. Names follow the ERD business rules
/// (CUSTOMER, VEHICLE, SERVICE, BOOKING, PROVIDER, PAYMENT, ...).

enum VehicleCategory { small, medium, large }

extension VehicleCategoryX on VehicleCategory {
  String get label => switch (this) {
        VehicleCategory.small => 'Small',
        VehicleCategory.medium => 'Medium',
        VehicleCategory.large => 'Large',
      };

  String get examples => switch (this) {
        VehicleCategory.small => 'Hatchbacks and sedans',
        VehicleCategory.medium => 'SUVs, bakkies and double cabs',
        VehicleCategory.large => 'Minibuses and 7-seaters',
      };
}

enum ServiceType { fullWash, internal, external }

extension ServiceTypeX on ServiceType {
  String get label => switch (this) {
        ServiceType.fullWash => 'Full Wash',
        ServiceType.internal => 'Internal Cleaning',
        ServiceType.external => 'External Cleaning',
      };

  String get description => switch (this) {
        ServiceType.fullWash => 'Complete interior and exterior clean',
        ServiceType.internal => 'Vacuum, surfaces and windows',
        ServiceType.external => 'Body, wheels, windows and finish',
      };

  int get minutes => switch (this) {
        ServiceType.fullWash => 60,
        ServiceType.internal => 40,
        ServiceType.external => 35,
      };

  /// Checklist the provider works through (shown to both sides).
  List<String> get checklist => switch (this) {
        ServiceType.fullWash => const [
            'Pre-rinse body',
            'Foam wash and hand wash',
            'Wheels and tyres',
            'Rinse and dry',
            'Exterior windows',
            'Vacuum seats and carpets',
            'Dashboard and door panels',
            'Interior windows and mats',
          ],
        ServiceType.internal => const [
            'Remove mats',
            'Vacuum seats and carpets',
            'Dashboard and door panels',
            'Interior windows',
            'Replace mats',
          ],
        ServiceType.external => const [
            'Pre-rinse body',
            'Foam wash and hand wash',
            'Wheels and tyres',
            'Rinse and dry',
            'Windows and tyre shine',
          ],
      };
}

/// Booking life cycle. Order matters: later values are later stages.
enum BookingStatus {
  pendingPayment,
  findingProvider,
  accepted,
  travelling,
  arrived,
  inProgress,
  awaitingApproval,
  awaitingPayment,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pendingPayment => 'Awaiting payment',
        BookingStatus.findingProvider => 'Finding a washer',
        BookingStatus.accepted => 'Washer accepted',
        BookingStatus.travelling => 'Washer on the way',
        BookingStatus.arrived => 'Washer arrived',
        BookingStatus.inProgress => 'Washing',
        BookingStatus.awaitingApproval => 'Check your car',
        BookingStatus.awaitingPayment => 'Awaiting payment',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };

  bool get isActive =>
      index >= BookingStatus.findingProvider.index &&
      index <= BookingStatus.awaitingPayment.index;

  /// Milestone index for the 5-step tracker (Accepted, Travelling,
  /// Arrived, Washing, Done).
  int get milestone => switch (this) {
        BookingStatus.pendingPayment || BookingStatus.findingProvider => -1,
        BookingStatus.accepted => 0,
        BookingStatus.travelling => 1,
        BookingStatus.arrived => 2,
        BookingStatus.inProgress => 3,
        BookingStatus.awaitingApproval ||
        BookingStatus.awaitingPayment ||
        BookingStatus.completed =>
          4,
        BookingStatus.cancelled => -1,
      };
}

enum PaymentMethod { card, cash }

enum ProviderType { individual, business }

enum ProviderPlan { commission, subscription }

enum ApplicationStatus { submitted, moreInfo, approved, rejected }

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;

  String get firstName => name.split(' ').first;
  String get initials =>
      name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.colour,
    required this.registration,
    required this.category,
    this.isDefault = false,
  });

  final String id;
  final String make;
  final String model;
  final int year;
  final String colour;
  final String registration;
  final VehicleCategory category;
  final bool isDefault;

  String get name => '$make $model';

  Vehicle copyWith({bool? isDefault}) => Vehicle(
        id: id,
        make: make,
        model: model,
        year: year,
        colour: colour,
        registration: registration,
        category: category,
        isDefault: isDefault ?? this.isDefault,
      );
}

class Address {
  const Address({
    required this.label,
    required this.line,
    this.notes = '',
    this.lat = -29.8167,
    this.lng = 30.8667,
  });

  final String label;
  final String line;
  final String notes;
  final double lat;
  final double lng;
}

class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.reviews,
    required this.areas,
    required this.plan,
    this.vehicle = '',
    this.online = false,
  });

  final String id;
  final String name;
  final ProviderType type;
  final double rating;
  final int reviews;
  final List<String> areas;
  final ProviderPlan plan;
  final String vehicle;
  final bool online;

  String get shortName {
    final parts = name.split(' ');
    return parts.length > 1 ? '${parts.first} ${parts[1][0]}.' : name;
  }

  String get initials =>
      name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
}

class ProviderApplication {
  const ProviderApplication({
    required this.id,
    required this.applicant,
    required this.type,
    required this.areas,
    required this.documents,
    required this.documentsTotal,
    required this.submitted,
    this.status = ApplicationStatus.submitted,
  });

  final String id;
  final String applicant;
  final ProviderType type;
  final List<String> areas;
  final int documents;
  final int documentsTotal;
  final DateTime submitted;
  final ApplicationStatus status;

  ProviderApplication copyWith({ApplicationStatus? status}) => ProviderApplication(
        id: id,
        applicant: applicant,
        type: type,
        areas: areas,
        documents: documents,
        documentsTotal: documentsTotal,
        submitted: submitted,
        status: status ?? this.status,
      );
}

/// Price shown before payment. Amounts are whole rands.
class PriceQuote {
  const PriceQuote({
    required this.servicePrice,
    required this.travelFee,
    required this.bookingFee,
    required this.distanceKm,
  });

  final int servicePrice;
  final int travelFee;
  final int bookingFee;
  final double distanceKm;

  /// Paid to the provider after the wash (card or cash).
  /// The booking fee is separate and is not deducted from this.
  int get balance => servicePrice + travelFee;

  int get total => balance + bookingFee;
}

class Booking {
  const Booking({
    required this.ref,
    required this.customer,
    required this.vehicle,
    required this.service,
    required this.address,
    required this.quote,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.waterAllowed = true,
    this.powerAllowed = true,
    this.provider,
    this.etaMinutes,
    this.checklistDone = 0,
    this.paymentMethod,
    this.tip = 0,
    this.rating,
    this.review = '',
    this.refundAmount,
  });

  final String ref;
  final Customer customer;
  final Vehicle vehicle;
  final ServiceType service;
  final Address address;
  final PriceQuote quote;
  final BookingStatus status;
  final DateTime createdAt;

  /// Null means an immediate ("wash now") booking.
  final DateTime? scheduledAt;
  final bool waterAllowed;
  final bool powerAllowed;
  final ServiceProvider? provider;
  final int? etaMinutes;
  final int checklistDone;
  final PaymentMethod? paymentMethod;
  final int tip;
  final int? rating;
  final String review;
  final double? refundAmount;

  bool get isImmediate => scheduledAt == null;

  Booking copyWith({
    BookingStatus? status,
    ServiceProvider? provider,
    int? etaMinutes,
    int? checklistDone,
    PaymentMethod? paymentMethod,
    int? tip,
    int? rating,
    String? review,
    double? refundAmount,
  }) =>
      Booking(
        ref: ref,
        customer: customer,
        vehicle: vehicle,
        service: service,
        address: address,
        quote: quote,
        status: status ?? this.status,
        createdAt: createdAt,
        scheduledAt: scheduledAt,
        waterAllowed: waterAllowed,
        powerAllowed: powerAllowed,
        provider: provider ?? this.provider,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        checklistDone: checklistDone ?? this.checklistDone,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        tip: tip ?? this.tip,
        rating: rating ?? this.rating,
        review: review ?? this.review,
        refundAmount: refundAmount ?? this.refundAmount,
      );
}

enum TicketStatus { open, investigating, awaitingResponse, resolved }

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.from,
    required this.bookingRef,
    required this.priority,
    required this.status,
    required this.updated,
  });

  final String id;
  final String subject;
  final String from;
  final String bookingRef;
  final String priority;
  final TicketStatus status;
  final String updated;
}
