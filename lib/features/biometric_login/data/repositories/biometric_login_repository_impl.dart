import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/auth/data/auth_api_headers.dart';
import 'package:vcare_admin/features/auth/data/auth_device_id.dart';
import 'package:vcare_admin/features/auth/data/models/admin_login_result_model.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';
import 'package:vcare_admin/features/biometric_login/data/models/biometric_challenge_model.dart';
import 'package:vcare_admin/features/biometric_login/data/models/biometric_credential_model.dart';
import 'package:vcare_admin/features/biometric_login/data/models/biometric_enrollment_response_model.dart';
import 'package:vcare_admin/features/biometric_login/data/services/biometric_credential_local_store.dart';
import 'package:vcare_admin/features/biometric_login/data/services/biometric_crypto_service.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/features/biometric_login/domain/repositories/biometric_login_repository.dart';
import 'package:vcare_admin/shared/utils/logger.dart';

class BiometricLoginRepositoryImpl implements BiometricLoginRepository {
  BiometricLoginRepositoryImpl(
    this.apiClient,
    this.storage, {
    BiometricCredentialLocalStore? credentialStore,
    BiometricCryptoService? cryptoService,
  })  : _credentialStore =
            credentialStore ?? SecureBiometricCredentialLocalStore(),
        _cryptoService = cryptoService ?? const BiometricCryptoService();

  final ApiClient apiClient;
  final StorageService storage;
  final BiometricCredentialLocalStore _credentialStore;
  final BiometricCryptoService _cryptoService;

  static const String _defaultUserType = 'CLIENT';

