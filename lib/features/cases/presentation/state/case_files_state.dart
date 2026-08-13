import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Files list + mutation state for a single case.
class CaseFilesStateData {
  const CaseFilesStateData({
    this.fetchOperation = const OperationState<List<CaseFile>>.idle(),
    this.mutationOperation = const OperationState<void>.idle(),
  });

  final OperationState<List<CaseFile>> fetchOperation;
  final OperationState<void> mutationOperation;

  List<CaseFile> get files => fetchOperation.data ?? const [];

  bool get fetching => fetchOperation.isLoading;

  bool get mutating => mutationOperation.isLoading;

  bool get isInitialLoading => fetchOperation.isLoading && files.isEmpty;

  bool get isRefreshing => fetchOperation.isLoading && files.isNotEmpty;

  String? get error =>
      mutationOperation.errorMessage ?? fetchOperation.errorMessage;

  CaseFilesStateData copyWith({
    OperationState<List<CaseFile>>? fetchOperation,
    OperationState<void>? mutationOperation,
  }) {
    return CaseFilesStateData(
      fetchOperation: fetchOperation ?? this.fetchOperation,
      mutationOperation: mutationOperation ?? this.mutationOperation,
    );
  }

  CaseFilesStateData loading() => copyWith(
    fetchOperation: OperationState<List<CaseFile>>.loading(data: files),
  );

  CaseFilesStateData success(List<CaseFile> files) => copyWith(
    fetchOperation: OperationState<List<CaseFile>>.success(files),
  );

  CaseFilesStateData failure(String? message) => copyWith(
    fetchOperation: OperationState<List<CaseFile>>.failure(
      message,
      data: files,
    ),
  );

  CaseFilesStateData mutationLoading() =>
      copyWith(mutationOperation: const OperationState<void>.loading());

  CaseFilesStateData mutationIdle() =>
      copyWith(mutationOperation: const OperationState<void>.idle());

  CaseFilesStateData mutationFailure(String? message) => copyWith(
    mutationOperation: OperationState<void>.failure(message),
  );
}
