import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:vcare_admin/features/documents/domain/repositories/documents_repository.dart';

part 'documents_repository_provider.g.dart';

@Riverpod(keepAlive: true)
DocumentsRepository documentsRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return DocumentsRepositoryImpl(apiClient);
}
