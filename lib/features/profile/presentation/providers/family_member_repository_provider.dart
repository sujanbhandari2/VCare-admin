import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/profile/data/repositories/family_member_repository_impl.dart';
import 'package:vcare_admin/features/profile/domain/repositories/family_member_repository.dart';

part 'family_member_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FamilyMemberRepository familyMemberRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FamilyMemberRepositoryImpl(apiClient);
}
