import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/auth/data/auth_device_id.dart';

class AuthApiHeaders {
  AuthApiHeaders._();

  /// Admin/platform login — omit X-User-Type per API contract.
  static const admin = <String, String>{};

  static const agent = {'x-user-type': 'AGENT'};

  /// Admin headers with a durable device id for 2FA remember-device (web parity).
  static Future<Map<String, String>> adminWithDeviceId(
    StorageService storage,
  ) async {
    final deviceId = await getOrCreateDeviceId(storage);
    return {
      'X-Device-Id': deviceId,
    };
  }

  /// Agent headers, optionally including a durable `x-device-id` for 2FA trust.
  static Future<Map<String, String>> agentWith({
    StorageService? storage,
    bool includeDeviceId = false,
  }) async {
    if (!includeDeviceId || storage == null) {
      return agent;
    }
    final deviceId = await getOrCreateDeviceId(storage);
    return {
      ...agent,
      'x-device-id': deviceId,
    };
  }
}
