import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/biometric_login/data/repositories/biometric_login_repository_impl.dart';
import 'package:vcare_admin/features/biometric_login/domain/repositories/biometric_login_repository.dart';

final biometricLoginRepositoryProvider = Provider<BiometricLoginRepository>(
  (ref) {
    return BiometricLoginRepositoryImpl(
      ref.read(apiClientProvider),
      ref.read(storageServiceProvider),
    );
  },
);
