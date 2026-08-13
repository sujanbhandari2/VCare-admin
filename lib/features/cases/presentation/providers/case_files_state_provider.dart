import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_files_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_files_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CaseFilesState extends _$CaseFilesState {
  int _generation = 0;

  @override
  CaseFilesStateData build(String caseId) => const CaseFilesStateData();

  Future<void> fetchFiles({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(caseFileRepositoryProvider).fetchFiles(
      caseId,
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

  Future<void> uploadFiles({
    required String clientId,
    required List<({String fileName, List<int> bytes})> files,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (files.isEmpty || state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref.read(caseFileRepositoryProvider).uploadFiles(
      caseId,
      clientId,
      files: files,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchFiles(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> addFromUrl({
    required String clientId,
    required List<CaseNotePublicUrl> urls,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (urls.isEmpty || state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref.read(caseFileRepositoryProvider).addFilesFromUrl(
      caseId,
      clientId,
      urls: urls,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchFiles(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> attachProfileFiles({
    required String clientId,
    required List<CaseFile> files,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (files.isEmpty || state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref
        .read(caseFileRepositoryProvider)
        .attachProfileFiles(caseId, clientId, files: files);

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchFiles(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> deleteFile({
    required String fileId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref.read(caseFileRepositoryProvider).deleteFile(
      fileId,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        if (ref.mounted) {
          final remaining = state.files
              .where((file) => file.id != fileId)
              .toList();
          state = state.success(remaining).mutationIdle();
        }
        onCompleted?.call(true, null);
      },
    );
  }
}
