import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/core/services/network/api_client_provider.dart';
import 'package:flutter_template/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:flutter_template/features/profile/domain/repositories/user_profile_repository.dart';

part 'user_profile_repository_provider.g.dart';

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);

  return UserProfileRepositoryImpl(apiClient);
}
