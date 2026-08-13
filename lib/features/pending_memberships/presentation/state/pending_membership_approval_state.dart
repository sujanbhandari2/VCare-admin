import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// State for the approve flow — billing start options, pricing preview, and the
/// approve request itself.
class PendingMembershipApprovalState {
  const PendingMembershipApprovalState({
    this.pricingOperation =
        const OperationState<MembershipApprovalCompute>.idle(),
    this.approveOperation = const OperationState<PendingMembership>.idle(),
    this.billingStartOptions = const [],
    this.selectedBillingStart,
  });

  final OperationState<MembershipApprovalCompute> pricingOperation;
  final OperationState<PendingMembership> approveOperation;
  final List<MembershipBillingStartOption> billingStartOptions;

  /// `yyyy-MM-dd` value of the selected billing start option.
  final String? selectedBillingStart;

  MembershipApprovalCompute? get compute => pricingOperation.data;

  bool get isInitialLoading => pricingOperation.isLoading && compute == null;

  /// Re-pricing after a billing date change, with the previous preview still on
  /// screen (dimmed).
  bool get isRepricing => pricingOperation.isLoading && compute != null;

  bool get hasError => pricingOperation.hasError && compute == null;
  String? get error => pricingOperation.errorMessage;
  String? get approveError => approveOperation.errorMessage;
  bool get approving => approveOperation.isLoading;

  bool get isEmpty => compute?.isEmpty ?? false;
  bool get canApprove =>
      !approving && !isRepricing && compute?.isEmpty == false;

  MembershipBillingStartOption? get selectedOption {
    for (final option in billingStartOptions) {
      if (option.value == selectedBillingStart) return option;
    }
    return billingStartOptions.isEmpty ? null : billingStartOptions.last;
  }

  PendingMembershipApprovalState copyWith({
    OperationState<MembershipApprovalCompute>? pricingOperation,
    OperationState<PendingMembership>? approveOperation,
    List<MembershipBillingStartOption>? billingStartOptions,
    String? selectedBillingStart,
  }) {
    return PendingMembershipApprovalState(
      pricingOperation: pricingOperation ?? this.pricingOperation,
      approveOperation: approveOperation ?? this.approveOperation,
      billingStartOptions: billingStartOptions ?? this.billingStartOptions,
      selectedBillingStart: selectedBillingStart ?? this.selectedBillingStart,
    );
  }
}