  @override
  Future<EitherResponseOrException<BiometricLoginStatus>> fetchStatus({
    String? accountId,
  }) {
    return safeNetworkCall(() async {
      final credential = await _readCredential();
      if (credential == null) {
        return BiometricLoginStatus.disabled;
      }

      final scopedAccountId = accountId?.trim();
      if (scopedAccountId != null && scopedAccountId.isNotEmpty) {
        if (credential.accountId.trim() != scopedAccountId) {
          // Another account owns the single device credential.
          return BiometricLoginStatus.disabled;
        }
      }

      return credential.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<BiometricLoginStatus>> enroll({
    required String accessToken,
    required String accountId,
    String? accountEmail,
    String? userType,
    String? deviceName,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (kIsWeb) {
        throw UnsupportedError('Biometric enrollment is not supported on web.');
      }

      final resolvedAccountId = accountId.trim();
      if (resolvedAccountId.isEmpty) {
        throw HttpException(
          title: 'Biometric enrollment failed',
          message: 'A valid account id is required to enroll biometrics.',
        );
      }

      final existing = await _readCredential();
      final deviceId = await getOrCreateDeviceId(storage);
      final resolvedDeviceName = deviceName?.trim().isNotEmpty == true
          ? deviceName!.trim()
          : await _resolveDeviceName();
      final biometricType = await _currentBiometricType();
      final resolvedUserType = _resolveUserType(userType);
      final keyPair = await _cryptoService.generateKeyPair();
      final headers = await AuthApiHeaders.biometric(
        storage: storage,
        userType: resolvedUserType,
      );

      try {
        final response = await apiClient.post(
          ApiEndpoints.authBiometricEnroll,
          JsonRequestBody({
            'publicKey': keyPair.publicKeyBase64,
            'biometricType': biometricType,
            if (resolvedDeviceName != null && resolvedDeviceName.isNotEmpty)
              'deviceName': resolvedDeviceName,
          }),
          cancelToken: cancelToken,
          isAuthenticated: false,
          additionalHeaders: {
            ...headers,
            'Authorization': 'Bearer $accessToken',
          },
        );

        final model = ResponseValidator.parse(
          response,
          (data) => BiometricEnrollmentResponseModel.fromJson(
            data as Map<String, dynamic>,
          ),
          dataValidator: (data) => data is Map,
        );

        if (!model.enrolled || model.device == null) {
          throw HttpException(
            title: 'Biometric enrollment failed',
            message: 'The server did not confirm biometric enrollment.',
            requestMethod: response.requestOptions.method,
            requestUri: response.requestOptions.uri,
            responseData: response.data,
          );
        }

        final credential = BiometricCredentialModel(
          version: BiometricCredentialModel.currentVersion,
          accountId: resolvedAccountId,
          accountEmail: accountEmail?.trim(),
          enrollmentId: model.device?.id,
          deviceId: deviceId,
          publicKeyBase64: keyPair.publicKeyBase64,
          keyAlias: keyPair.keyAlias,
          biometricType: model.device?.biometricType ?? biometricType,
          deviceName: model.device?.deviceName ?? resolvedDeviceName,
          userType: userType?.trim(),
          enrolledAt: model.device?.enrolledAt ?? DateTime.now(),
          lastUsedAt: model.device?.lastUsedAt,
          isCurrent: model.device?.isCurrent ?? true,
        );

        // Replace the single local credential only after server success.
        if (existing != null &&
            existing.keyAlias.trim().isNotEmpty &&
            existing.keyAlias != keyPair.keyAlias) {
          await _cryptoService.deleteKey(existing.keyAlias);
        }

        await _saveCredential(credential);
        return credential.toEntity();
      } catch (error) {
        // Keep the previous credential; discard the unused new native key.
        await _cryptoService.deleteKey(keyPair.keyAlias);
        rethrow;
      }
    });
  }

  @override
  Future<EitherResponseOrException<BiometricChallenge>> challenge({
    String? userType,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (kIsWeb) {
        throw UnsupportedError('Biometric login is not supported on web.');
      }

      final credential = await _readCredential();
      if (credential == null) {
        throw HttpException(
          title: 'Biometric unavailable',
          message: 'No biometric enrollment exists on this device.',
        );
      }

      final deviceId = await getOrCreateDeviceId(storage);
      final resolvedUserType = _resolveUserType(userType ?? credential.userType);
      final headers = await AuthApiHeaders.biometric(
        storage: storage,
        userType: resolvedUserType,
      );

      final challengeResponse = await apiClient.post(
        ApiEndpoints.authBiometricChallenge,
        JsonRequestBody({'deviceId': deviceId}),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: headers,
      );

      final challenge = ResponseValidator.parse(
        challengeResponse,
        (data) => BiometricChallengeModel.fromJson(
          data as Map<String, dynamic>,
        ),
        dataValidator: (data) => data is Map,
      );

      if (challenge.challengeToken.trim().isEmpty ||
          challenge.nonce.trim().isEmpty) {
        throw HttpException(
          title: 'Biometric login failed',
          message: 'The challenge response was incomplete.',
          requestMethod: challengeResponse.requestOptions.method,
          requestUri: challengeResponse.requestOptions.uri,
          responseData: challengeResponse.data,
        );
      }

      Logger.logMessage(
        'Biometric challenge resolved: token=${challenge.challengeToken.length}, nonce=${challenge.nonce.length}',
      );
      return challenge.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<void>> authenticateForLogin({
    String? userType,
    String? preferredBiometric,
    String? reason,
  }) {
    return safeNetworkCall(() async {
      if (kIsWeb) {
        throw UnsupportedError('Biometric login is not supported on web.');
      }

      final credential = await _readCredential();
      if (credential == null) {
        throw HttpException(
          title: 'Biometric unavailable',
          message: 'No biometric enrollment exists on this device.',
        );
      }

      try {
        await _cryptoService.authenticateForSigning(
          keyAlias: credential.keyAlias,
          reason: reason?.trim().isNotEmpty == true
              ? reason!.trim()
              : 'Use biometrics to sign in.',
          preferredBiometric: preferredBiometric,
        );
      } on PlatformException catch (error) {
        if (error.code == 'reenrollment_required') {
          await _credentialStore.delete();
          throw HttpException(
            title: 'Biometric reenrollment required',
            message:
                'Biometric login needs to be set up again. Enable it from Profile.',
            responseData: error.code,
          );
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> cancelLoginAuthentication() {
    return _cryptoService.cancelSigning();
  }

  @override
  Future<void> clearLocalCredential() async {
    final credential = await _readCredential();
    if (credential != null && credential.keyAlias.trim().isNotEmpty) {
      await _cryptoService.deleteKey(credential.keyAlias);
    }
    await _credentialStore.delete();
  }

  @override
  Future<EitherResponseOrException<AdminAuthSession>> loginWithChallenge({
    required BiometricChallenge challenge,
    String? userType,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (kIsWeb) {
        throw UnsupportedError('Biometric login is not supported on web.');
      }

      Logger.logMessage('Biometric login started.');
      final credential = await _readCredential();
      if (credential == null) {
        throw HttpException(
          title: 'Biometric unavailable',
          message: 'No biometric enrollment exists on this device.',
        );
      }

      Logger.logMessage(
        'Biometric credential loaded for device ${credential.deviceId}.',
      );

      final deviceId = await getOrCreateDeviceId(storage);
      final resolvedUserType = _resolveUserType(userType ?? credential.userType);
      final headers = await AuthApiHeaders.biometric(
        storage: storage,
        userType: resolvedUserType,
      );

      Logger.logMessage('Biometric headers prepared for $resolvedUserType.');
      late final String signature;
      try {
        signature = await _cryptoService.completeSign(
          nonce: challenge.nonce,
        );
      } on PlatformException catch (error) {
        Logger.logError('Biometric signature creation failed: $error');
        await _cryptoService.cancelSigning();
        if (error.code == 'reenrollment_required' ||
            _isKeyUserNotAuthenticated(error)) {
          await _credentialStore.delete();
          throw HttpException(
            title: 'Biometric reenrollment required',
            message:
                'Biometric login needs to be set up again. Enable it from Profile.',
            responseData: 'reenrollment_required',
          );
        }
        throw HttpException(
          title: 'Biometric login failed',
          message: 'Unable to sign the biometric challenge.',
          requestMethod: 'POST',
          requestUri: Uri.parse(
            '${apiClient.baseUrl}${ApiEndpoints.authBiometricLogin}',
          ),
          responseData: error.toString(),
        );
      } catch (error) {
        Logger.logError('Biometric signature creation failed: $error');
        await _cryptoService.cancelSigning();
        throw HttpException(
          title: 'Biometric login failed',
          message: 'Unable to sign the biometric challenge.',
          requestMethod: 'POST',
          requestUri: Uri.parse(
            '${apiClient.baseUrl}${ApiEndpoints.authBiometricLogin}',
          ),
          responseData: error.toString(),
        );
      }

      Logger.logMessage('Biometric signature created.');
      Logger.logMessage(
        'Posting biometric login for device $deviceId as $resolvedUserType.',
      );
      final loginResponse = await apiClient.post(
        ApiEndpoints.authBiometricLogin,
        JsonRequestBody({
          'deviceId': deviceId,
          'challengeToken': challenge.challengeToken,
          'signature': signature,
        }),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: headers,
      );

      final model = ResponseValidator.parse(
        loginResponse,
        (data) => AdminLoginResultModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map,
      );

      final session = _resolveSession(
        responseData: loginResponse.data,
        model: model,
      );
      if (session == null) {
        throw HttpException(
          title: 'Biometric login failed',
          message: 'The login response did not contain a usable session.',
          requestMethod: loginResponse.requestOptions.method,
          requestUri: loginResponse.requestOptions.uri,
          responseData: loginResponse.data,
        );
      }

      await _saveCredential(
        credential.copyWith(lastUsedAt: DateTime.now()),
      );
      return session;
    });
  }

  @override
  Future<EitherResponseOrException<void>> revoke({
    required String accessToken,
    String? userType,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final credential = await _readCredential();
      final resolvedUserType =
          _resolveUserType(userType ?? credential?.userType);
      final headers = await AuthApiHeaders.biometric(
        storage: storage,
        userType: resolvedUserType,
      );

      final response = await apiClient.delete(
        ApiEndpoints.authBiometricCurrent,
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: {
          ...headers,
          'Authorization': 'Bearer $accessToken',
        },
      );
      ResponseValidator.ensureValid(response);

      if (credential != null && credential.keyAlias.trim().isNotEmpty) {
        await _cryptoService.deleteKey(credential.keyAlias);
      }
      await _credentialStore.delete();
    });
  }

  Future<BiometricCredentialModel?> _readCredential() async {
    final raw = await _credentialStore.read();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final model = BiometricCredentialModel.fromJson(decoded);
    if (!model.isValidNativeCredential) {
      // Legacy software-key credentials are not migrated; force re-enroll.
      await _credentialStore.delete();
      return null;
    }

    return model;
  }

  Future<void> _saveCredential(BiometricCredentialModel credential) async {
    await _credentialStore.write(jsonEncode(credential.toJson()));
  }

  Future<String?> _resolveDeviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        return 'Web';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return info.model.trim().isNotEmpty ? info.model.trim() : info.device;
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return info.name.trim().isNotEmpty ? info.name.trim() : info.model;
        case TargetPlatform.macOS:
          final info = await plugin.macOsInfo;
          return info.model.trim().isNotEmpty ? info.model.trim() : 'macOS';
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          return info.computerName.trim().isNotEmpty
              ? info.computerName.trim()
              : 'Windows';
        case TargetPlatform.linux:
          final info = await plugin.linuxInfo;
          final prettyName = info.prettyName.trim();
          return prettyName.isNotEmpty ? prettyName : 'Linux';
        case TargetPlatform.fuchsia:
          return 'Device';
      }
    } catch (error) {
      Logger.logMessage('Unable to resolve biometric device name: $error');
      return null;
    }
  }

  Future<String> _currentBiometricType() async {
    try {
      final localAuth = LocalAuthentication();
      final available = await localAuth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return 'FACE';
      }
      if (available.contains(BiometricType.fingerprint)) {
        return 'FINGERPRINT';
      }
      return 'OTHER';
    } catch (_) {
      return 'OTHER';
    }
  }

  String _resolveUserType(String? userType) {
    final resolved = userType?.trim().toUpperCase();
    if (resolved == null || resolved.isEmpty) {
      return _defaultUserType;
    }
    return resolved;
  }

  AdminAuthSession? _resolveSession({
    required dynamic responseData,
    required AdminLoginResultModel model,
  }) {
    try {
      final session = model.toSession();
      if (session.accessToken.trim().isNotEmpty &&
          session.refreshToken.trim().isNotEmpty) {
        return session;
      }
    } catch (_) {
      // Fall through to the more permissive parsers below.
    }

    final payload = responseData is Map<String, dynamic>
        ? _unwrapPayload(responseData)
        : null;
    if (payload == null) {
      return null;
    }

    final accessToken = _readString(
      payload,
      const ['accessToken', 'access', 'access_token'],
    );
    final refreshToken = _readString(
      payload,
      const ['refreshToken', 'refresh', 'refresh_token'],
    );

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    final user = _buildUser(payload);
    final menu = _readList(payload, const ['menu', 'menus']);

    return AdminAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      menu: menu,
      urls: null,
    );
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      return _unwrapPayload(nestedData);
    }

    final nestedResult = json['result'];
    if (nestedResult is Map<String, dynamic>) {
      return _unwrapPayload(nestedResult);
    }

    final nestedPayload = json['payload'];
    if (nestedPayload is Map<String, dynamic>) {
      return _unwrapPayload(nestedPayload);
    }

    return json;
  }

  Map<String, dynamic> _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return const {};
  }

