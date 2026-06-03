import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class FieldValidator {
  /// Method to handle the field validation
  ///
  static String? handleValidation(
    String? s, {
    bool required = false,
    String? error,
    required BuildContext context,
  }) {
    if (!required) return null;

    if (s == null || s.trim().isEmpty) {
      return error ?? context.appLocalization.handle_validation_required;
    }

    return null;
  }

  /// Method to validate username
  ///
  static String? validateUsername(String? value,
      {required BuildContext context, String? invalidMessage}) {
    String pattern = r'(^[a-z][a-z0-9_.-]*\s*$)';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_username_required;
    } else if (!regExp.hasMatch(value)) {
      return invalidMessage ??
          context.appLocalization.validate_username_invalid;
    }
    return null;
  }

  /// Method to validate name
  ///
  static String? validateName(
      String? value, BuildContext context, String? invalidMessage) {
    String pattern = r'(^[a-zA-Z ]*$)';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_name_required;
    } else if (!regExp.hasMatch(value)) {
      return invalidMessage ?? context.appLocalization.validate_name_invalid;
    }

    if (value.trim().split(' ').length < 2) {
      return context.appLocalization.validate_name_full;
    }

    return null;
  }

  /// Method to validate first name
  ///
  static String? validateFirstName(String? value,
      {required BuildContext context, String? invalidMessage}) {
    String pattern = r'(^[a-zA-Z ]*$)';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_first_name_required;
    } else if (!regExp.hasMatch(value)) {
      return invalidMessage ??
          context.appLocalization.validate_first_name_invalid;
    }
    return null;
  }

  /// Method to validate mobile
  ///
  static String? validateMobile(String? value,
      {required BuildContext context}) {
    String pattern = r'(^[0-9]*$)';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_mobile_required;
    } else if (!regExp.hasMatch(value)) {
      return context.appLocalization.validate_mobile_invalid_digits;
    } else if (value.length != 10) {
      return context.appLocalization.validate_mobile_invalid_length;
    }
    return null;
  }

  /// Method to validate password
  ///
  static String? validatePassword(
    String? value, {
    required BuildContext context,
    bool complexValidation = false,
  }) {
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_password_empty;
    }

    if (value.length < 8) {
      return context.appLocalization.validate_password_length;
    }

    if (complexValidation && !isPasswordValid(value)) {
      return context.appLocalization.validate_password_complex;
    }

    return null;
  }

  /// Method to validate email
  ///
  static String? validateEmail(String? value, {required BuildContext context}) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))\s*$';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return context.appLocalization.validate_email_required;
    } else if (!regExp.hasMatch(value)) {
      return context.appLocalization.validate_email_invalid;
    } else {
      return null;
    }
  }

  /// Method to validate username or email
  ///
  static String? validateUsernameOrEmail(String? value,
      {required BuildContext context}) {
    final usernameValidationMessage = validateUsername(value, context: context);

    if (usernameValidationMessage == null) return null;

    return validateEmail(value, context: context);
  }

  /// Method to validate username or phone
  ///
  static String? validateUsernameOrPhone(String? value,
      {required BuildContext context}) {
    final usernameValidationMessage = validateUsername(value, context: context);

    if (usernameValidationMessage == null) return null;

    return validateMobile(value, context: context);
  }

  /// Method to validate email or phone
  ///
  static String? validateEmailOrPhone(String? value,
      {required BuildContext context}) {
    if (value == null || value.trim().isEmpty) {
      return context.appLocalization.validate_email_or_phone_required;
    }

    final emailValidationMessage = validateEmail(value, context: context);

    if (emailValidationMessage == null) return null;

    String pattern = r'(^[0-9]*$)';
    RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return context.appLocalization.validate_email_or_phone_invalid_email;
    }

    return validateMobile(value, context: context);
  }

  /// Method to validate age
  ///
  static String? validateAge(String? value, {required BuildContext context}) {
    if (value == null || value.trim().isEmpty) {
      return context.appLocalization.validate_age_required;
    }

    int age;
    try {
      age = int.parse(value);
    } catch (e) {
      return context.appLocalization.validate_age_invalid_number;
    }

    if (age < 10 || age > 120) {
      return context.appLocalization.validate_age_invalid_range;
    }

    // Return null if the age is valid
    return null;
  }

  /// Method to check if password valid
  ///
  static bool isPasswordValid(String? password) {
    if (password == null) {
      return false;
    }

    // Define regular expressions
    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    final uppercaseRegex = RegExp(r'[A-Z]');
    final lowercaseRegex = RegExp(r'[a-z]');
    final numberRegex = RegExp(r'[0-9]');

    // Check conditions
    final hasSpecialChar = specialCharRegex.hasMatch(password);
    final hasUppercase = uppercaseRegex.hasMatch(password);
    final hasLowercase = lowercaseRegex.hasMatch(password);
    final hasNumber = numberRegex.hasMatch(password);

    return hasSpecialChar && hasUppercase && hasLowercase && hasNumber;
  }

  /// Method to validate field
  ///
  static String? validateField(String? value,
      {String? message, required BuildContext context}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? context.appLocalization.validate_field_required;
    }

    return null;
  }

  /// Method to validate location fields in the sign up page
  ///
  static String? validateLocationField<T>(BuildContext context, T? value) {
    if (value != null) return null;

    return '${context.appLocalization.handle_validation_required}.';
  }
}
