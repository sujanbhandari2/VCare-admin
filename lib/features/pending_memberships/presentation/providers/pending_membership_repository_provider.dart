import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/pending_memberships/data/repositories/pending_membership_repository_impl.dart';
import 'package:vcare_admin/features/pending_memberships/domain/repositories/pending_membership_repository.dart';

part 'pending_membership_repository_provider.g.dart';

@Riverpod(keepAlive: true)
PendingMembershipRepository pendingMembershipRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PendingMembershipRepositoryImpl(apiClient);
}
