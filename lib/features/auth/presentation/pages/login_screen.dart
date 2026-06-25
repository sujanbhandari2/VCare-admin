import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/shared/widgets/common_circular_icon_button.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/shared/utils/field_validator.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/auth/domain/enums/login_request_type.dart';
import 'package:vcare_admin/features/auth/presentation/providers/login_request_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Login form key
  ///
  final _loginFormKey = GlobalKey<FormState>();

  /// Text Controllers
  ///
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loginRequestState = ref.watch(loginRequestStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: .dark,
      ),
      child: Scaffold(
        // backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: context.height * 0.25),
              Text(
                context.appLocalization.sign_in,
                style: context.textTheme.titleLarge?.copyWith(fontSize: 24.0),
              ),
              const SizedBox(height: 36.0),
              Form(
                key: _loginFormKey,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    AuthTextField(
                      controller: _usernameController,
                      label: context.appLocalization.phone_or_username,
                      hint: context.appLocalization.phone_or_username_hint,
                      margin: const .fromLTRB(16.0, 16.0, 16.0, 0.0),
                      inputType: .emailAddress,
                      textInputAction: .next,
                      validator: (value) {
                        return FieldValidator.validateUsernameOrPhone(
                          value,
                          context: context,
                        );
                      },
                      enabled: !loginRequestState.requesting,
                    ),
                    AuthTextField(
                      controller: _passwordController,
                      label: context.appLocalization.password,
                      hint: context.appLocalization.password,
                      margin: const .fromLTRB(16.0, 16.0, 16.0, 0.0),
                      obscureText: true,
                      inputType: .emailAddress,
                      textInputAction: .next,
                      validator: (value) {
                        return FieldValidator.validatePassword(
                          value,
                          context: context,
                        );
                      },
                      enabled: !loginRequestState.requesting,
                    ),
                    Align(
                      alignment: .centerRight,
                      child: Padding(
                        padding: const .all(16.0),
                        child: GestureDetector(
                          onTap: () {
                            if (!loginRequestState.requesting) {
                              context.pushNamed(
                                AppRouter.forgotPassword.toPathName,
                              );
                            }
                          },
                          child: Text(
                            context.appLocalization.forgot_password,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.isDarkTheme
                                  ? context.theme.primaryColorLight
                                  : context.theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const .only(
                  left: 16.0,
                  right: 16.0,
                  top: 12.0,
                  // bottom: 16.0,
                ),
                child: AppButton.elevated(
                  onPressed: !loginRequestState.requesting
                      ? _handleLoginButtonPressed
                      : null,
                  text: context.appLocalization.sign_in,
                  loading:
                      loginRequestState.requesting &&
                      loginRequestState.type == .password,
                  uppercase: false,
                ),
              ),
              Padding(
                padding: const .all(16.0),
                child: Text(context.appLocalization.or),
              ),
              Row(
                mainAxisSize: .max,
                mainAxisAlignment: .center,
                children: [
                  CommonCircularIconButton(
                    icon: "assets/svg/google.svg",
                    loading:
                        loginRequestState.requesting &&
                        loginRequestState.type == .google,
                    onClick: !loginRequestState.requesting
                        ? _handleGoogleLoginButtonPressed
                        : null,
                  ),
                  const SizedBox(width: 16.0),
                  CommonCircularIconButton(
                    icon: "assets/svg/apple.svg",
                    loading:
                        loginRequestState.requesting &&
                        loginRequestState.type == .apple,
                    onClick: !loginRequestState.requesting
                        ? _handleAppleLoginButtonPressed
                        : null,
                  ),
                ],
              ),
              Padding(
                padding: const .all(16.0),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "${context.appLocalization.dont_have_account}  ",
                          style: context.textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: context.appLocalization.create_account,
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: .bold,
                            color: context.isDarkTheme
                                ? context.theme.primaryColorLight
                                : context.theme.primaryColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              if (!loginRequestState.requesting) {
                                context.pushNamed(
                                  AppRouter.register.toPathName,
                                );
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Method to handle login button pressed
  ///
  Future<void> _handleLoginButtonPressed() async {
    await _handleLogin(LoginRequestType.password);
  }

  /// Method to handle google login button pressed
  ///
  Future<void> _handleGoogleLoginButtonPressed() async {
    await _handleLogin(LoginRequestType.google);
  }

  /// Method to handle apple login button pressed
  ///
  Future<void> _handleAppleLoginButtonPressed() async {
    await _handleLogin(LoginRequestType.apple);
  }

  /// Method to handle login
  ///
  Future<void> _handleLogin(LoginRequestType type) async {
    FocusScope.of(context).unfocus();

    if (type == LoginRequestType.password) {
      final validated = _loginFormKey.currentState?.validate() == true;
      if (!validated) return;
    }

    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    await ref
        .refresh(loginRequestStateProvider.notifier)
        .login(
          payloads: <String, dynamic>{'email': email, 'password': password},
          onSuccess: (session) {
            _handleOnLoginSuccess();
          },
          onError: (error) {
            Fluttertoast.showToast(
              msg: error ?? context.appLocalization.something_went_wrong,
            );
          },
          type: type,
        );
  }

  void _handleOnLoginSuccess() {
    //invalidates the current state and works from start
    ref.invalidate(userLoggedInStateProvider);

    //fetching profile
    ref.read(authMeStateProvider.notifier).fetchMe();

    // If login success, navigate to home screen
    context.goNamed(AppRouter.home.toPathName);
  }

  /// Dispose
  ///
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
