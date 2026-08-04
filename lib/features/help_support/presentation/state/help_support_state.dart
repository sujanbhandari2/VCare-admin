import 'package:vcare_admin/features/help_support/domain/entities/contact_support_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class HelpSupportState {
  const HelpSupportState({
    this.operation = const OperationState<ContactSupportResult?>.idle(),
  });

  final OperationState<ContactSupportResult?> operation;

  bool get submitting => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  ContactSupportResult? get data => operation.data;

  HelpSupportState loading() =>
      HelpSupportState(operation: OperationState.loading(data: data));

  HelpSupportState success(ContactSupportResult result) =>
      HelpSupportState(operation: OperationState.success(result));

  HelpSupportState failure(String? message) =>
      HelpSupportState(operation: OperationState.failure(message, data: data));

  HelpSupportState idle() => const HelpSupportState();
}
