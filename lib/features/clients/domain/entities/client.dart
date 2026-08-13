import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';

enum ClientGender { male, female, nonBinary }

enum ClientMembershipStatus { approved, submitted, completed, cancelled }

enum ClientPaymentMethodType {
  creditDebitCard,
  bankTransfer,
  cash,
  check,
  others,
}

enum ClientBillingStatus { paid, pending, overdue }

enum ClientTransactionStatus { succeeded, failed, onHold, pending }

enum ClientCaseStatus { requested, inProgress, resolved }

class ClientListItem implements LoadableListItem {
  const ClientListItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.avatarUrl,
    this.clientType = ClientListType.individual,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String avatarUrl;
  final ClientListType clientType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientListItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ClientMembership {
  const ClientMembership({
    required this.id,
    required this.plan,
    required this.carrier,
    required this.memberId,
    required this.status,
    required this.benefitDate,
    required this.cost,
    required this.costUnit,
    required this.tier,
    this.note,
    this.nextBillingDate,
  });

  final String id;
  final String plan;
  final String carrier;
  final String memberId;
  final ClientMembershipStatus status;
  final String benefitDate;
  final double cost;
  final String costUnit;
  final String tier;
  final String? note;
  final String? nextBillingDate;
}

class ClientDependent {
  const ClientDependent({
    required this.id,
    required this.name,
    required this.relation,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String relation;
  final String avatarUrl;
}

/// Agent affiliated with a client, embedded as `affiliateAgents[]` on the
/// client detail payload.
class ClientAffiliateAgent {
  const ClientAffiliateAgent({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.avatarUrl,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String avatarUrl;
  final String? email;
  final String? phone;
}

class ClientPaymentMethod {
  const ClientPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.last4,
    this.expMonth,
    this.expYear,
    this.isPrimary = false,
  });

  final String id;
  final ClientPaymentMethodType type;
  final String label;
  final String? last4;
  final int? expMonth;
  final int? expYear;
  final bool isPrimary;
}

class ClientBilling {
  const ClientBilling({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentMethodId,
  });

  final String id;
  final String description;
  final double amount;
  final String dueDate;
  final ClientBillingStatus status;
  final String? paymentMethodId;
}

class ClientTransaction implements LoadableListItem {
  const ClientTransaction({
    required this.id,
    required this.membershipTitle,
    required this.date,
    required this.dateTime,
    required this.payDate,
    required this.amount,
    required this.status,
    required this.reference,
    this.paymentMethodLabel,
    this.description,
    this.note,
    this.dependentName,
    this.dependentRelation,
  });

  final String id;
  final String membershipTitle;
  final String date;
  final String dateTime;
  final String payDate;
  final double amount;
  final ClientTransactionStatus status;
  final String reference;
  final String? paymentMethodLabel;
  final String? description;
  final String? note;
  final String? dependentName;
  final String? dependentRelation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ClientCase implements LoadableListItem {
  const ClientCase({
    required this.id,
    required this.caseId,
    required this.title,
    required this.status,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String caseId;
  final String title;
  final ClientCaseStatus status;
  final String updatedAt;
  final String createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientCase && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ClientFile implements LoadableListItem {
  const ClientFile({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadedAt,
    required this.url,
    required this.mime,
  });

  final String id;
  final String name;
  final String size;
  final String uploadedAt;
  final String url;
  final String mime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Client {
  const Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.dob,
    required this.location,
    required this.gender,
    required this.ssn,
    required this.memberships,
    required this.dependents,
    required this.paymentMethods,
    required this.billings,
    required this.transactions,
    required this.cases,
    required this.files,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String dob;
  final String location;
  final ClientGender gender;
  final String ssn;
  final List<ClientMembership> memberships;
  final List<ClientDependent> dependents;
  final List<ClientPaymentMethod> paymentMethods;
  final List<ClientBilling> billings;
  final List<ClientTransaction> transactions;
  final List<ClientCase> cases;
  final List<ClientFile> files;
}
