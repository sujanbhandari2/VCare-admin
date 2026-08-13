// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'VCare client';

  @override
  String get app_name_dev => 'VCare client - Dev';

  @override
  String get app_name_qa => 'VCare client - QA';

  @override
  String get app_name_uat => 'VCare client - UAT';

  @override
  String get tab_home => 'Home';

  @override
  String get tab_map => 'Map';

  @override
  String get tab_profile => 'Profile';

  @override
  String get sign_in => 'Sign In';

  @override
  String get sign_up => 'Sign Up';

  @override
  String get register => 'Register';

  @override
  String get name => 'Name';

  @override
  String get first_name => 'First Name';

  @override
  String get middle_name => 'Middle Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get full_name => 'Full Name';

  @override
  String get username => 'Username';

  @override
  String get phone => 'Phone Number';

  @override
  String get email => 'Email';

  @override
  String get gender => 'Gender';

  @override
  String get photo => 'Photo';

  @override
  String get password => 'Password';

  @override
  String get confirm_password => 'Confirm Password';

  @override
  String get forgot_password => 'Forgot Password';

  @override
  String get phone_or_username => 'Phone / Username';

  @override
  String get phone_or_username_hint => 'phone or username';

  @override
  String get email_or_username => 'Email / Username';

  @override
  String get email_or_username_hint => 'email or username';

  @override
  String get email_or_phone => 'Email / Phone';

  @override
  String get email_or_phone_hint => 'email or phone';

  @override
  String get email_or_phone_label =>
      'Enter email or phone associated with your account';

  @override
  String get dont_have_account => 'Don\'t have an account?';

  @override
  String get create_account => 'Create Account';

  @override
  String get validate_username_required => 'Username is required';

  @override
  String get validate_username_invalid => 'Invalid username';

  @override
  String get validate_name_required => 'Name is required';

  @override
  String get validate_name_invalid => 'Invalid name';

  @override
  String get validate_name_full => 'Full name is required';

  @override
  String get validate_first_name_required => 'First name is required';

  @override
  String get validate_first_name_invalid => 'Invalid first name';

  @override
  String get validate_mobile_required => 'Mobile number is required';

  @override
  String get validate_mobile_invalid_digits =>
      'Mobile number should contain only digits';

  @override
  String get validate_mobile_invalid_length =>
      'Mobile number length is invalid';

  @override
  String get validate_password_empty => 'Password cannot be empty';

  @override
  String get validate_password_length =>
      'Password must be at least 8 characters';

  @override
  String get validate_password_complex =>
      'Password must include letters, numbers, and special characters';

  @override
  String get validate_password_not_match => 'Password doesn\'t match';

  @override
  String get validate_email_required => 'Email is required';

  @override
  String get validate_email_invalid => 'Invalid email';

  @override
  String get validate_email_or_phone_required =>
      'Email or phone number is required';

  @override
  String get validate_email_or_phone_invalid_email => 'Invalid email';

  @override
  String get validate_age_required => 'Age is required';

  @override
  String get validate_age_invalid_number => 'Age must be a number';

  @override
  String get validate_age_invalid_range => 'Age must be within a valid range';

  @override
  String get validate_field_required => 'This field is required';

  @override
  String get handle_validation_required => 'Validation is required';

  @override
  String get select_gender_error => 'Please select your gender';

  @override
  String get gender_male => 'Male';

  @override
  String get gender_female => 'Female';

  @override
  String get gender_other => 'Other';

  @override
  String get next => 'Next';

  @override
  String get continue_ => 'Continue';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get upload => 'Upload';

  @override
  String get upload_photo => 'Upload Photo';

  @override
  String get location_service_dialog_title => 'Location Access Needed';

  @override
  String get location_service_dialog_body =>
      'To provide a better experience, we need access to your location.\n\nThis will enable us to show relevant content and enhance your interaction with our app.';

  @override
  String get allow => 'Allow';

  @override
  String get cancel => 'Cancel';

  @override
  String get or => 'Or';

  @override
  String get get_started => 'Get Started';

  @override
  String get update_available => 'Update Available';

  @override
  String get update_now => 'Update Now';

  @override
  String get update_available_desc =>
      'A new version of the app is available. Please update to the latest version for the best experience.';

  @override
  String get update_later => 'Later';

  @override
  String get whats_new => 'What\'s new';

  @override
  String get updated_on => 'Updated on';

  @override
  String get app_store => 'App Store';

  @override
  String get internet_connected => 'Internet Connected';

  @override
  String get apple_identity_token_getting_err =>
      'Unable to get the identity token';

  @override
  String get google_access_token_getting_err =>
      'Unable to get the access token';

  @override
  String get no_internet_connection => 'No active internet connection';

  @override
  String get request_handle_err => 'Unable to handle your request';

  @override
  String get connectionTimeoutError => 'Connection timeout';

  @override
  String get sendTimeoutError => 'Unable to send data within timeframe';

  @override
  String get receiveTimeoutError => 'Unable to receive data within timeframe';

  @override
  String get badCertificateError => 'Bad or expired certificate';

  @override
  String get badResponseError => 'Bad response';

  @override
  String get canceledRequestError => 'Request is cancelled';

  @override
  String get connectionError =>
      'Unable to connect to server. Check your internet connection.';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get languages => 'Languages';

  @override
  String get settings => 'Settings';

  @override
  String get settings_language_and_theme => 'Language and theme';

  @override
  String get settings_select_app_language => 'Select app language';

  @override
  String get settings_theme_and_color_scheme => 'Organization Branding';

  @override
  String get settings_theme_and_seed_color =>
      'Colors, fonts, logos, and text size';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get color_scheme => 'Color Scheme';

  @override
  String get text_scale => 'Text Scale';

  @override
  String get text_scale_small => 'Small';

  @override
  String get text_scale_default => 'Default';

  @override
  String get text_scale_large => 'Large';

  @override
  String get theme_mode_system_default => 'System default';

  @override
  String get theme_mode_light => 'Light';

  @override
  String get theme_mode_dark => 'Dark';

  @override
  String get color_scheme_style_tonal_spot => 'Tonal Spot';

  @override
  String get color_scheme_style_fidelity => 'Fidelity';

  @override
  String get color_scheme_style_expressive => 'Expressive';

  @override
  String get color_scheme_generate_from_image => 'Generate from image';

  @override
  String get color_scheme_source_image => 'Color source image';

  @override
  String get color_scheme_from_image_applied =>
      'Color scheme generated from image';

  @override
  String get color_scheme_from_image_failed =>
      'Could not generate color scheme from image';

  @override
  String get contrast_mode => 'Contrast Mode';

  @override
  String get contrast_mode_normal => 'Normal';

  @override
  String get contrast_mode_medium => 'Medium';

  @override
  String get contrast_mode_high => 'High';

  @override
  String get branding_colors_section => 'Brand colors';

  @override
  String get branding_fonts_section => 'Font theme';

  @override
  String get branding_logos_section => 'Logos';

  @override
  String get branding_primary_color => 'Primary';

  @override
  String get branding_secondary_color => 'Secondary';

  @override
  String get branding_accent_color => 'Accent';

  @override
  String get branding_primary_logo => 'Primary logo';

  @override
  String get branding_icon_mark => 'Icon mark';

  @override
  String get branding_upload => 'Upload';

  @override
  String get branding_remove => 'Remove';

  @override
  String get branding_save => 'Save colors';

  @override
  String get branding_reset => 'Reset to defaults';

  @override
  String get branding_preview => 'Live preview';

  @override
  String get branding_saved => 'Branding updated';

  @override
  String get branding_save_failed => 'Could not update branding';

  @override
  String get branding_font_updated => 'Font theme updated';

  @override
  String get branding_invalid_color => 'Enter a valid 6-digit hex color';

  @override
  String get branding_custom_colors => 'Custom colors';

  @override
  String get branding_loading => 'Loading branding…';

  @override
  String get english => 'English';

  @override
  String get nepali => 'Nepali';

  @override
  String get bengali => 'Bengali';

  @override
  String get hindi => 'Hindi';

  @override
  String get spanish => 'Spanish';

  @override
  String get arabic => 'Arabic';

  @override
  String get french => 'French';

  @override
  String get german => 'German';

  @override
  String get russian => 'Russian';

  @override
  String get item1 => 'Onboarding Title 1';

  @override
  String get item2 => 'Onboarding Title 2';

  @override
  String get item3 => 'Onboarding Title 3';

  @override
  String get item4 => 'Onboarding Title 4';

  @override
  String get item1_description =>
      'This is the description of the on boarding title 1';

  @override
  String get item2_description =>
      'This is the description of the on boarding title 2';

  @override
  String get item3_description =>
      'This is the description of the on boarding title 3';

  @override
  String get item4_description =>
      'This is the description of the on boarding title 4';

  @override
  String get something_went_wrong => 'Something went wrong';

  @override
  String get failed_to_load_more_items => 'Failed to load more items';

  @override
  String get retry => 'Retry';

  @override
  String get no_items_found => 'No items found';

  @override
  String get sign_out => 'Sign Out';
}
