import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class ClientDocumentsLoadableState {
  ClientDocumentsLoadableState({
    LoadableListState<ClientFile>? list,
    this.uploadOperation = const OperationState<void>.idle(),
  }) : list = list ?? LoadableListState<ClientFile>();

  final LoadableListState<ClientFile> list;
  final OperationState<void> uploadOperation;

  bool get isUploading => uploadOperation.isLoading;

  String? get uploadError => uploadOperation.errorMessage;

  List<ClientFile> get items => list.items;

  int get totalItems => list.totalItems;

  bool get hasMore => list.hasMore;

  bool get isInitialLoading => list.isInitialLoading;

  bool get isInitialError => list.isInitialError;

  bool get isEmpty => list.isEmpty;

  bool get isLoadingMore => list.isLoadingMore;

  String? get loadMoreErrorMessage => list.loadMoreErrorMessage;

  OperationState<List<ClientFile>> get operation => list.operation;

  ClientDocumentsLoadableState copyWithUpload(
    OperationState<void> uploadOperation,
  ) => ClientDocumentsLoadableState(
    list: list,
    uploadOperation: uploadOperation,
  );

  ClientDocumentsLoadableState copyWithList(
    LoadableListState<ClientFile> list,
  ) => ClientDocumentsLoadableState(
    list: list,
    uploadOperation: uploadOperation,
  );
}
