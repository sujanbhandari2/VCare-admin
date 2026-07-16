class ClientNameModel {
  const ClientNameModel({this.firstName, this.middleName, this.lastName});

  final String? firstName;
  final String? middleName;
  final String? lastName;

  factory ClientNameModel.fromJson(Map<String, dynamic> json) {
    return ClientNameModel(
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
    );
  }
}

class ClientAddressModel {
  const ClientAddressModel({
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;

  factory ClientAddressModel.fromJson(Map<String, dynamic> json) {
    return ClientAddressModel(
      addressLine1: json['addressLine1']?.toString(),
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
    );
  }
}

class ClientContactModel {
  const ClientContactModel({
    this.email,
    this.phoneNumber,
    this.allowTextNotification,
  });

  final String? email;
  final String? phoneNumber;
  final bool? allowTextNotification;

  factory ClientContactModel.fromJson(Map<String, dynamic> json) {
    return ClientContactModel(
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      allowTextNotification: json['allowTextNotification'] == true,
    );
  }
}