  List<String> _readList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value.whereType<String>().toList();
      }
    }
    return const [];
  }

  String? _readString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      final resolved = value is String ? value.trim() : value.toString().trim();
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    return null;
  }

  AdminAuthUser _buildUser(Map<String, dynamic> payload) {
    final userJson = _readMap(payload, const ['user', 'account', 'profile']);
    final tenantJson = _readMap(userJson, const ['currentTenant']);
    final firstName = _readString(
          userJson,
          const ['firstName', 'first_name', 'givenName'],
        ) ??
        '';
    final lastName = _readString(
          userJson,
          const ['lastName', 'last_name', 'familyName'],
        ) ??
        '';
    final email = _readString(userJson, const ['email']) ?? '';
    final userId = _readString(userJson, const ['id', 'userId', 'user_id']) ??
        _readString(payload, const ['userId', 'user_id']) ??
        '';
    final rolesRaw = userJson['currentRoles'];
    final currentRoles = rolesRaw is List
        ? rolesRaw.whereType<String>().toList()
        : const <String>[];

    return AdminAuthUser(
      id: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      currentTenant: AdminAuthTenant(
        id: _readString(tenantJson, const ['id']) ?? '',
        slug: _readString(tenantJson, const ['slug']) ?? '',
        name: _readString(tenantJson, const ['name']) ?? '',
      ),
      currentRoles: currentRoles,
    );
  }

  bool _isKeyUserNotAuthenticated(PlatformException error) {
    final raw = '${error.code} ${error.message}'.toLowerCase();
    return raw.contains('key user not authenticated') ||
        raw.contains('key_user_not_authenticated') ||
        raw.contains('keystore code: -26');
  }
}
