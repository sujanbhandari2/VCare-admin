class ForgotPasswordResponse {
  ForgotPasswordResponse({
    this.message,
    this.success = false,
  });

  final String? message;
  final bool success;

  ForgotPasswordResponse copyWith({
    String? message,
    bool? success,
  }) {
    return ForgotPasswordResponse(
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }

  @override
  String toString() {
    return "$message, $success ";
  }
}
