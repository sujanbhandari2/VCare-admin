import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BiometricKeyPairData {
  const BiometricKeyPairData({
    required this.keyAlias,
    required this.publicKeyBase64,
  });

  final String keyAlias;
  final String publicKeyBase64;
}

/// Platform-channel facade over Android Keystore / iOS Secure Enclave.
///
/// Private keys never leave the secure hardware; only the public SPKI and a
/// local key alias are returned to Dart.
///
/// Login signing is two-phase so the OS biometric UI unlocks a Keystore
/// CryptoObject session before the challenge nonce is signed:
/// 1. [authenticateForSigning] — BiometricPrompt + CryptoObject
/// 2. [completeSign] — signs with the authenticated Signature instance
///
/// On Android, never sign with a fresh Signature after a plain biometric
/// prompt — that causes KEY_USER_NOT_AUTHENTICATED (-26).
class BiometricCryptoService {
  const BiometricCryptoService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.vcare.admin/biometric_crypto';

  final MethodChannel _channel;

  Future<BiometricKeyPairData> generateKeyPair({String? keyAlias}) async {
    if (kIsWeb) {
      throw UnsupportedError('Biometric login is not supported on web.');
    }

    final alias = (keyAlias?.trim().isNotEmpty == true)
        ? keyAlias!.trim()
        : _createKeyAlias();

    final response = await _channel.invokeMapMethod<String, dynamic>(
      'generateKeyPair',
      {'keyAlias': alias},
    );

    final resolvedAlias = (response?['keyAlias'] as String?)?.trim() ?? '';
    final publicKeyBase64 =
        (response?['publicKeyBase64'] as String?)?.trim() ?? '';

    if (resolvedAlias.isEmpty || publicKeyBase64.isEmpty) {
      throw StateError('Native biometric key generation returned incomplete data.');
    }

    return BiometricKeyPairData(
      keyAlias: resolvedAlias,
      publicKeyBase64: publicKeyBase64,
    );
  }

  /// Shows the OS biometric prompt and keeps a short-lived signing session.
  Future<void> authenticateForSigning({
    required String keyAlias,
    String reason = 'Use biometrics to sign in.',
    String? preferredBiometric,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Biometric login is not supported on web.');
    }

    await _channel.invokeMethod<void>(
      'authenticateForSigning',
      {
        'keyAlias': keyAlias,
        'reason': reason,
        'preferredBiometric': ?preferredBiometric,
      },
    );
  }

  /// Completes a signature for [nonce] after [authenticateForSigning].
  Future<String> completeSign({required String nonce}) async {
    if (kIsWeb) {
      throw UnsupportedError('Biometric login is not supported on web.');
    }

    final response = await _channel.invokeMapMethod<String, dynamic>(
      'completeSign',
      {'nonce': nonce},
    );

    final signature = (response?['signatureBase64'] as String?)?.trim() ?? '';
    if (signature.isEmpty) {
      throw StateError('Native biometric signing returned an empty signature.');
    }
    return signature;
  }

  Future<void> cancelSigning() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('cancelSigning');
    } catch (_) {
      // Best-effort cleanup of any pending native signing session.
    }
  }

  /// One-shot authenticate + sign (used when a two-phase flow is unnecessary).
  Future<String> signNonce({
    required String keyAlias,
    required String nonce,
    String reason = 'Use biometrics to sign in.',
  }) async {
    await authenticateForSigning(keyAlias: keyAlias, reason: reason);
    try {
      return await completeSign(nonce: nonce);
    } catch (error) {
      await cancelSigning();
      rethrow;
    }
  }

  Future<void> deleteKey(String keyAlias) async {
    if (kIsWeb || keyAlias.trim().isEmpty) {
      return;
    }

    await _channel.invokeMethod<void>(
      'deleteKey',
      {'keyAlias': keyAlias},
    );
  }

  String biometricTypeFromAvailable(List<dynamic> biometrics) {
    final biometricStrings = biometrics.map((item) => item.toString()).toList();
    if (biometricStrings.contains('BiometricType.face')) {
      return 'FACE';
    }
    if (biometricStrings.contains('BiometricType.fingerprint')) {
      return 'FINGERPRINT';
    }
    return 'OTHER';
  }

  String _createKeyAlias() {
    final random = Random.secure();
    final suffix = List<int>.generate(8, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'vcare.biometric.$suffix';
  }
}
