class ForgotPasswordResponseModel {
  ForgotPasswordResponseModel({this.message, this.success = false});

  final String? message;
  final bool success;
  ForgotPasswordResponseModel copyWith({String? message, bool? success}) {
    return ForgotPasswordResponseModel(
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(
      message:
          json["message"] ??
          json['Message'] ??
          json['Details'] ??
          json['details'],
      success: json["success"] is bool ? json['success'] : false,
    );
  }

  Map<String, dynamic> toJson() => {"message": message, "success": success};

  @override
  String toString() {
    return "$message, $success ";
  }
}
