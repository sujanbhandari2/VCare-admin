import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/clients/presentation/state/client_documents_loadable_state.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'client_documents_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ClientDocumentsState extends _$ClientDocumentsState {
  static const int _pageSize = 20;

  late final String _clientId;
  int _currentPage = 0;
  int _generation = 0;

  @override
  ClientDocumentsLoadableState build(String clientId) {
    _clientId = clientId;
    return ClientDocumentsLoadableState();
  }

  PaginatedListRequest _buildRequest({required int page}) {
    return PaginatedListRequest(page: page, limit: _pageSize);
  }

  Future<EitherResponseOrException<PaginatedResult<ClientFile>>> _fetchPage(
    PaginatedListRequest request, {
    bool forceRefresh = false,
  }) {
    return ref.read(clientRepositoryProvider).fetchDocuments(
      _clientId,
      request,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> loadInitial({bool forceRefresh = true}) async {
    final generation = ++_generation;

    if (ref.mounted) {
      state = state.copyWithList(state.list.loading());
    }

    final response = await _fetchPage(
      _buildRequest(page: 1),
      forceRefresh: forceRefresh,
    );

    if (!ref.mounted || generation != _generation) {
      return;
    }

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _generation) {
          state = state.copyWithList(state.list.failure(error.userMessage));
        }
      },
      success: (result) {
        _currentPage = result.pagination.page;
        if (ref.mounted && generation == _generation) {
          state = state.copyWithList(
            state.list.success(
              items: result.items,
              total: result.pagination.total,
            ),
          );
        }
      },
    );
  }

  Future<void> refresh() => loadInitial(forceRefresh: true);

  Future<void> loadMore() async {
    if (state.list.isLoadingMore || !state.hasMore) {
      return;
    }

    if (ref.mounted) {
      state = state.copyWithList(state.list.loadingMore());
    }

    final nextPage = _currentPage + 1;
    final response = await _fetchPage(_buildRequest(page: nextPage));

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWithList(state.list.appendFailure(error.userMessage));
        }
      },
      success: (result) {
        _currentPage = result.pagination.page;
        if (ref.mounted) {
          state = state.copyWithList(
            state.list.appendSuccess(
              appendedItems: result.items,
              total: result.pagination.total,
            ),
          );
        }
      },
    );
  }

  Future<void> uploadDocument({
    required String fileName,
    required List<int> bytes,
    String? note,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (!ref.mounted || state.isUploading) return;

    state = state.copyWithUpload(const OperationState<void>.loading());

    final response = await ref
        .read(clientRepositoryProvider)
        .uploadClientDocument(
          clientId: _clientId,
          fileName: fileName,
          bytes: bytes,
          note: note,
          date: todayIsoDate(),
        );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWithUpload(
            OperationState<void>.failure(error.userMessage),
          );
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await loadInitial(forceRefresh: true);
        if (ref.mounted) {
          state = state.copyWithUpload(const OperationState<void>.idle());
        }
        onCompleted?.call(true, null);
      },
    );
  }

  void addLocalFile(ClientFile file) {
    if (!ref.mounted) return;

    final list = state.list;
    final updated = [file, ...list.items];
    state = state.copyWithList(
      list.success(items: updated, total: list.totalItems + 1),
    );
  }

  Future<({bool success, String? error})> renameDocument({
    required String documentId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return (success: false, error: null);
    }

    final response = await ref
        .read(clientRepositoryProvider)
        .renameClientDocument(documentId: documentId, name: trimmed);

    return response.when(
      failure: (error) => (success: false, error: error.userMessage),
      success: (_) {
        if (ref.mounted) {
          renameLocalFile(documentId, trimmed);
        }
        return (success: true, error: null);
      },
    );
  }

  void renameLocalFile(String id, String name) {
    if (!ref.mounted) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final list = state.list;
    final updated = list.items
        .map(
          (file) => file.id == id
              ? ClientFile(
                  id: file.id,
                  name: trimmed,
                  size: file.size,
                  uploadedAt: file.uploadedAt,
                  url: file.url,
                  mime: file.mime,
                )
              : file,
        )
        .toList();

    state = state.copyWithList(
      list.success(items: updated, total: list.totalItems),
    );
  }

  void removeLocalFile(String id) {
    if (!ref.mounted) return;

    final list = state.list;
    final updated = list.items.where((file) => file.id != id).toList();
    final nextTotal = list.totalItems > 0 ? list.totalItems - 1 : 0;
    state = state.copyWithList(list.success(items: updated, total: nextTotal));
  }
}
