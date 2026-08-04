import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/help_support/data/repositories/help_support_repository_impl.dart';
import 'package:vcare_admin/features/help_support/domain/repositories/help_support_repository.dart';

part 'help_support_repository_provider.g.dart';

@Riverpod(keepAlive: true)
HelpSupportRepository helpSupportRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return HelpSupportRepositoryImpl(apiClient);
}
