import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_code_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/state/agent_code_state.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'agent_code_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AgentCodeStateNotifier extends _$AgentCodeStateNotifier {
  @override
  AgentCodeState build() => const AgentCodeState();

  Future<void> updateAgentCode({
    required String agentCode,
    CancelToken? cancelToken,
    void Function(UpdatedAgentCode? result)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(agentCodeRepositoryProvider).updateAgentCode(
          agentCode: agentCode,
          cancelToken: cancelToken,
        );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (result) async {
        if (ref.mounted) {
          final currentProfile = ref.read(localProfileStateProvider);
          final nextLink = result.referralLink?.trim().isNotEmpty == true
              ? result.referralLink
              : replaceReferralCode(
                    currentProfile.referralLink,
                    result.agentCode,
                  ) ??
                  currentProfile.referralLink;

          await ref.read(localProfileStateProvider.notifier).updateReferralCode(
                agentCode: result.agentCode,
                referralLink: nextLink,
              );

          if (ref.mounted) {
            state = state.success(result);
          }
        }
        onCompleted?.call(result);
      },
    );
  }
}
