import 'package:vcare_admin/features/pending_memberships/data/models/membership_approval_model.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';

extension MembershipApprovalLineItemModelMapper
    on MembershipApprovalLineItemModel {
  MembershipApprovalLineItem toEntity() {
    return MembershipApprovalLineItem(
      enrollmentId: enrollmentId?.trim() ?? '',
      clientId: clientId?.trim() ?? '',
      clientName: clientName?.trim() ?? '',
      clientEmail: clientEmail?.trim().isNotEmpty == true
          ? clientEmail!.trim()
          : null,
      offeringName: offeringName?.trim().isNotEmpty == true
          ? offeringName!.trim()
          : 'Membership',
      enrolledAsLabel: enrolledAsLabel?.trim(),
      enrolledAs: enrolledAs?.trim(),
      description: description?.trim().isNotEmpty == true
          ? description!.trim()
          : null,
      registrationFee: parseMembershipAmount(registrationFee),
      discountAmount: parseMembershipAmount(discountAmount),
      recurringFee: parseMembershipAmount(recurringFee),
      totalAmount: parseMembershipAmount(totalAmount),
      billingStartDate: parseMembershipDate(billingStartDate),
      billingEndDate: parseMembershipDate(billingEndDate),
    );
  }
}

extension MembershipBillingPeriodModelMapper on MembershipBillingPeriodModel {
  MembershipBillingPeriod toEntity() {
    return MembershipBillingPeriod(
      startDate: parseMembershipDate(startDate),
      endDate: parseMembershipDate(endDate),
    );
  }
}

extension MembershipApprovalPriceEntryModelMapper
    on MembershipApprovalPriceEntryModel {
  MembershipApprovalPriceEntry toEntity() {
    return MembershipApprovalPriceEntry(
      lineItems: lineItems
          .map((item) => item.toEntity())
          .toList(growable: false),
      totalAmount: parseMembershipAmount(totalAmount),
      currency: currency?.trim().isNotEmpty == true
          ? currency!.trim().toUpperCase()
          : 'USD',
      billingInterval: billingInterval?.trim(),
      recurringLineItems: recurringLineItems
          .map((item) => item.toEntity())
          .toList(growable: false),
      recurringTotalAmount: parseMembershipAmount(
        recurringLineItemsTotalAmount,
      ),
      nextExecutionDate: parseMembershipDate(nextExecutionDate),
    );
  }
}

extension MembershipApprovalSponsorModelMapper
    on MembershipApprovalSponsorModel {
  MembershipApprovalSponsor? toEntity() {
    final sponsorId = id?.trim();
    if (sponsorId == null || sponsorId.isEmpty) return null;

    return MembershipApprovalSponsor(
      id: sponsorId,
      name: name?.trim() ?? '',
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      phoneNumber: phoneNumber?.trim().isNotEmpty == true
          ? phoneNumber!.trim()
          : null,
    );
  }
}

extension MembershipApprovalComputeModelMapper
    on MembershipApprovalComputeModel {
  MembershipApprovalCompute toEntity() {
    return MembershipApprovalCompute(
      priceList: priceList
          .map((entry) => entry.toEntity())
          .toList(growable: false),
      billingInterval: billingInterval?.trim(),
      missedBillingPeriods: missedBillingPeriods
          .map((period) => period.toEntity())
          .toList(growable: false),
      futureBillingPeriods: futureBillingPeriods
          .map((period) => period.toEntity())
          .toList(growable: false),
      sponsor: sponsorDetails?.toEntity(),
    );
  }
}
