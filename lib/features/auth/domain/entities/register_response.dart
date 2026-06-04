class RegisterResponse {
  RegisterResponse({this.message, this.success = false});

  final String? message;
  final bool success;

  RegisterResponse copyWith({String? message, bool? success}) {
    return RegisterResponse(
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }

  @override
  String toString() {
    return "$message, $success, ";
  }
}
