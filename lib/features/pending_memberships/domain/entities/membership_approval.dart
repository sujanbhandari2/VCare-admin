/// Charge line item returned by `POST /enrollments/approve/compute`.
class MembershipApprovalLineItem {
  const MembershipApprovalLineItem({
    required this.enrollmentId,
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    required this.offeringName,
    this.enrolledAsLabel,
    this.enrolledAs,
    this.description,
    this.registrationFee = 0,
    this.discountAmount = 0,
    this.recurringFee = 0,
    this.totalAmount = 0,
    this.billingStartDate,
    this.billingEndDate,
  });

  final String enrollmentId;
  final String clientId;
  final String clientName;
  final String? clientEmail;
  final String offeringName;
  final String? enrolledAsLabel;
  final String? enrolledAs;
  final String? description;
  final double registrationFee;
  final double discountAmount;
  final double recurringFee;
  final double totalAmount;
  final DateTime? billingStartDate;
  final DateTime? billingEndDate;

  /// True for the line item that owns the billing obligation — parity with web
  /// `findBillingLineItem`.
  bool get ownsBilling {
    final value = enrolledAs?.trim().toUpperCase();
    return value == 'PRIMARY' || value == 'GROUP';
  }
}

class MembershipBillingPeriod {
  const MembershipBillingPeriod({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;
}

class MembershipApprovalPriceEntry {
  const MembershipApprovalPriceEntry({
    this.lineItems = const [],
    this.totalAmount = 0,
    this.currency = 'USD',
    this.billingInterval,
    this.recurringLineItems = const [],
    this.recurringTotalAmount = 0,
    this.nextExecutionDate,
  });

  final List<MembershipApprovalLineItem> lineItems;
  final double totalAmount;
  final String currency;
  final String? billingInterval;
  final List<MembershipApprovalLineItem> recurringLineItems;
  final double recurringTotalAmount;
  final DateTime? nextExecutionDate;
}

class MembershipApprovalSponsor {
  const MembershipApprovalSponsor({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
}

/// Recurring charge summary shown as an info banner before approving.
class MembershipRecurringSummary {
  const MembershipRecurringSummary({
    required this.totalAmount,
    this.nextExecutionDate,
    this.billingInterval,
  });

  final double totalAmount;
  final DateTime? nextExecutionDate;
  final String? billingInterval;
}

/// Pricing preview for an approval — `POST /enrollments/approve/compute`.
class MembershipApprovalCompute {
  const MembershipApprovalCompute({
    this.priceList = const [],
    this.billingInterval,
    this.missedBillingPeriods = const [],
    this.futureBillingPeriods = const [],
    this.sponsor,
  });

  final List<MembershipApprovalPriceEntry> priceList;
  final String? billingInterval;
  final List<MembershipBillingPeriod> missedBillingPeriods;
  final List<MembershipBillingPeriod> futureBillingPeriods;
  final MembershipApprovalSponsor? sponsor;

  bool get isEmpty => priceList.isEmpty;

  String get currency => priceList.isEmpty ? 'USD' : priceList.first.currency;

  List<MembershipApprovalLineItem> get lineItems => [
    for (final entry in priceList) ...entry.lineItems,
  ];

  double get grandTotal =>
      priceList.fold<double>(0, (sum, entry) => sum + entry.totalAmount);

  int get membershipCount =>
      lineItems.map((item) => item.enrollmentId).toSet().length;

  MembershipApprovalLineItem? get billingLineItem {
    final items = lineItems;
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.ownsBilling) return item;
    }
    return items.first;
  }

  /// Client charged for this approval — sponsor first, then the billing item.
  String? get billingClientId {
    final sponsorId = sponsor?.id.trim();
    if (sponsorId != null && sponsorId.isNotEmpty) return sponsorId;
    final itemClientId = billingLineItem?.clientId.trim();
    return itemClientId == null || itemClientId.isEmpty ? null : itemClientId;
  }

  String? get billingClientName {
    final sponsorName = sponsor?.name.trim();
    if (sponsorName != null && sponsorName.isNotEmpty) return sponsorName;
    final itemName = billingLineItem?.clientName.trim();
    return itemName == null || itemName.isEmpty ? null : itemName;
  }

  /// Earliest benefit start across line items, then future periods, then the
  /// last scheduled execution — parity with web `resolveBenefitStartDate`.
  DateTime resolveBenefitStartDate(DateTime fallback) {
    final itemDates =
        lineItems
            .map((item) => item.billingStartDate)
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (itemDates.isNotEmpty) return itemDates.first;

    final futureDates =
        futureBillingPeriods
            .map((period) => period.startDate)
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (futureDates.isNotEmpty) return futureDates.first;

    for (var i = priceList.length - 1; i >= 0; i -= 1) {
      final next = priceList[i].nextExecutionDate;
      if (next != null) return next;
    }

    return fallback;
  }

  /// Parity with web `resolveRecurringSummary`.
  MembershipRecurringSummary? get recurringSummary {
    for (var i = priceList.length - 1; i >= 0; i -= 1) {
      final entry = priceList[i];
      if (entry.recurringLineItems.isEmpty) continue;
      if (entry.recurringTotalAmount <= 0) continue;

      return MembershipRecurringSummary(
        totalAmount: entry.recurringTotalAmount,
        nextExecutionDate: entry.nextExecutionDate,
        billingInterval: entry.billingInterval ?? billingInterval,
      );
    }
    return null;
  }
}

/// Selectable billing start date — parity with web `BillingStartOption`.
class MembershipBillingStartOption {
  const MembershipBillingStartOption({
    required this.value,
    required this.label,
    required this.date,
    this.isToday = false,
  });

  /// `yyyy-MM-dd`, also the value posted to approve/compute.
  final String value;
  final String label;
  final DateTime date;
  final bool isToday;
}

/// Flattened approval row: a line item, or a period that has no line items.
class MembershipApprovalRow {
  const MembershipApprovalRow({
    this.item,
    this.periodTotal = 0,
    this.payPeriodStart,
    this.payPeriodEnd,
  });

  final MembershipApprovalLineItem? item;
  final double periodTotal;
  final DateTime? payPeriodStart;
  final DateTime? payPeriodEnd;

  bool get isEmptyPeriod => item == null;
}
