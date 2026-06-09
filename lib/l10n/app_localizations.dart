import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'VCare client'**
  String get app_name;

  /// No description provided for @app_name_dev.
  ///
  /// In en, this message translates to:
  /// **'VCare client - Dev'**
  String get app_name_dev;

  /// No description provided for @app_name_qa.
  ///
  /// In en, this message translates to:
  /// **'VCare client - QA'**
  String get app_name_qa;

  /// No description provided for @app_name_uat.
  ///
  /// In en, this message translates to:
  /// **'VCare client - UAT'**
  String get app_name_uat;

  /// No description provided for @tab_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tab_home;

  /// No description provided for @tab_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tab_map;

  /// No description provided for @tab_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tab_profile;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @middle_name.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middle_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgot_password;

  /// No description provided for @phone_or_username.
  ///
  /// In en, this message translates to:
  /// **'Phone / Username'**
  String get phone_or_username;

  /// No description provided for @phone_or_username_hint.
  ///
  /// In en, this message translates to:
  /// **'phone or username'**
  String get phone_or_username_hint;

  /// No description provided for @email_or_username.
  ///
  /// In en, this message translates to:
  /// **'Email / Username'**
  String get email_or_username;

  /// No description provided for @email_or_username_hint.
  ///
  /// In en, this message translates to:
  /// **'email or username'**
  String get email_or_username_hint;

  /// No description provided for @email_or_phone.
  ///
  /// In en, this message translates to:
  /// **'Email / Phone'**
  String get email_or_phone;

  /// No description provided for @email_or_phone_hint.
  ///
  /// In en, this message translates to:
  /// **'email or phone'**
  String get email_or_phone_hint;

  /// No description provided for @email_or_phone_label.
  ///
  /// In en, this message translates to:
  /// **'Enter email or phone associated with your account'**
  String get email_or_phone_label;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_account;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @validate_username_required.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get validate_username_required;

  /// No description provided for @validate_username_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid username'**
  String get validate_username_invalid;

  /// No description provided for @validate_name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validate_name_required;

  /// No description provided for @validate_name_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid name'**
  String get validate_name_invalid;

  /// No description provided for @validate_name_full.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get validate_name_full;

  /// No description provided for @validate_first_name_required.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get validate_first_name_required;

  /// No description provided for @validate_first_name_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid first name'**
  String get validate_first_name_invalid;

  /// No description provided for @validate_mobile_required.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get validate_mobile_required;

  /// No description provided for @validate_mobile_invalid_digits.
  ///
  /// In en, this message translates to:
  /// **'Mobile number should contain only digits'**
  String get validate_mobile_invalid_digits;

  /// No description provided for @validate_mobile_invalid_length.
  ///
  /// In en, this message translates to:
  /// **'Mobile number length is invalid'**
  String get validate_mobile_invalid_length;

  /// No description provided for @validate_password_empty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get validate_password_empty;

  /// No description provided for @validate_password_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validate_password_length;

  /// No description provided for @validate_password_complex.
  ///
  /// In en, this message translates to:
  /// **'Password must include letters, numbers, and special characters'**
  String get validate_password_complex;

  /// No description provided for @validate_password_not_match.
  ///
  /// In en, this message translates to:
  /// **'Password doesn\'t match'**
  String get validate_password_not_match;

  /// No description provided for @validate_email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validate_email_required;

  /// No description provided for @validate_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validate_email_invalid;

  /// No description provided for @validate_email_or_phone_required.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number is required'**
  String get validate_email_or_phone_required;

  /// No description provided for @validate_email_or_phone_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validate_email_or_phone_invalid_email;

  /// No description provided for @validate_age_required.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get validate_age_required;

  /// No description provided for @validate_age_invalid_number.
  ///
  /// In en, this message translates to:
  /// **'Age must be a number'**
  String get validate_age_invalid_number;

  /// No description provided for @validate_age_invalid_range.
  ///
  /// In en, this message translates to:
  /// **'Age must be within a valid range'**
  String get validate_age_invalid_range;

  /// No description provided for @validate_field_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validate_field_required;

  /// No description provided for @handle_validation_required.
  ///
  /// In en, this message translates to:
  /// **'Validation is required'**
  String get handle_validation_required;

  /// No description provided for @select_gender_error.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get select_gender_error;

  /// No description provided for @gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get gender_female;

  /// No description provided for @gender_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get gender_other;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @upload_photo.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get upload_photo;

  /// No description provided for @location_service_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Location Access Needed'**
  String get location_service_dialog_title;

  /// No description provided for @location_service_dialog_body.
  ///
  /// In en, this message translates to:
  /// **'To provide a better experience, we need access to your location.\n\nThis will enable us to show relevant content and enhance your interaction with our app.'**
  String get location_service_dialog_body;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started;

  /// No description provided for @update_available.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get update_available;

  /// No description provided for @update_now.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get update_now;

  /// No description provided for @update_available_desc.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to the latest version for the best experience.'**
  String get update_available_desc;

  /// No description provided for @update_later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get update_later;

  /// No description provided for @whats_new.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whats_new;

  /// No description provided for @updated_on.
  ///
  /// In en, this message translates to:
  /// **'Updated on'**
  String get updated_on;

  /// No description provided for @app_store.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get app_store;

  /// No description provided for @internet_connected.
  ///
  /// In en, this message translates to:
  /// **'Internet Connected'**
  String get internet_connected;

  /// No description provided for @apple_identity_token_getting_err.
  ///
  /// In en, this message translates to:
  /// **'Unable to get the identity token'**
  String get apple_identity_token_getting_err;

  /// No description provided for @google_access_token_getting_err.
  ///
  /// In en, this message translates to:
  /// **'Unable to get the access token'**
  String get google_access_token_getting_err;

  /// No description provided for @no_internet_connection.
  ///
  /// In en, this message translates to:
  /// **'No active internet connection'**
  String get no_internet_connection;

  /// No description provided for @request_handle_err.
  ///
  /// In en, this message translates to:
  /// **'Unable to handle your request'**
  String get request_handle_err;

  /// No description provided for @connectionTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get connectionTimeoutError;

  /// No description provided for @sendTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Unable to send data within timeframe'**
  String get sendTimeoutError;

  /// No description provided for @receiveTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Unable to receive data within timeframe'**
  String get receiveTimeoutError;

  /// No description provided for @badCertificateError.
  ///
  /// In en, this message translates to:
  /// **'Bad or expired certificate'**
  String get badCertificateError;

  /// No description provided for @badResponseError.
  ///
  /// In en, this message translates to:
  /// **'Bad response'**
  String get badResponseError;

  /// No description provided for @canceledRequestError.
  ///
  /// In en, this message translates to:
  /// **'Request is cancelled'**
  String get canceledRequestError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server. Check your internet connection.'**
  String get connectionError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settings_language_and_theme.
  ///
  /// In en, this message translates to:
  /// **'Language and theme'**
  String get settings_language_and_theme;

  /// No description provided for @settings_select_app_language.
  ///
  /// In en, this message translates to:
  /// **'Select app language'**
  String get settings_select_app_language;

  /// No description provided for @settings_theme_and_color_scheme.
  ///
  /// In en, this message translates to:
  /// **'Theme & Color Scheme'**
  String get settings_theme_and_color_scheme;

  /// No description provided for @settings_theme_and_seed_color.
  ///
  /// In en, this message translates to:
  /// **'Theme mode, text scale, and contrast'**
  String get settings_theme_and_seed_color;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @color_scheme.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get color_scheme;

  /// No description provided for @text_scale.
  ///
  /// In en, this message translates to:
  /// **'Text Scale'**
  String get text_scale;

  /// No description provided for @text_scale_small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get text_scale_small;

  /// No description provided for @text_scale_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get text_scale_default;

  /// No description provided for @text_scale_large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get text_scale_large;

  /// No description provided for @theme_mode_system_default.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get theme_mode_system_default;

  /// No description provided for @theme_mode_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_mode_light;

  /// No description provided for @theme_mode_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_mode_dark;

  /// No description provided for @color_scheme_style_tonal_spot.
  ///
  /// In en, this message translates to:
  /// **'Tonal Spot'**
  String get color_scheme_style_tonal_spot;

  /// No description provided for @color_scheme_style_fidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get color_scheme_style_fidelity;

  /// No description provided for @color_scheme_style_expressive.
  ///
  /// In en, this message translates to:
  /// **'Expressive'**
  String get color_scheme_style_expressive;

  /// No description provided for @color_scheme_generate_from_image.
  ///
  /// In en, this message translates to:
  /// **'Generate from image'**
  String get color_scheme_generate_from_image;

  /// No description provided for @color_scheme_source_image.
  ///
  /// In en, this message translates to:
  /// **'Color source image'**
  String get color_scheme_source_image;

  /// No description provided for @color_scheme_from_image_applied.
  ///
  /// In en, this message translates to:
  /// **'Color scheme generated from image'**
  String get color_scheme_from_image_applied;

  /// No description provided for @color_scheme_from_image_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate color scheme from image'**
  String get color_scheme_from_image_failed;

  /// No description provided for @contrast_mode.
  ///
  /// In en, this message translates to:
  /// **'Contrast Mode'**
  String get contrast_mode;

  /// No description provided for @contrast_mode_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get contrast_mode_normal;

  /// No description provided for @contrast_mode_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get contrast_mode_medium;

  /// No description provided for @contrast_mode_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get contrast_mode_high;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @item1.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Title 1'**
  String get item1;

  /// No description provided for @item2.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Title 2'**
  String get item2;

  /// No description provided for @item3.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Title 3'**
  String get item3;

  /// No description provided for @item4.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Title 4'**
  String get item4;

  /// No description provided for @item1_description.
  ///
  /// In en, this message translates to:
  /// **'This is the description of the on boarding title 1'**
  String get item1_description;

  /// No description provided for @item2_description.
  ///
  /// In en, this message translates to:
  /// **'This is the description of the on boarding title 2'**
  String get item2_description;

  /// No description provided for @item3_description.
  ///
  /// In en, this message translates to:
  /// **'This is the description of the on boarding title 3'**
  String get item3_description;

  /// No description provided for @item4_description.
  ///
  /// In en, this message translates to:
  /// **'This is the description of the on boarding title 4'**
  String get item4_description;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong;

  /// No description provided for @failed_to_load_more_items.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more items'**
  String get failed_to_load_more_items;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @no_items_found.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get no_items_found;

  /// No description provided for @sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get sign_out;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
