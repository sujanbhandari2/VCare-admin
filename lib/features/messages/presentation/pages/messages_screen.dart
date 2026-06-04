import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/care_avatar.dart';
import 'package:flutter_template/features/messages/presentation/providers/message_groups_provider.dart';
import 'package:flutter_template/features/messages/presentation/widgets/messages_new_chat_sheet.dart';
import 'package:flutter_template/features/messages/presentation/widgets/messages_new_group_sheet.dart';
import 'package:flutter_template/features/messages/presentation/widgets/messages_empty_state.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';
import 'package:flutter_template/shared/widgets/vcare_sticky_search_bar.dart';
import 'package:flutter_template/shared/widgets/vcare_sticky_tab_header.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _scrolled = false;
  bool _previewEmpty = false;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 16;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final allThreads = ShellMockData.messageThreads();
    final allGroups = ref.watch(messageGroupsProvider);

    final query = _searchController.text.trim().toLowerCase();

    final filteredThreads = _previewEmpty
        ? <MessageThreadItem>[]
        : (query.isEmpty
              ? allThreads
              : allThreads.where((t) {
                  return t.contact.name.toLowerCase().contains(query) ||
                      (t.lastBody ?? '').toLowerCase().contains(query);
                }).toList());

    final filteredGroups = _previewEmpty
        ? <MessageGroupItem>[]
        : (query.isEmpty
              ? allGroups
              : allGroups.where((g) {
                  return g.name.toLowerCase().contains(query) ||
                      g.members.any(
                        (m) => m.name.toLowerCase().contains(query),
                      );
                }).toList());

    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              hasSubtitle: true,
              showBottomBorder: _scrolled,
              title: vcareTabPageTitle(
                title: 'Messages',
                subtitle: 'Chat with your care team',
                action: _HeaderNewMenu(
                  vcare: vcare,
                  onNewChat: () => MessagesNewChatSheet.show(context),
                  onNewGroup: () => MessagesNewGroupSheet.show(
                    context,
                    onCreated: (group) => context.pushNamed(
                      AppRouter.groupChatName,
                      pathParameters: {'id': group.id},
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: VcareStickySearchHeaderDelegate(
              scrolled: _scrolled,
              focused: _searchFocused,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onFocusChange: (focused) {
                if (focused != _searchFocused) {
                  setState(() => _searchFocused = focused);
                }
              },
              placeholder: 'Search messages, people or groups',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () =>
                      setState(() => _previewEmpty = !_previewEmpty),
                  icon: Icon(
                    _previewEmpty ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: vcare.mutedForeground.withValues(alpha: 0.4),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          if (filteredThreads.isEmpty && filteredGroups.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.only(top: 20),
              sliver: SliverToBoxAdapter(child: MessagesEmptyState()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final group in filteredGroups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MessagesGroupRow(group: group, vcare: vcare),
                    ),
                  for (final thread in filteredThreads)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MessagesThreadRow(thread: thread, vcare: vcare),
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderNewMenu extends StatelessWidget {
  const _HeaderNewMenu({
    required this.vcare,
    required this.onNewChat,
    required this.onNewGroup,
  });

  final VCareThemeExtension vcare;
  final VoidCallback onNewChat;
  final VoidCallback onNewGroup;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: onNewChat,
          child: _NewMenuOption(
            icon: LucideIcons.userPlus,
            iconBackground: VCareColors.primary.withValues(alpha: 0.12),
            iconColor: VCareColors.primary,
            title: 'New chat',
            subtitle: 'Start a 1:1 conversation',
          ),
        ),
        PopupMenuItem<void>(
          onTap: onNewGroup,
          child: _NewMenuOption(
            icon: LucideIcons.users,
            iconBackground: vcare.accent.withValues(alpha: 0.12),
            iconColor: vcare.accent,
            title: 'New group',
            subtitle: 'Chat with multiple people',
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plus, size: 16, color: VCareColors.primary),
          const SizedBox(width: 4),
          Text(
            'New',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VCareColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewMenuOption extends StatelessWidget {
  const _NewMenuOption({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessagesThreadRow extends StatelessWidget {
  const _MessagesThreadRow({required this.thread, required this.vcare});

  final MessageThreadItem thread;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    final contact = thread.contact;
    final last = thread.lastAt;

    return Container(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRouter.careTeamDetailName,
          pathParameters: {'id': contact.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CareAvatar(member: contact, size: 48),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: thread.isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: vcare.card, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (last != null)
                          Text(
                            DateFormat('MMM d').format(last),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: VCareColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastBody ?? 'No messages yet — say hi 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: vcare.mutedForeground.withValues(
                                alpha: 0.8,
                              ),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (thread.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: VCareColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesGroupRow extends StatelessWidget {
  const _MessagesGroupRow({required this.group, required this.vcare});

  final MessageGroupItem group;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    final previewMembers = group.members.take(3).toList();
    final extra = group.members.length - previewMembers.length;
    final lastAt = group.lastAt ?? group.createdAt;
    final isFresh =
        DateTime.now().difference(group.createdAt) < const Duration(minutes: 1);

    return Container(
      decoration: BoxDecoration(
        color: isFresh
            ? VCareColors.primary.withValues(alpha: 0.05)
            : vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRouter.groupChatName,
          pathParameters: {'id': group.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: vcare.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isFresh
                          ? Border.all(color: VCareColors.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: vcare.accent,
                      size: 24,
                    ),
                  ),
                  if (isFresh)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: VCareColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: vcare.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFresh) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VCareColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          _formatRelative(lastAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'GROUP · ${group.members.length} MEMBERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: vcare.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MemberAvatars(members: previewMembers),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            group.lastBody ??
                                previewMembers
                                    .map((m) => m.name.split(' ')[0])
                                    .join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: vcare.mutedForeground.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.lastBody == null && extra > 0)
                          Text(
                            ' +$extra',
                            style: TextStyle(
                              fontSize: 12,
                              color: vcare.mutedForeground.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(date);
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.members});

  final List<CareTeamMember> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20.0 + (members.length - 1) * 12.0,
      child: Stack(
        children: [
          for (var i = 0; i < members.length; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.vcare.card, width: 2),
                ),
                child: members[i].photoAsset != null
                    ? CircleAvatar(
                        radius: 8,
                        backgroundImage: AssetImage(members[i].photoAsset!),
                      )
                    : CircleAvatar(
                        radius: 8,
                        backgroundColor: context.vcare.muted,
                        child: Text(
                          members[i].name[0],
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
