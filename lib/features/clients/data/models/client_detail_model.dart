import 'client_shared_models.dart';

class ClientDetailProfileModel {
  const ClientDetailProfileModel({
    required this.id,
    this.clientType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.companyName,
    this.contactFirstName,
    this.contactLastName,
    this.dateOfBirth,
    this.gender,
    this.status,
    this.ssnLast4,
    this.address,
    this.userId,
    this.createdAt,
    this.profilePreviewLink,
  });

  final String id;
  final String? clientType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? companyName;
  final String? contactFirstName;
  final String? contactLastName;
  final String? dateOfBirth;
  final String? gender;
  final String? status;
  final String? ssnLast4;
  final ClientAddressModel? address;
  final String? userId;
  final String? createdAt;
  final String? profilePreviewLink;

  bool get isGroup => clientType?.toUpperCase() == 'GROUP';

  factory ClientDetailProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailProfileModel(
      id: json['id']?.toString() ?? '',
      clientType: json['clientType']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      companyName: json['companyName']?.toString(),
      contactFirstName: json['contactFirstName']?.toString(),
      contactLastName: json['contactLastName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      status: json['status']?.toString(),
      ssnLast4: json['ssnLast4']?.toString(),
      address: json['address'] is Map<String, dynamic>
          ? ClientAddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      userId: json['userId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
    );
  }
}

class ClientMemberCardModel {
  const ClientMemberCardModel({
    this.cardLast4,
    this.cardBrand,
    this.cardExpMonth,
    this.cardExpYear,
  });

  final String? cardLast4;
  final String? cardBrand;
  final int? cardExpMonth;
  final int? cardExpYear;

