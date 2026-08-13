import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Client profile files offered when attaching existing documents to a case.
class CaseProfileFilesStateData {
  const CaseProfileFilesStateData({
    this.fetchOperation = const OperationState<List<CaseFile>>.idle(),
  });

  final OperationState<List<CaseFile>> fetchOperation;

  List<CaseFile> get files => fetchOperation.data ?? const [];

  bool get fetching => fetchOperation.isLoading;

  bool get isInitialLoading => fetchOperation.isLoading && files.isEmpty;

  String? get error => fetchOperation.errorMessage;

  CaseProfileFilesStateData loading() => CaseProfileFilesStateData(
    fetchOperation: OperationState<List<CaseFile>>.loading(data: files),
  );

  CaseProfileFilesStateData success(List<CaseFile> results) =>
      CaseProfileFilesStateData(
        fetchOperation: OperationState<List<CaseFile>>.success(results),
      );

  CaseProfileFilesStateData failure(String? message) =>
      CaseProfileFilesStateData(
        fetchOperation: OperationState<List<CaseFile>>.failure(
          message,
          data: files,
        ),
      );
}
