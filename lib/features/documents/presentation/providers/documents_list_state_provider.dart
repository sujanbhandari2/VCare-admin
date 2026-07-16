import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_repository_provider.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_notifier_mixin.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'documents_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class DocumentsListState extends _$DocumentsListState
    with PaginatedListNotifierMixin<AgentFile> {
  @override
  LoadableListState<AgentFile> build() => LoadableListState<AgentFile>();

  @override
  bool get mounted => ref.mounted;

  @override
  bool resolveForceRefresh() => ref.read(networkFetchSessionProvider);

  @override
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(documentsRepositoryProvider).fetchFiles(
      request,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> uploadDocument({
    required String fileName,
    required List<int> bytes,
    String? note,
    bool refreshList = true,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final response = await ref.read(documentsRepositoryProvider).uploadDocument(
      fileName: fileName,
      bytes: bytes,
      note: note,
      date: todayIsoDate(),
    );

    await response.when(
      failure: (error) async {
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        if (refreshList) {
          await refresh();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<({bool success, String? error})> deleteDocument({
    required String documentId,
  }) async {
    final response = await ref
        .read(documentsRepositoryProvider)
        .deleteDocument(documentId: documentId);

    return response.when(
      failure: (error) async => (success: false, error: error.userMessage),
      success: (_) async {
        if (ref.mounted) {
          await refresh();
        }
        return (success: true, error: null);
      },
    );
  }
}
