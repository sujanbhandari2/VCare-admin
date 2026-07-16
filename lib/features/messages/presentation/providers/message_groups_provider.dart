import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';

part 'message_groups_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageGroups extends _$MessageGroups {
  @override
  List<MessageGroupItem> build() {
    final careTeam = ref.watch(careTeamStateProvider).members;
    return ShellMockData.messageGroups(careTeam: careTeam);
  }

  MessageGroupItem create({
    required String name,
    required List<CareTeamMember> members,
  }) {
    final created = MessageGroupItem(
      id: 'group-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      members: members,
      createdAt: DateTime.now(),
      lastBody: 'Group "$name" created with ${members.length} members.',
      lastAt: DateTime.now(),
    );
    state = [created, ...state];
    return created;
  }
}

// Re-exported for backwards compatibility with existing imports.
bool isCareTeamOrgRole(CareTeamRole role) =>
    role == CareTeamRole.employer || role == CareTeamRole.insurance;
