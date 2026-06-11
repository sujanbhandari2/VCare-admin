import 'package:vcare_admin/features/auth/data/models/forgot_password_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/login_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/register_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';

extension LoginResponseMapper on model.LoginResponseModel {
  AuthSession toEntity() {
    return AuthSession(
      refresh: refresh,
      access: access,
      userId: userId,
      email: email,
      username: username,
    );
  }
}

extension LoginResponseEntityMapper on AuthSession {
  model.LoginResponseModel toModel() {
    return model.LoginResponseModel(
      refresh: refresh,
      access: access,
      userId: userId,
      email: email,
      username: username,
    );
  }
}

extension RegisterResponseMapper on model.RegisterResponseModel {
  RegisterResponse toEntity() {
    return RegisterResponse(message: message, success: success);
  }
}

extension RegisterResponseEntityMapper on RegisterResponse {
  model.RegisterResponseModel toModel() {
    return model.RegisterResponseModel(message: message, success: success);
  }
}

extension ForgotPasswordResponseMapper on model.ForgotPasswordResponseModel {
  ForgotPasswordResponse toEntity() {
    return ForgotPasswordResponse(message: message, success: success);
  }
}

extension ForgotPasswordResponseEntityMapper on ForgotPasswordResponse {
  model.ForgotPasswordResponseModel toModel() {
    return model.ForgotPasswordResponseModel(
      message: message,
      success: success,
    );
  }
}
