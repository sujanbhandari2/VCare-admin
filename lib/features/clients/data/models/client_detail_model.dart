import 'client_shared_models.dart';

class ClientDetailProfileModel {
  const ClientDetailProfileModel({
    required this.id,
    this.clientType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.status,
    this.ssnLast4,
    this.address,
    this.userId,
    this.createdAt,
  });

  final String id;
  final String? clientType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? status;
  final String? ssnLast4;
  final ClientAddressModel? address;
  final String? userId;
  final String? createdAt;

  factory ClientDetailProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailProfileModel(
      id: json['id']?.toString() ?? '',
      clientType: json['clientType']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      status: json['status']?.toString(),
      ssnLast4: json['ssnLast4']?.toString(),
      address: json['address'] is Map<String, dynamic>
          ? ClientAddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      userId: json['userId']?.toString(),
      createdAt: json['createdAt']?.toString(),
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

class ClientDetailModel {
  const ClientDetailModel({
    required this.profile,
    required this.contact,
    this.memberCard,
  });

  final ClientDetailProfileModel profile;
  final ClientContactModel contact;
  final ClientMemberCardModel? memberCard;

  factory ClientDetailModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailModel(
      profile: ClientDetailProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
      contact: ClientContactModel.fromJson(
        json['contact'] as Map<String, dynamic>? ?? const {},
      ),
      memberCard: json['memberCard'] is Map<String, dynamic>
          ? ClientMemberCardModel.fromJson(
              json['memberCard'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
