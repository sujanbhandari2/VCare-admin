import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/care_avatar.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class CareTeamDetailScreen extends StatefulWidget {
  const CareTeamDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<CareTeamDetailScreen> createState() => _CareTeamDetailScreenState();
}

class _CareTeamDetailScreenState extends State<CareTeamDetailScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _messages = List.from(
      HomeMockData.messagesByContact[widget.memberId] ?? [],
    );
    // Sorting by date just in case, though mock is sorted.
    _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    if (_editingId != null) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == _editingId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: _editingId!,
            body: text,
            createdAt: _messages[index].createdAt,
            sender: 'me',
          );
        }
        _editingId = null;
        _composer.clear();
      });
      return;
    }

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          body: text,
          createdAt: DateTime.now(),
          sender: 'me',
        ),
      );
      _composer.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startEdit(String id, String body) {
    setState(() {
      _editingId = id;
      _composer.text = body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _composer.clear();
    });
  }

  void _deleteMessage(String id) {
    setState(() {
      _messages.removeWhere((m) => m.id == id);
      if (_editingId == id) {
        _editingId = null;
        _composer.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    CareTeamMember? member;
    for (final entry in HomeMockData.careTeam) {
      if (entry.id == widget.memberId) {
        member = entry;
        break;
      }
    }

    if (member == null) {
      return const Scaffold(body: Center(child: Text('Contact not found')));
    }

    final isOrg = member.isOrg;

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(title: member.name, showBack: true),
          Expanded(
            child: Column(
              children: [
                _DetailProfileCard(member: member, isOrg: isOrg),
                Expanded(
                  child: isOrg
                      ? _OrgInfoBody(member: member)
                      : _MessageList(
                          messages: _messages,
                          member: member,
                          scrollController: _scrollController,
                          onEdit: _startEdit,
                          onDelete: _deleteMessage,
                        ),
                ),
              ],
            ),
          ),
          if (!isOrg)
            _ChatComposer(
              controller: _composer,
              onSend: _send,
              isEditing: _editingId != null,
              onCancelEdit: _cancelEdit,
            ),
        ],
      ),
    );
  }
}

class _DetailProfileCard extends StatelessWidget {
  const _DetailProfileCard({required this.member, required this.isOrg});

  final CareTeamMember member;
  final bool isOrg;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vcare.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CareAvatar(member: member, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.roleLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: VCareColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.bio ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                _CircularButton(
                  icon: LucideIcons.phone,
                  color: VCareColors.primary,
                  onTap: () {},
                ),
                if (!isOrg) ...[
                  const SizedBox(width: 6),
                  _CircularButton(
                    icon: LucideIcons.mail,
                    color: Colors.white,
                    iconColor: vcare.mutedForeground,
                    onTap: () {},
                    showBorder: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  const _CircularButton({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    this.onTap,
    this.showBorder = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: showBorder ? Border.all(color: context.vcare.border) : null,
          boxShadow: [
            if (!showBorder)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.member,
    required this.scrollController,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ChatMessage> messages;
  final CareTeamMember member;
  final ScrollController scrollController;
  final void Function(String id, String body) onEdit;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hi 👋',
          style: TextStyle(color: vcare.mutedForeground, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true, // Start from bottom
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final isMe = m.sender == 'me';

        bool showDate = true;
        if (index < messages.length - 1) {
          final next = messages[index + 1]; // next is older in reverse list
          showDate =
              m.createdAt.day != next.createdAt.day ||
              m.createdAt.month != next.createdAt.month;
        }

        return Column(
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: vcare.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM d').format(m.createdAt).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: vcare.mutedForeground.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    _SmallCareAvatar(member: member),
                    const SizedBox(width: 8),
                  ],
                  if (isMe)
                    _MessageActionsMenu(
                      onEdit: () => onEdit(m.id, m.body),
                      onDelete: () => onDelete(m.id),
                    ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? VCareColors.primary : vcare.muted,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        m.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageActionsMenu extends StatelessWidget {
  const _MessageActionsMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        LucideIcons.moreHorizontal,
        size: 16,
        color: context.vcare.mutedForeground.withValues(alpha: 0.4),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(-8, 24),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.pencil, size: 16),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                LucideIcons.trash2,
                size: 16,
                color: VCareColors.destructive,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(fontSize: 14, color: VCareColors.destructive),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallCareAvatar extends StatelessWidget {
  const _SmallCareAvatar({required this.member});

  final CareTeamMember member;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    if (member.photoAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          member.photoAsset!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
        ),
      );
    } else if (member.photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          member.photoUrl!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _DefaultAvatar(vcare: vcare, name: member.name),
        ),
      );
    }
    return _DefaultAvatar(vcare: vcare, name: member.name);
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.vcare, required this.name});

  final VCareThemeExtension vcare;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: vcare.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        name[0],
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: vcare.accent,
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    required this.isEditing,
    required this.onCancelEdit,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEditing;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editing message',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelEdit,
                    child: const Icon(LucideIcons.x, size: 14),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: vcare.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: vcare.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    LucideIcons.paperclip,
                    size: 18,
                    color: vcare.mutedForeground,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    LucideIcons.mic,
                    size: 18,
                    color: vcare.mutedForeground,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Material(
                  color: VCareColors.primary.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onSend,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        LucideIcons.send,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgInfoBody extends StatelessWidget {
  const _OrgInfoBody({required this.member});

  final CareTeamMember member;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final rows = <MapEntry<String, String>>[
      if (member.phone != null) MapEntry('Phone', member.phone!),
      if (member.email != null) MapEntry('Email', member.email!),
      if (member.role == CareTeamRole.insurance)
        const MapEntry('Policy #', 'alex.rivera@example.com'),
      const MapEntry('Group #', 'GRP-22841'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: vcare.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _OrgInfoRow(
                  label: rows[i].key,
                  value: rows[i].value,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrgInfoRow extends StatelessWidget {
  const _OrgInfoRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: vcare.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
