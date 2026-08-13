import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_profile_files_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_profile_files_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseProfileFilesState extends _$CaseProfileFilesState {
  int _generation = 0;

  @override
  CaseProfileFilesStateData build(String clientId) =>
      const CaseProfileFilesStateData();

  Future<void> fetchFiles({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(caseFileRepositoryProvider)
        .fetchClientProfileFiles(
          clientId,
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
        );

    if (!ref.mounted || generation != _generation) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _generation) {
          state = state.failure(error.userMessage);
        }
      },
      success: (files) {
        if (ref.mounted && generation == _generation) {
          state = state.success(files);
        }
      },
    );
  }
}
