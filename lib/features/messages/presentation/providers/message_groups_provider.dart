import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';

part 'message_groups_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageGroups extends _$MessageGroups {
  @override
  List<MessageGroupItem> build() => ShellMockData.messageGroups();

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

bool isCareTeamOrgRole(CareTeamRole role) =>
    role == CareTeamRole.employer || role == CareTeamRole.insurance;
