class RegisterResponseModel {
  RegisterResponseModel({
    this.message,
    this.success = false,
  });

  final String? message;
  final bool success;
  RegisterResponseModel copyWith({
    String? message,
    bool? success,
  }) {
    return RegisterResponseModel(
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json["message"] ??
          json['Message'] ??
          json['Details'] ??
          json['details'],
      success: json["success"] is bool ? json['success'] : false,
    );
  }

  Map<String, dynamic> toJson() => {
        "message": message,
        "success": success,
      };

  @override
  String toString() {
    return "$message, $success, ";
  }
}
