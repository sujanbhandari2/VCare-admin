class ForgotPasswordAccountModel {
  const ForgotPasswordAccountModel({
    required this.accountId,
    required this.displayName,
  });

  final String accountId;
  final String displayName;

  factory ForgotPasswordAccountModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordAccountModel(
      accountId: json['accountId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }
}
