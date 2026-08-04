import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_code_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_code_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_repository_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';

import '../../../../fixtures/repositories/fake_agent_code_repository.dart';
import '../../../../fixtures/repositories/fake_local_profile_repository.dart';

void main() {
  group('AgentCodeStateNotifier', () {
    late FakeAgentCodeRepository repository;
    late FakeLocalProfileRepository localProfileRepository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAgentCodeRepository();
      localProfileRepository = FakeLocalProfileRepository();
      container = ProviderContainer(
        overrides: [
          agentCodeRepositoryProvider.overrideWith((ref) => repository),
          localProfileRepositoryProvider.overrideWith(
            (ref) => localProfileRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateAgentCode saves agentCode and referralLink to local profile',
        () async {
      repository.updateResult = Success(
        const UpdatedAgentCode(
          agentCode: 'new-code',
          referralLink: 'https://vcare.app/refer/new-code',
        ),
      );

      UpdatedAgentCode? completed;
      await container.read(agentCodeStateProvider.notifier).updateAgentCode(
            agentCode: 'new-code',
            onCompleted: (result) => completed = result,
          );

      final state = container.read(agentCodeStateProvider);
      final profile = container.read(localProfileStateProvider);

      expect(repository.updateCallCount, 1);
      expect(repository.lastAgentCode, 'new-code');
      expect(state.updating, isFalse);
      expect(state.data?.agentCode, 'new-code');
      expect(completed?.agentCode, 'new-code');
      expect(profile.agentCode, 'new-code');
      expect(profile.referralLink, 'https://vcare.app/refer/new-code');
      expect(localProfileRepository.saveCallCount, 1);
    });

    test('updateAgentCode rewrites referral link when API omits it', () async {
      repository.updateResult = Success(
        const UpdatedAgentCode(agentCode: 'rewritten'),
      );

      await container.read(agentCodeStateProvider.notifier).updateAgentCode(
            agentCode: 'rewritten',
          );

      final profile = container.read(localProfileStateProvider);
      expect(profile.agentCode, 'rewritten');
      expect(profile.referralLink, 'https://vcare.app/refer/rewritten');
    });

    test('updateAgentCode sets failure on error', () async {
      repository.updateResult = Failure(
        HttpException(
          title: 'Error',
          message: 'Code already taken',
          errorType: HttpErrorType.client,
        ),
      );

      UpdatedAgentCode? completed = const UpdatedAgentCode(agentCode: 'x');
      await container.read(agentCodeStateProvider.notifier).updateAgentCode(
            agentCode: 'taken',
            onCompleted: (result) => completed = result,
          );

      final state = container.read(agentCodeStateProvider);
      final profile = container.read(localProfileStateProvider);

      expect(state.error, 'Code already taken');
      expect(completed, isNull);
      expect(profile.agentCode, 'old-code');
      expect(localProfileRepository.saveCallCount, 0);
    });
  });
}
