import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_repository_provider.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
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

  String? _resolveAgentProfileId() {
    final id = ref
        .read(authMeStateProvider)
        .data
        ?.agentProfile
        ?.id
        ?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  /// Public resolver used by W-9 todo upload (with optional todo resource fallback).
  String? resolveAgentProfileIdForUpload() => _resolveAgentProfileId();

  String? resolveCurrentUserId() {
    final id = ref.read(authMeStateProvider).data?.user.id?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool canManage(AgentFile file) {
    return canManageDocument(
      currentUserId: resolveCurrentUserId(),
      createdBy: file.createdBy,
      userId: file.userId,
    );
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    final agentProfileId = _resolveAgentProfileId();
    if (agentProfileId == null) {
      return Future.value(
        Failure(
          HttpException(
            title: 'Missing agent profile',
            message: 'Agent profile is required to load documents',
          ),
        ),
      );
    }

    return ref.read(documentsRepositoryProvider).fetchFiles(
      request,
      agentProfileId: agentProfileId,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> uploadDocument({
    required String fileName,
    required List<int> bytes,
    required String documentType,
    String? note,
    String? agentProfileId,
    bool refreshList = true,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    final resolvedProfileId = () {
      final override = agentProfileId?.trim();
      if (override != null && override.isNotEmpty) return override;
      return _resolveAgentProfileId();
    }();

    if (resolvedProfileId == null) {
      onCompleted?.call(false, 'Agent profile is required to upload documents');
      return;
    }

    final response = await ref.read(documentsRepositoryProvider).uploadDocument(
      fileName: fileName,
      bytes: bytes,
      agentProfileId: resolvedProfileId,
      documentType: documentType,
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

  Future<({bool success, String? error})> renameDocument({
    required String documentId,
    required String name,
  }) async {
    final response = await ref
        .read(documentsRepositoryProvider)
        .renameDocument(documentId: documentId, name: name);

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

  Future<({bool success, String? error, List<int>? bytes})>
  downloadDocumentContent({
    required String documentId,
  }) async {
    final response = await ref
        .read(documentsRepositoryProvider)
        .downloadDocumentContent(documentId: documentId);

    return response.when(
      failure: (error) async =>
          (success: false, error: error.userMessage, bytes: null),
      success: (bytes) async => (success: true, error: null, bytes: bytes),
    );
  }
}
