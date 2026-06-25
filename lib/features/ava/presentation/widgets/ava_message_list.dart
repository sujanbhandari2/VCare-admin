import 'package:flutter/material.dart';

import 'package:vcare_admin/features/ava/domain/entities/ava_message.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_date_chip.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_human_request_link.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_layout.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_message_bubble.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_suggestion_list.dart';
import 'package:vcare_admin/features/ava/utils/ava_chat_date.dart';

/// Matches vcareapp [AvaMessageList] — scrollable thread anchored to bottom.
class AvaMessageList extends StatelessWidget {
  const AvaMessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.showSuggestions,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
    required this.onHumanRequest,
  });

  final ScrollController scrollController;
  final List<AvaMessage> messages;
  final bool showSuggestions;
  final void Function(String text) onSend;
  final void Function(String id, String body) onEdit;
  final void Function(String id) onDelete;
  final VoidCallback onHumanRequest;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AvaLayout.horizontalPadding,
            AvaLayout.listTopPadding,
            AvaLayout.horizontalPadding,
            AvaLayout.listBottomPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildChildren(),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren() {
    final children = <Widget>[];

    for (var i = 0; i < messages.length; i++) {
      if (i == 0 ||
          !avaSameDay(messages[i - 1].createdAt, messages[i].createdAt)) {
        children.add(
          AvaDateChip(label: formatAvaChatDateSeparator(messages[i].createdAt)),
        );
      }
      children.add(
        AvaMessageBubble(
          message: messages[i],
          onEdit: messages[i].isMe ? onEdit : null,
          onDelete: messages[i].isMe ? onDelete : null,
        ),
      );
    }

    if (messages.length > 1) {
      children.add(AvaHumanRequestLink(onTap: onHumanRequest));
    }

    if (showSuggestions) {
      children.add(AvaSuggestionList(onSelect: onSend));
    }

    return _spaced(children);
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.isEmpty) return items;
    final spaced = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      spaced.add(const SizedBox(height: AvaLayout.itemGap));
      spaced.add(items[i]);
    }
    return spaced;
  }
}
