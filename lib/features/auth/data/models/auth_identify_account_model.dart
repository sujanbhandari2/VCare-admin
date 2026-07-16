class AuthIdentifyAccountModel {
  AuthIdentifyAccountModel({
    required this.accountId,
    required this.displayName,
  });

  final String accountId;
  final String displayName;

  factory AuthIdentifyAccountModel.fromJson(Map<String, dynamic> json) {
    return AuthIdentifyAccountModel(
      accountId: json['accountId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}
