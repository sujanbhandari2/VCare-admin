import 'package:vcare_admin/features/auth/data/models/login_response_model.dart';

class AuthVerifyOtpResultModel {
  AuthVerifyOtpResultModel({this.session});

  final LoginResponseModel? session;

  factory AuthVerifyOtpResultModel.fromJson(Map<String, dynamic> json) {
    final hasSessionFields = json.containsKey('access') ||
        json.containsKey('refresh') ||
        json.containsKey('user_id');

    return AuthVerifyOtpResultModel(
      session: hasSessionFields ? LoginResponseModel.fromJson(json) : null,
    );
  }
}