  factory ClientMemberCardModel.fromJson(Map<String, dynamic> json) {
    return ClientMemberCardModel(
      cardLast4: json['cardLast4']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      cardExpMonth: _asInt(json['cardExpMonth']),
      cardExpYear: _asInt(json['cardExpYear']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class ClientAffiliateAgentModel {
  const ClientAffiliateAgentModel({
    required this.id,
    this.agentType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.agentCode,
    this.status,
    this.profilePreviewLink,
    this.agencyGroupName,
  });

  final String id;
  final String? agentType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? agentCode;
  final String? status;
  final String? profilePreviewLink;
  final String? agencyGroupName;

  bool get isAgencyGroup =>
      agentType?.toUpperCase() == 'AGENCY_GROUP' || agencyGroupName != null;

  factory ClientAffiliateAgentModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] is Map
        ? Map<String, dynamic>.from(json['name'] as Map)
        : const <String, dynamic>{};
    final contact = json['contact'] is Map
        ? Map<String, dynamic>.from(json['contact'] as Map)
        : const <String, dynamic>{};
    final agencyGroup = json['agencyGroup'];

    return ClientAffiliateAgentModel(
      id: json['id']?.toString() ?? '',
      agentType: json['agentType']?.toString(),
      firstName: name['firstName']?.toString() ?? json['firstName']?.toString(),
      middleName:
          name['middleName']?.toString() ?? json['middleName']?.toString(),
      lastName: name['lastName']?.toString() ?? json['lastName']?.toString(),
      email: contact['email']?.toString() ?? json['email']?.toString(),
      phoneNumber:
          contact['phoneNumber']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone']?.toString(),
      agentCode: json['agentCode']?.toString(),
      status: json['status']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
      agencyGroupName: agencyGroup is Map
          ? agencyGroup['name']?.toString()
          : agencyGroup?.toString(),
    );
  }
}

class ClientDetailModel {
  const ClientDetailModel({
    required this.profile,
    required this.contact,
    this.memberCard,
    this.affiliateAgents = const [],
  });

  final ClientDetailProfileModel profile;
  final ClientContactModel contact;
  final ClientMemberCardModel? memberCard;
  final List<ClientAffiliateAgentModel> affiliateAgents;

  static List<ClientAffiliateAgentModel> _parseAffiliateAgents(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => ClientAffiliateAgentModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((agent) => agent.id.isNotEmpty)
        .toList();
  }

  factory ClientDetailModel.fromJson(Map<String, dynamic> json) {
    // Legacy agent envelope: { profile, contact, memberCard }
    if (json['profile'] is Map) {
      return ClientDetailModel(
        profile: ClientDetailProfileModel.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map),
        ),
        contact: ClientContactModel.fromJson(
          Map<String, dynamic>.from(
            (json['contact'] as Map?) ?? const {},
          ),
        ),
        memberCard: json['memberCard'] is Map
            ? ClientMemberCardModel.fromJson(
                Map<String, dynamic>.from(json['memberCard'] as Map),
              )
            : null,
        affiliateAgents: _parseAffiliateAgents(json['affiliateAgents']),
      );
    }

    final clientType = json['clientType']?.toString();
    final isGroup = clientType?.toUpperCase() == 'GROUP';

    // Web individual: basicInfo / contactInfo / address
    final basicInfo = json['basicInfo'] is Map
        ? Map<String, dynamic>.from(json['basicInfo'] as Map)
        : null;
    final contactInfo = json['contactInfo'] is Map
        ? Map<String, dynamic>.from(json['contactInfo'] as Map)
        : json['contact'] is Map
        ? Map<String, dynamic>.from(json['contact'] as Map)
        : <String, dynamic>{};

    final address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : null;

    final nameBlock = json['name'] is Map
        ? Map<String, dynamic>.from(json['name'] as Map)
        : null;

    String? companyName = json['companyName']?.toString();
    String? contactFirstName = json['contactFirstName']?.toString();
    String? contactLastName = json['contactLastName']?.toString();
    if (nameBlock != null) {
      companyName ??= nameBlock['companyName']?.toString();
      contactFirstName ??= nameBlock['contactFirstName']?.toString();
      contactLastName ??= nameBlock['contactLastName']?.toString();
    }

    return ClientDetailModel(
      profile: ClientDetailProfileModel(
        id: json['id']?.toString() ?? '',
        clientType: clientType,
        firstName:
            basicInfo?['firstName']?.toString() ??
            json['firstName']?.toString() ??
            nameBlock?['firstName']?.toString() ??
            contactFirstName,
        middleName:
            basicInfo?['middleName']?.toString() ??
            json['middleName']?.toString() ??
            nameBlock?['middleName']?.toString(),
        lastName:
            basicInfo?['lastName']?.toString() ??
            json['lastName']?.toString() ??
            nameBlock?['lastName']?.toString() ??
            contactLastName,
        companyName: companyName,
        contactFirstName: contactFirstName,
        contactLastName: contactLastName,
        dateOfBirth:
            basicInfo?['dateOfBirth']?.toString() ??
            json['dateOfBirth']?.toString(),
        gender: basicInfo?['gender']?.toString() ?? json['gender']?.toString(),
        status: json['status']?.toString(),
        ssnLast4:
            basicInfo?['ssnLast4']?.toString() ?? json['ssnLast4']?.toString(),
        address: address != null
            ? ClientAddressModel.fromJson(address)
            : null,
        userId: json['userId']?.toString() ??
            (json['user'] is Map
                ? (json['user'] as Map)['id']?.toString()
                : null),
        createdAt:
            json['createdAt']?.toString() ?? json['joinedAt']?.toString(),
        profilePreviewLink: json['profilePreviewLink']?.toString(),
      ),
      contact: ClientContactModel.fromJson({
        ...contactInfo,
        if (json['email'] != null) 'email': json['email'],
        if (json['phone'] != null) 'phone': json['phone'],
        if (json['phoneNumber'] != null) 'phoneNumber': json['phoneNumber'],
        if (isGroup && contactInfo['email'] == null && json['email'] != null)
          'email': json['email'],
      }),
      memberCard: json['memberCard'] is Map
          ? ClientMemberCardModel.fromJson(
              Map<String, dynamic>.from(json['memberCard'] as Map),
            )
          : null,
      affiliateAgents: _parseAffiliateAgents(json['affiliateAgents']),
    );
  }

  static bool isValidApiData(dynamic data) {
    if (data is! Map) return false;
    if (data['profile'] is Map) return true;
    if (data['id'] != null) return true;
    return false;
  }
}
