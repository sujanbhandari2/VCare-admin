/// Line item from `POST /enrollments/approve/compute` (amounts arrive as
/// decimal strings).
class MembershipApprovalLineItemModel {
  const MembershipApprovalLineItemModel({
    this.enrollmentId,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.offeringName,
    this.enrolledAsLabel,
    this.enrolledAs,
    this.description,
    this.registrationFee,
    this.discountAmount,
    this.recurringFee,
    this.totalAmount,
    this.billingStartDate,
    this.billingEndDate,
  });

  final String? enrollmentId;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? offeringName;
  final String? enrolledAsLabel;
  final String? enrolledAs;
  final String? description;
  final String? registrationFee;
  final String? discountAmount;
  final String? recurringFee;
  final String? totalAmount;
  final String? billingStartDate;
  final String? billingEndDate;

  factory MembershipApprovalLineItemModel.fromJson(Map<String, dynamic> json) {
    return MembershipApprovalLineItemModel(
      enrollmentId: json['enrollmentId']?.toString(),
      clientId: json['clientId']?.toString(),
      clientName: json['clientName']?.toString(),
      clientEmail: json['clientEmail']?.toString(),
      offeringName: json['offeringName']?.toString(),
      enrolledAsLabel: json['enrolledAsLabel']?.toString(),
      enrolledAs: json['enrolledAs']?.toString(),
      description: json['description']?.toString(),
      registrationFee: json['registrationFee']?.toString(),
      discountAmount: json['discountAmount']?.toString(),
      recurringFee: json['recurringFee']?.toString(),
      totalAmount:
          json['totalAmount']?.toString() ??
          json['totalImmediateAmount']?.toString(),
      billingStartDate: json['billingStartDate']?.toString(),
      billingEndDate: json['billingEndDate']?.toString(),
    );
  }
}

class MembershipBillingPeriodModel {
  const MembershipBillingPeriodModel({this.startDate, this.endDate});

  final String? startDate;
  final String? endDate;

  factory MembershipBillingPeriodModel.fromJson(Map<String, dynamic> json) {
    return MembershipBillingPeriodModel(
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }
}

class MembershipApprovalPriceEntryModel {
  const MembershipApprovalPriceEntryModel({
    this.lineItems = const [],
    this.totalAmount,
    this.currency,
    this.billingInterval,
    this.recurringLineItems = const [],
    this.recurringLineItemsTotalAmount,
    this.nextExecutionDate,
  });

  final List<MembershipApprovalLineItemModel> lineItems;
  final String? totalAmount;
  final String? currency;
  final String? billingInterval;
  final List<MembershipApprovalLineItemModel> recurringLineItems;
  final String? recurringLineItemsTotalAmount;
  final String? nextExecutionDate;

  factory MembershipApprovalPriceEntryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembershipApprovalPriceEntryModel(
      lineItems: _parseLineItems(json['lineItems']),
      totalAmount: json['totalAmount']?.toString(),
      currency: json['currency']?.toString(),
      billingInterval: json['billingInterval']?.toString(),
      recurringLineItems: _parseLineItems(json['recurringLineItems']),
      recurringLineItemsTotalAmount: json['recurringLineItemsTotalAmount']
          ?.toString(),
      nextExecutionDate: json['nextExecutionDate']?.toString(),
    );
  }

  static List<MembershipApprovalLineItemModel> _parseLineItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => MembershipApprovalLineItemModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }
}

class MembershipApprovalSponsorModel {
  const MembershipApprovalSponsorModel({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;

  factory MembershipApprovalSponsorModel.fromJson(Map<String, dynamic> json) {
    return MembershipApprovalSponsorModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

class MembershipApprovalComputeModel {
  const MembershipApprovalComputeModel({
    this.priceList = const [],
    this.billingInterval,
    this.missedBillingPeriods = const [],
    this.futureBillingPeriods = const [],
    this.sponsorDetails,
  });

  final List<MembershipApprovalPriceEntryModel> priceList;
  final String? billingInterval;
  final List<MembershipBillingPeriodModel> missedBillingPeriods;
  final List<MembershipBillingPeriodModel> futureBillingPeriods;
  final MembershipApprovalSponsorModel? sponsorDetails;

  factory MembershipApprovalComputeModel.fromJson(Map<String, dynamic> json) {
    final priceListRaw = json['priceList'];
    final sponsorRaw = json['sponsorDetails'];

    return MembershipApprovalComputeModel(
      priceList: priceListRaw is List
          ? priceListRaw
                .whereType<Map>()
                .map(
                  (entry) => MembershipApprovalPriceEntryModel.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const [],
      billingInterval: json['billingInterval']?.toString(),
      missedBillingPeriods: _parsePeriods(json['missedBillingPeriods']),
      futureBillingPeriods: _parsePeriods(json['futureBillingPeriods']),
      sponsorDetails: sponsorRaw is Map
          ? MembershipApprovalSponsorModel.fromJson(
              Map<String, dynamic>.from(sponsorRaw),
            )
          : null,
    );
  }

  static List<MembershipBillingPeriodModel> _parsePeriods(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (period) => MembershipBillingPeriodModel.fromJson(
            Map<String, dynamic>.from(period),
          ),
        )
        .toList(growable: false);
  }
}
