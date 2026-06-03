import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:flutter_template/features/home/data/home_mock_data.dart';

/// Persists a demo session compatible with [userLoggedInStateProvider].
class VcareMockAuth {
  VcareMockAuth._();

  static Future<void> signIn(dynamic ref) async {
    final storage = ref.read(storageServiceProvider);
    await storage.set(StorageKeys.loggedInUserToken, 'vcare-mock-token');
    await storage.set(StorageKeys.loggedInUserId, 1);
    await storage.set(
      StorageKeys.loggedInUserEmail,
      'alex.rivera@example.com',
    );
    await storage.set(
      StorageKeys.loggedInUserUsername,
      HomeMockData.member.fullName,
    );
    await storage.set(
      StorageKeys.tokenRefreshedDate,
      DateTime.now().toIso8601String(),
    );
    await storage.set(StorageKeys.alreadyOnboarded, true);
    ref.invalidate(userLoggedInStateProvider);
  }

  static Future<void> signOut(dynamic ref) async {
    final storage = ref.read(storageServiceProvider);
    await storage.set(StorageKeys.loggedInUserToken, '');
    await storage.set(StorageKeys.loggedInUserId, 0);
    ref.invalidate(userLoggedInStateProvider);
  }
}
