import 'package:vcare_admin/features/auth/data/models/auth_identify_result_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/auth_verify_otp_result_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/forgot_password_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/login_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/register_response_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/auth_identify_account_model.dart'
    as model;
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_account.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/data/models/auth_login_result_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/auth_pre_auth_user_model.dart'
    as model;
import 'package:vcare_admin/features/auth/data/models/auth_setup_account_result_model.dart'
    as model;
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';

extension AuthIdentifyAccountMapper on model.AuthIdentifyAccountModel {
  AuthIdentifyAccount toEntity() {
    return AuthIdentifyAccount(
      accountId: accountId,
      displayName: displayName,
    );
  }
}

extension AuthIdentifyResultMapper on model.AuthIdentifyResultModel {
  AuthIdentifyResult toEntity() {
    return AuthIdentifyResult(
      userExists: userExists,
      multipleAccounts: multipleAccounts,
      atLeastOneAccountLoggedIn: atLeastOneAccountLoggedIn,
      otherPendingAccount: otherPendingAccount,
      otpSend: otpSend,
      accounts: accounts.map((account) => account.toEntity()).toList(),
    );
  }
}

extension AuthVerifyOtpResultMapper on model.AuthVerifyOtpResultModel {
  AuthVerifyOtpResult toEntity() {
    return AuthVerifyOtpResult(
      session: session?.toEntity(),
      registrationToken: registrationToken,
    );
  }
}

extension AuthLoginResultMapper on model.AuthLoginResultModel {
  AuthSession toEntity() {
    return AuthSession(
      refresh: session.refresh,
      access: session.access,
      email: session.email,
      username: session.username,
      profileId: profileId,
      tenantId: tenantId,
    );
  }
}

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

extension AuthPreAuthUserMapper on model.AuthPreAuthUserModel {
  AuthPreAuthUser toEntity() {
    return AuthPreAuthUser(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dob: dob,
      zipCode: zipCode,
      email: email,
      phone: phone,
    );
  }
}

extension AuthSetupAccountResultMapper on model.AuthSetupAccountResultModel {
  AuthSetupAccountResult toEntity() {
    return AuthSetupAccountResult(
      session: session.toEntity().copyWith(
        profileId: profileId,
        tenantId: tenantId,
      ),
      profileId: profileId,
      menu: menu,
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
