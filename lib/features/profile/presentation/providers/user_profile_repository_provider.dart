import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:vcare_admin/features/profile/domain/repositories/user_profile_repository.dart';

part 'user_profile_repository_provider.g.dart';

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);

  return UserProfileRepositoryImpl(apiClient);
}
