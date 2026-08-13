import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/pending_memberships/domain/entities/membership_approval.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/providers/pending_membership_repository_provider.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/state/pending_membership_approval_state.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_approval_builders.dart';
import 'package:vcare_admin/features/pending_memberships/utils/membership_parsers.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'pending_membership_approval_state_provider.g.dart';

@Riverpod(keepAlive: true)
class PendingMembershipApprovalStateNotifier
    extends _$PendingMembershipApprovalStateNotifier {
  @override
  PendingMembershipApprovalState build(String membershipId) =>
      const PendingMembershipApprovalState();

  /// Prices the approval for today, which also yields the missed billing
  /// periods used as billing start options — parity with the web approval flow's
  /// first compute call.
  Future<void> initialize() async {
    if (ref.mounted) {
      state = state.copyWith(
        pricingOperation: OperationState.loading(data: state.compute),
      );
    }

    final today = _today();
    final response = await ref
        .read(pendingMembershipRepositoryProvider)
        .computeApproval(membershipId: membershipId, date: today);

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        state = state.copyWith(
          pricingOperation: OperationState.failure(
            error.userMessage,
            data: state.compute,
          ),
        );
      },
      success: (compute) {
        final options = buildBillingStartOptions(
          compute.missedBillingPeriods,
          now: today,
        );
        final todayOption = options.lastOrNull;

        state = state.copyWith(
          pricingOperation: OperationState.success(compute),
          billingStartOptions: options,
          selectedBillingStart:
              todayOption?.value ?? formatMembershipApiDate(today),
        );
      },
    );
  }

  /// Re-prices the approval for another billing start date.
  Future<void> selectBillingStart(String value) async {
    if (value == state.selectedBillingStart) return;

    MembershipBillingStartOption? option;
    for (final candidate in state.billingStartOptions) {
      if (candidate.value == value) {
        option = candidate;
        break;
      }
    }
    if (option == null) return;

    if (ref.mounted) {
      state = state.copyWith(
        selectedBillingStart: value,
        pricingOperation: OperationState.loading(data: state.compute),
      );
    }

    final response = await ref
        .read(pendingMembershipRepositoryProvider)
        .computeApproval(membershipId: membershipId, date: option.date);

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        state = state.copyWith(
          pricingOperation: OperationState.failure(
            error.userMessage,
            data: state.compute,
          ),
        );
      },
      success: (compute) {
        state = state.copyWith(
          pricingOperation: OperationState.success(compute),
        );
      },
    );
  }

  /// Approves with the selected billing start — `POST /enrollments/approve`.
  Future<PendingMembership?> approve({
    void Function(String? message)? onError,
  }) async {
    if (state.approving) return null;

    final date = state.selectedOption?.date ?? _today();

    if (ref.mounted) {
      state = state.copyWith(
        approveOperation: const OperationState<PendingMembership>.loading(),
      );
    }

    final response = await ref
        .read(pendingMembershipRepositoryProvider)
        .approveMembership(membershipId: membershipId, date: date);

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            approveOperation: OperationState.failure(error.userMessage),
          );
        }
        onError?.call(error.userMessage);
        return null;
      },
      success: (membership) {
        if (ref.mounted) {
          state = state.copyWith(
            approveOperation: OperationState.success(membership),
          );
        }
        return membership;
      },
    );
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
