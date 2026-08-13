import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/cases/data/repositories/case_file_repository_impl.dart';
import 'package:vcare_admin/features/cases/data/repositories/case_note_repository_impl.dart';
import 'package:vcare_admin/features/cases/data/repositories/case_repository_impl.dart';
import 'package:vcare_admin/features/cases/data/repositories/case_task_repository_impl.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_file_repository.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_note_repository.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_repository.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_task_repository.dart';

part 'case_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CaseRepository caseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CaseRepositoryImpl(apiClient);
}

@Riverpod(keepAlive: true)
CaseNoteRepository caseNoteRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CaseNoteRepositoryImpl(apiClient);
}

@Riverpod(keepAlive: true)
CaseFileRepository caseFileRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CaseFileRepositoryImpl(apiClient);
}

@Riverpod(keepAlive: true)
CaseTaskRepository caseTaskRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CaseTaskRepositoryImpl(apiClient);
}
