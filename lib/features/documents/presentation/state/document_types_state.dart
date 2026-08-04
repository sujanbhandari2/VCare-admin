import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class DocumentTypesState {
  const DocumentTypesState({
    this.operation = const OperationState<List<DocumentTypeOption>>.idle(),
  });

  final OperationState<List<DocumentTypeOption>> operation;

  bool get requesting => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  List<DocumentTypeOption> get data => operation.data ?? const [];

  DocumentTypesState loading() => DocumentTypesState(
    operation: OperationState.loading(data: operation.data),
  );

  DocumentTypesState success(List<DocumentTypeOption> data) =>
      DocumentTypesState(operation: OperationState.success(data));

  DocumentTypesState failure(String? message) => DocumentTypesState(
    operation: OperationState.failure(message, data: operation.data),
  );
}
