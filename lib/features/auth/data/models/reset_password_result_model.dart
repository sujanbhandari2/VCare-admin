class ResetPasswordResultModel {
  const ResetPasswordResultModel({this.message});

  final String? message;

  factory ResetPasswordResultModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResultModel(
      message:
          json['message']?.toString() ??
          json['Message']?.toString() ??
          json['details']?.toString(),
    );
  }
}
