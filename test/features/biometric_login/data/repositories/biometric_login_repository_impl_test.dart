import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/features/biometric_login/data/models/biometric_credential_model.dart';
import 'package:vcare_admin/features/biometric_login/data/repositories/biometric_login_repository_impl.dart';
import 'package:vcare_admin/features/biometric_login/data/services/biometric_credential_local_store.dart';
import 'package:vcare_admin/features/biometric_login/data/services/biometric_crypto_service.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';

import '../../../../helpers/in_memory_storage_service.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? postResponse;
  Response<dynamic>? deleteResponse;
  Object? postError;
  Object? deleteError;
  String? lastPostPath;
  String? lastDeletePath;
  RequestBody? lastPostBody;
  Map<String, String>? lastPostHeaders;
  Map<String, String>? lastDeleteHeaders;
  final List<String> postPaths = <String>[];

  @override
  String get baseUrl => 'https://example.com/api/v1/';

  @override
  Map<String, String> get headers => const {};

  @override
  Future<Response<dynamic>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<dynamic>> delete(
    String path, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) async {
    lastDeletePath = path;
    lastDeleteHeaders = additionalHeaders;
    if (deleteError != null) {
      throw deleteError!;
    }
    return deleteResponse!;
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    bool forceRefresh = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<dynamic>> post(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    postPaths.add(path);
    lastPostPath = path;
    lastPostBody = body;
    lastPostHeaders = additionalHeaders;
    if (postError != null) {
      throw postError!;
    }
    return postResponse!;
  }

  @override
  Future<Response<dynamic>> patch(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<dynamic>> put(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) =>
      throw UnimplementedError();
}

class _FakeCryptoService extends BiometricCryptoService {
  _FakeCryptoService() : super(channel: const MethodChannel('test.biometric'));

  final deletedAliases = <String>[];
  var keyCounter = 0;
  var authenticated = false;
  String? lastSignedAlias;
  String? lastNonce;
  String? pendingAlias;

  @override
  Future<BiometricKeyPairData> generateKeyPair({String? keyAlias}) async {
    keyCounter += 1;
    final alias = keyAlias?.trim().isNotEmpty == true
        ? keyAlias!.trim()
        : 'alias-$keyCounter';
    return BiometricKeyPairData(
      keyAlias: alias,
      publicKeyBase64: 'cHVibGljLWtleS0ka2V5Q291bnRlcg==',
    );
  }

  @override
  Future<void> authenticateForSigning({
    required String keyAlias,
    String reason = 'Use biometrics to sign in.',
    String? preferredBiometric,
  }) async {
    pendingAlias = keyAlias;
    authenticated = true;
  }

  @override
  Future<String> completeSign({required String nonce}) async {
    if (!authenticated || pendingAlias == null) {
      throw StateError('Biometric authentication is required before signing');
    }
    lastSignedAlias = pendingAlias;
    lastNonce = nonce;
    authenticated = false;
    pendingAlias = null;
    return base64Encode(List<int>.filled(64, 7));
  }

  @override
  Future<void> cancelSigning() async {
    authenticated = false;
    pendingAlias = null;
  }

  @override
  Future<String> signNonce({
    required String keyAlias,
    required String nonce,
    String reason = 'Use biometrics to sign in.',
  }) async {
    await authenticateForSigning(keyAlias: keyAlias, reason: reason);
    return completeSign(nonce: nonce);
  }

  @override
  Future<void> deleteKey(String keyAlias) async {
    deletedAliases.add(keyAlias);
  }
}

BiometricCredentialModel _credential({
  required String accountId,
  String keyAlias = 'alias-a',
  String deviceId = 'device-1',
}) {
  return BiometricCredentialModel(
    version: BiometricCredentialModel.currentVersion,
    accountId: accountId,
    accountEmail: '$accountId@example.com',
    enrollmentId: 'enroll-$accountId',
    deviceId: deviceId,
    publicKeyBase64: 'cHVibGljLWtleQ==',
    keyAlias: keyAlias,
    biometricType: 'FACE',
    deviceName: 'Test Phone',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricCredentialModel', () {
    test('rejects legacy software private-key credentials', () {
      final model = BiometricCredentialModel.fromJson({
        'version': 1,
        'deviceId': 'device-1',
        'publicKeyBase64': 'abc',
        'privateKeyScalar': 'deadbeef',
        'biometricType': 'FACE',
      });

      expect(model.isValidNativeCredential, isFalse);
    });

    test('accepts native key-alias credentials', () {
      final model = _credential(accountId: 'user-a');
      expect(model.isValidNativeCredential, isTrue);
      expect(model.toJson().containsKey('privateKeyScalar'), isFalse);
    });
  });

  group('BiometricLoginRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late InMemoryStorageService storage;
    late InMemoryBiometricCredentialLocalStore credentialStore;
    late _FakeCryptoService crypto;
    late BiometricLoginRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      storage = InMemoryStorageService();
      credentialStore = InMemoryBiometricCredentialLocalStore();
      crypto = _FakeCryptoService();
      repository = BiometricLoginRepositoryImpl(
        apiClient,
        storage,
        credentialStore: credentialStore,
        cryptoService: crypto,
      );
    });

    test('fetchStatus without accountId reports any local enrollment', () async {
      await credentialStore.write(
        jsonEncode(_credential(accountId: 'user-a').toJson()),
      );

      final result = await repository.fetchStatus();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isEnrolled, isTrue);
      expect(result.dataOrNull?.accountId, 'user-a');
    });

    test('fetchStatus with mismatched accountId reports disabled', () async {
      await credentialStore.write(
        jsonEncode(_credential(accountId: 'user-a').toJson()),
      );

      final result = await repository.fetchStatus(accountId: 'user-b');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isEnrolled, isFalse);
    });

    test('fetchStatus with matching accountId reports enrolled', () async {
      await credentialStore.write(
        jsonEncode(_credential(accountId: 'user-a').toJson()),
      );

      final result = await repository.fetchStatus(accountId: 'user-a');
      expect(result.dataOrNull?.isEnrolled, isTrue);
    });

    test('enroll replaces previous account credential after success', () async {
      await credentialStore.write(
        jsonEncode(
          _credential(accountId: 'user-a', keyAlias: 'alias-old').toJson(),
        ),
      );
      await storage.set(StorageKeys.deviceId, 'device-1');

      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.authBiometricEnroll),
        statusCode: 200,
        data: {
          'enrolled': true,
          'device': {
            'id': 'enroll-b',
            'deviceId': 'device-1',
            'deviceName': 'Pixel',
            'biometricType': 'FINGERPRINT',
            'enrolledAt': '2026-09-10T10:00:00.000Z',
            'lastUsedAt': null,
            'isCurrent': true,
          },
        },
      );

      final result = await repository.enroll(
        accessToken: 'token-b',
        accountId: 'user-b',
        accountEmail: 'b@example.com',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.accountId, 'user-b');
      expect(result.dataOrNull?.isEnrolled, isTrue);
      expect(crypto.deletedAliases, contains('alias-old'));

      final stored = BiometricCredentialModel.fromJson(
        jsonDecode(await credentialStore.read() as String)
            as Map<String, dynamic>,
      );
      expect(stored.accountId, 'user-b');
      expect(stored.keyAlias, isNot(equals('alias-old')));
    });

    test('enroll failure keeps previous credential and deletes new key',
        () async {
      await credentialStore.write(
        jsonEncode(
          _credential(accountId: 'user-a', keyAlias: 'alias-old').toJson(),
        ),
      );
      await storage.set(StorageKeys.deviceId, 'device-1');
      apiClient.postError = HttpException(
        title: 'fail',
        message: 'server error',
        statusCode: 400,
      );

      final result = await repository.enroll(
        accessToken: 'token-b',
        accountId: 'user-b',
      );

      expect(result.isFailure, isTrue);
      expect(crypto.deletedAliases, isNotEmpty);

      final stored = BiometricCredentialModel.fromJson(
        jsonDecode(await credentialStore.read() as String)
            as Map<String, dynamic>,
      );
      expect(stored.accountId, 'user-a');
      expect(stored.keyAlias, 'alias-old');
    });

    test('loginWithChallenge signs nonce with native key alias', () async {
      await credentialStore.write(
        jsonEncode(
          _credential(accountId: 'user-a', keyAlias: 'alias-sign').toJson(),
        ),
      );
      await storage.set(StorageKeys.deviceId, 'device-1');

      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.authBiometricLogin),
        statusCode: 200,
        data: {
          'tokens': {
            'accessToken': 'access',
            'refreshToken': 'refresh',
          },
          'user': {
            'id': 'user-a',
            'email': 'a@example.com',
            'firstName': 'A',
            'lastName': 'User',
            'currentTenant': {
              'id': 't1',
              'slug': 'default',
              'name': 'Default',
            },
            'currentRoles': ['ADMIN'],
          },
          'menu': ['dashboard'],
        },
      );

      final auth = await repository.authenticateForLogin();
      expect(auth.isSuccess, isTrue);

      final result = await repository.loginWithChallenge(
        challenge: const BiometricChallenge(
          challengeToken: 'challenge',
          nonce: 'nonce-value',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(crypto.lastSignedAlias, 'alias-sign');
      expect(crypto.lastNonce, 'nonce-value');
      expect(result.dataOrNull?.accessToken, 'access');
    });

    test('revoke deletes server enrollment then local credential', () async {
      await credentialStore.write(
        jsonEncode(
          _credential(accountId: 'user-a', keyAlias: 'alias-revoke').toJson(),
        ),
      );
      await storage.set(StorageKeys.deviceId, 'device-1');
      apiClient.deleteResponse = Response<dynamic>(
        requestOptions:
            RequestOptions(path: ApiEndpoints.authBiometricCurrent),
        statusCode: 200,
        data: {'success': true},
      );

      final result = await repository.revoke(accessToken: 'access-token');

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastDeletePath, ApiEndpoints.authBiometricCurrent);
      expect(
        apiClient.lastDeleteHeaders?['Authorization'],
        'Bearer access-token',
      );
      expect(crypto.deletedAliases, contains('alias-revoke'));
      expect(await credentialStore.read(), isNull);
    });

    test('revoke failure retains local credential', () async {
      await credentialStore.write(
        jsonEncode(
          _credential(accountId: 'user-a', keyAlias: 'alias-keep').toJson(),
        ),
      );
      await storage.set(StorageKeys.deviceId, 'device-1');
      apiClient.deleteError = HttpException(
        title: 'fail',
        message: 'unauthorized',
        statusCode: 401,
      );

      final result = await repository.revoke(accessToken: 'access-token');

      expect(result.isFailure, isTrue);
      expect(await credentialStore.read(), isNotNull);
      expect(crypto.deletedAliases, isEmpty);
    });

    test('challenge posts deviceId with X-Device-Id header', () async {
      await credentialStore.write(
        jsonEncode(_credential(accountId: 'user-a').toJson()),
      );
      await storage.set(StorageKeys.deviceId, 'stable-device');
      apiClient.postResponse = Response<dynamic>(
        requestOptions:
            RequestOptions(path: ApiEndpoints.authBiometricChallenge),
        statusCode: 200,
        data: {
          'challengeToken': 'tok',
          'nonce': 'nonce',
          'expiresIn': 300,
        },
      );

      final result = await repository.challenge();

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPostPath, ApiEndpoints.authBiometricChallenge);
      expect(apiClient.lastPostHeaders?['X-Device-Id'], 'stable-device');
      final body = apiClient.lastPostBody as JsonRequestBody;
      expect(body.data['deviceId'], 'stable-device');
    });
  });
}
