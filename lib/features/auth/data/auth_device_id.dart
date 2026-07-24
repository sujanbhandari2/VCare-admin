import 'dart:math';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';

/// Returns a durable install device id, creating and persisting one if needed.
///
/// Must survive logout so the server can skip 2FA for remembered devices.
Future<String> getOrCreateDeviceId(StorageService storage) async {
  final existing = storage.get(StorageKeys.deviceId)?.toString().trim();
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final next = _generateDeviceId();
  await storage.set(StorageKeys.deviceId, next);
  return next;
}

String _generateDeviceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  // UUID v4 variant bits
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
