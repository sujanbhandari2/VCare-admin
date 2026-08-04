import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_repository_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_constants.dart';

import '../../../../fixtures/repositories/fake_care_team_repository.dart';

void main() {
  group('CareTeamStateNotifier', () {
    late FakeCareTeamRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeCareTeamRepository();
      container = ProviderContainer(
        overrides: [
          careTeamRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchCareTeam uses Agent Care Team group filter', () async {
      repository.fetchResult = Success([
        const CareTeamMember(
          id: 'listed',
          name: 'Listed',
          role: CareTeamRole.advocate,
        ),
        const CareTeamMember(
          id: 'mine',
          name: 'Mine',
          role: CareTeamRole.provider,
          agentId: 'agent-1',
        ),
      ]);

      await container.read(careTeamStateProvider.notifier).fetchCareTeam();

      final state = container.read(careTeamStateProvider);
      expect(repository.fetchCallCount, 1);
      expect(repository.lastGroup, careTeamListGroupAgentCareTeam);
      expect(state.listedTeam.map((m) => m.id), ['listed']);
      expect(state.agentTeam.map((m) => m.id), ['mine']);
    });

    test('updateContact calls repository and upserts member', () async {
      repository.updateResult = Success(
        const CareTeamMember(
          id: '1',
          name: 'Updated',
          role: CareTeamRole.provider,
          agentId: 'agent-1',
        ),
      );

      CareTeamMember? completed;
      await container.read(careTeamStateProvider.notifier).updateContact(
            '1',
            (
              name: 'Updated',
              role: CareTeamRole.provider,
              email: 'a@b.com',
              phone: '15551234567',
              website: null,
              bio: '',
              photoUrl: null,
              address: null,
              policyNumber: null,
              groupNumber: null,
              initialProfileId: 'old-profile',
            ),
            onCompleted: (member) => completed = member,
          );

      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdateArgs?['setProfileId'], isTrue);
      expect(repository.lastUpdateArgs?['profileId'], isNull);
      expect(completed?.name, 'Updated');
      expect(container.read(careTeamStateProvider).byId('1')?.name, 'Updated');
    });

    test('deleteContact removes member on success', () async {
      container.read(careTeamStateProvider.notifier);
      // Seed via success path
      repository.fetchResult = Success([
        const CareTeamMember(
          id: '1',
          name: 'To delete',
          role: CareTeamRole.provider,
          agentId: 'agent-1',
        ),
      ]);
      await container.read(careTeamStateProvider.notifier).fetchCareTeam();

      var success = false;
      await container.read(careTeamStateProvider.notifier).deleteContact(
            '1',
            onCompleted: (ok) => success = ok,
          );

      expect(success, isTrue);
      expect(repository.deleteCallCount, 1);
      expect(container.read(careTeamStateProvider).members, isEmpty);
    });

    test('deleteContact sets failure on error', () async {
      repository.deleteResult = Failure(
        HttpException(
          title: 'Error',
          message: 'Cannot delete',
          errorType: HttpErrorType.client,
        ),
      );

      var success = true;
      await container.read(careTeamStateProvider.notifier).deleteContact(
            '1',
            onCompleted: (ok) => success = ok,
          );

      expect(success, isFalse);
      expect(container.read(careTeamStateProvider).deleteError, 'Cannot delete');
    });

    test('createContact sends role label', () async {
      CareTeamMember? created;
      await container.read(careTeamStateProvider.notifier).createContact(
            (
              name: 'New',
              role: CareTeamRole.customerSupport,
              email: '',
              phone: '',
              website: null,
              bio: '',
              photoUrl: null,
              address: null,
              policyNumber: null,
              groupNumber: null,
              initialProfileId: null,
            ),
            onCompleted: (member) => created = member,
          );

      expect(repository.createCallCount, 1);
      expect(repository.lastCreateArgs?['role'], 'Customer Support');
      expect(created?.id, 'new-id');
    });
  });
}
