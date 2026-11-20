import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_note.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class MyTaskDetailState {
  const MyTaskDetailState({
    this.fetchOperation = const OperationState<MyTask>.idle(),
    this.updateOperation = const OperationState<MyTask>.idle(),
    this.notesOperation = const OperationState<List<MyTaskNote>>.idle(),
    this.notes = const [],
  });

  final OperationState<MyTask> fetchOperation;
  final OperationState<MyTask> updateOperation;
  final OperationState<List<MyTaskNote>> notesOperation;
  final List<MyTaskNote> notes;

  MyTask? get data => updateOperation.data ?? fetchOperation.data;

  bool get fetching => fetchOperation.isLoading && data == null;
  bool get refreshing => fetchOperation.isLoading && data != null;
  bool get updating => updateOperation.isLoading;
  bool get notesLoading => notesOperation.isLoading && notes.isEmpty;
  bool get hasError => fetchOperation.hasError && data == null;
  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;
  String? get notesError => notesOperation.errorMessage;

  MyTaskDetailState loading() => MyTaskDetailState(
    fetchOperation: OperationState.loading(data: data),
    updateOperation: updateOperation,
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState success(MyTask task) => MyTaskDetailState(
    fetchOperation: OperationState.success(task),
    updateOperation: const OperationState.idle(),
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState failure(String? message) => MyTaskDetailState(
    fetchOperation: OperationState.failure(message, data: data),
    updateOperation: updateOperation,
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState updatingInProgress() => MyTaskDetailState(
    fetchOperation: fetchOperation,
    updateOperation: OperationState.loading(data: data),
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState updateSuccess(MyTask task) => MyTaskDetailState(
    fetchOperation: OperationState.success(task),
    updateOperation: OperationState.success(task),
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState updateFailure(String? message) => MyTaskDetailState(
    fetchOperation: fetchOperation,
    updateOperation: OperationState.failure(message, data: data),
    notesOperation: notesOperation,
    notes: notes,
  );

  MyTaskDetailState notesLoadingState() => MyTaskDetailState(
    fetchOperation: fetchOperation,
    updateOperation: updateOperation,
    notesOperation: OperationState.loading(data: notes),
    notes: notes,
  );

  MyTaskDetailState notesSuccess(List<MyTaskNote> next) => MyTaskDetailState(
    fetchOperation: fetchOperation,
    updateOperation: updateOperation,
    notesOperation: OperationState.success(next),
    notes: next,
  );

  MyTaskDetailState notesFailure(String? message) => MyTaskDetailState(
    fetchOperation: fetchOperation,
    updateOperation: updateOperation,
    notesOperation: OperationState.failure(message, data: notes),
    notes: notes,
  );
}
