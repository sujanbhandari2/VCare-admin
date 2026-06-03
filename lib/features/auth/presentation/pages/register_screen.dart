import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_template/shared/widgets/image_upload_field.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_dropdown_field.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/utils/field_validator.dart';
import 'package:flutter_template/features/auth/domain/enums/gender.dart';
import 'package:flutter_template/features/auth/presentation/providers/register_request_state_provider.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  /// Register form key
  ///
  final _registerFormKey = GlobalKey<FormState>();

  /// Text Controllers
  ///

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Selected Gender
  ///
  Gender? _gender;

  /// Profile Image
  ///
  XFile? _profileImage;

  /// Method to handle on Gender change
  ///
  void _handleGenderChange(Gender? gender) {
    _gender = gender;
  }

  /// Method to handle on profile image selected
  ///
  void _handleProfileImageSelected(XFile? profile) {
    _profileImage = profile;
  }

  @override
  Widget build(BuildContext context) {
    final registerRequestState = ref.watch(registerRequestStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: .dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          _handlePop(context);
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Align(
                  alignment: context.isRtl ? .topRight : .topLeft,
                  child: Padding(
                    padding: .only(
                      left: context.isRtl ? 0.0 : 12.0,
                      right: context.isRtl ? 12.0 : 0.0,
                      top: context.padding.top,
                    ),
                    child: IconButton(
                      onPressed: context.pop,
                      icon: const Icon(Icons.arrow_back_ios, size: 18.0),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: context.height * 0.05),
                    Text(
                      context.appLocalization.sign_up,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontSize: 24.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 36.0)),
              SliverToBoxAdapter(
                child: Form(
                  key: _registerFormKey,
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      AuthTextField(
                        controller: _nameController,
                        label: context.appLocalization.name,
                        hint: context.appLocalization.name,
                        margin: const .fromLTRB(16.0, 0.0, 16.0, 0.0),
                        inputType: .name,
                        textInputAction: .next,
                        validator: (value) {
                          return FieldValidator.validateName(
                            value,
                            context,
                            null,
                          );
                        },
                        enabled: !registerRequestState.requesting,
                        required: true,
                      ),
                      AuthTextField(
                        controller: _phoneController,
                        label: context.appLocalization.phone,
                        hint: context.appLocalization.phone,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        inputType: .phone,
                        textInputAction: .next,
                        validator: (value) {
                          return FieldValidator.validateMobile(
                            value,
                            context: context,
                          );
                        },
                        enabled: !registerRequestState.requesting,
                        required: true,
                        maxLength: 10,
                      ),
                      AuthTextField(
                        controller: _usernameController,
                        label: context.appLocalization.username,
                        hint: context.appLocalization.username,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        inputType: .text,
                        textInputAction: .next,
                        validator: (value) {
                          return FieldValidator.validateUsername(
                            value,
                            context: context,
                          );
                        },
                        enabled: !registerRequestState.requesting,
                        required: true,
                      ),
                      AuthTextField(
                        controller: _emailController,
                        label: context.appLocalization.email,
                        hint: "example@email.com",
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        inputType: .emailAddress,
                        textInputAction: .next,
                        validator: (s) {
                          if (s == null || s.isEmpty) return null;
                          return FieldValidator.validateEmail(
                            s,
                            context: context,
                          );
                        },
                        enabled: !registerRequestState.requesting,
                      ),
                      AuthDropdownField<Gender>(
                        items: Gender.values,
                        label: context.appLocalization.gender,
                        hint: context.appLocalization.gender,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        validator: (gender) {
                          if (gender != null) return null;
                          return context.appLocalization.select_gender_error;
                        },
                        onChanged: _handleGenderChange,
                        enabled: !registerRequestState.requesting,
                        required: true,
                      ),
                      AuthTextField(
                        controller: _passwordController,
                        label: context.appLocalization.password,
                        hint: context.appLocalization.password,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        obscureText: true,
                        inputType: .emailAddress,
                        textInputAction: .next,
                        validator: (value) {
                          return FieldValidator.validatePassword(
                            value,
                            context: context,
                          );
                        },
                        enabled: !registerRequestState.requesting,
                        required: true,
                      ),
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: context.appLocalization.confirm_password,
                        hint: context.appLocalization.confirm_password,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 0.0),
                        obscureText: true,
                        inputType: .text,
                        textInputAction: .done,
                        validator: (s) {
                          if (s == null ||
                              s.isEmpty ||
                              s != _passwordController.text) {
                            return context
                                .appLocalization
                                .validate_password_not_match;
                          }
                          return null;
                        },
                        enabled: !registerRequestState.requesting,
                        required: true,
                      ),
                      ImageUploadField(
                        label: context.appLocalization.photo,
                        margin: const .fromLTRB(16.0, 12.0, 16.0, 8.0),
                        radius: const .circular(8.0),
                        onSelected: _handleProfileImageSelected,
                      ),
                    ],
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const .all(
              //       16.0,
              //     ),
              //     child: Text.rich(
              //       TextSpan(
              //         children: [
              //           TextSpan(
              //             text: context.appLocalization.by_continuing,
              //             style: context.textTheme.bodyMedium,
              //           ),
              //           TextSpan(
              //             text: context.appLocalization.user_agreement,
              //             style: context.textTheme.labelMedium?.copyWith(
              //               fontWeight: .bold,
              //               color: context.theme.primaryColor,
              //             ),
              //             recognizer: TapGestureRecognizer()
              //               ..onTap = () {
              //                 if (!registerRequestState.requesting) {
              //                   // Go to User Agreement
              //                 }
              //               },
              //           ),
              //           TextSpan(
              //             text: " &  ",
              //             style: context.textTheme.bodyMedium,
              //           ),
              //           TextSpan(
              //             text: context.appLocalization.privacy_policy,
              //             style: context.textTheme.labelMedium?.copyWith(
              //               fontWeight: .bold,
              //               color: context.theme.primaryColor,
              //             ),
              //             recognizer: TapGestureRecognizer()
              //               ..onTap = () {
              //                 if (!registerRequestState.requesting) {
              //                   // Go to privacy policy
              //                 }
              //               },
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const .only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: 16.0,
                  ),
                  child: AppButton.elevated(
                    onPressed: _handleRegisterButtonPressed,
                    text: context.appLocalization.register,
                    loading: registerRequestState.requesting,
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: Center(
              //     child: Padding(
              //       padding: const .all(
              //         16.0,
              //       ),
              //       child: Text.rich(
              //         TextSpan(
              //           children: [
              //             TextSpan(
              //               text: "Already have an account?  ",
              //               style: context.textTheme.bodyMedium,
              //             ),
              //             TextSpan(
              //               text: "Sign In",
              //               style: context.textTheme.labelMedium?.copyWith(
              //                 fontWeight: .bold,
              //               ),
              //               recognizer: TapGestureRecognizer()
              //                 ..onTap = () {
              //                   if (!registerRequestState.requesting) {
              //                     context
              //                         .goNamed(AppRouter.loginScreen.toPathName);x
              //                   }
              //                 },
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  void _handlePop(BuildContext context) {
    ref.invalidate(registerRequestStateProvider);
    context.pop();
  }

  /// Method to handle register button pressed
  ///
  Future<void> _handleRegisterButtonPressed() async {
    FocusScope.of(context).unfocus();

    if (_registerFormKey.currentState?.validate() == true) {
      final payloads = <String, dynamic>{};
      final medias = <String, dynamic>{};

      final name = _nameController.text.trim();
      final names = name.split(" ").toList();

      payloads['first_name'] = names.length <= 2
          ? names.first
          : names.sublist(0, names.length - 1);
      payloads['last_name'] = names.length > 1 ? names.last : '';

      payloads['phone'] = _phoneController.text.trim();
      if (_emailController.text.trim().isNotEmpty) {
        payloads['email'] = _emailController.text.trim().toLowerCase();
      }
      payloads['username'] = _usernameController.text.trim();
      payloads['gender'] = _gender?.label ?? '';
      payloads['password'] = _passwordController.text.trim();

      // Profile Image
      if (_profileImage != null) {
        medias['image'] = _profileImage?.path ?? '';
      }

      // Register
      ref
          .read(registerRequestStateProvider.notifier)
          .register(
            payloads: payloads,
            medias: medias,
            onCompleted: (response) {
              if (response?.success == true) {}
            },
          );
    }
  }

  /// Dispose
  ///
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
