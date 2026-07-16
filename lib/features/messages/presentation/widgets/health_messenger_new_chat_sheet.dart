import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/associated_user_messenger_mapper.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_chat_notifier.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/vcare_messenger_avatar.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

class HealthMessengerNewChatSheet extends ConsumerStatefulWidget {
  const HealthMessengerNewChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HealthMessengerNewChatSheet(),
    );
  }

  @override
  ConsumerState<HealthMessengerNewChatSheet> createState() =>
      _HealthMessengerNewChatSheetState();
}

class _HealthMessengerNewChatSheetState
    extends ConsumerState<HealthMessengerNewChatSheet> {
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthMessengerChatProvider.notifier).ensureAssociatedUsersLoaded();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matches(AssociatedUser user, String query) {
    if (query.isEmpty) {
      return true;
    }
    return user.displayName.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        AssociatedUserMessengerMapper.humanizeRole(user.role)
            .toLowerCase()
            .contains(query);
  }

  Future<void> _openChat(MessengerUser user) async {
    Navigator.of(context).pop();
    await ref.read(healthMessengerChatProvider.notifier).openDirectChat(user);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final chatState = ref.watch(healthMessengerChatProvider);
    final query = _queryController.text.trim().toLowerCase();
    final associatedUsers = chatState.associatedUsers
        .where((user) => _matches(user, query))
        .toList(growable: false);
    final suggested = associatedUsers
        .where((user) => !user.isPlatformUser)
        .map(AssociatedUserMessengerMapper.toMessengerUser)
        .toList(growable: false);
    final allPeople = associatedUsers
        .where((user) => user.isPlatformUser)
        .map(AssociatedUserMessengerMapper.toMessengerUser)
        .toList(growable: false);
    final isLoading =
        chatState.isBootstrapping || chatState.isSuggestedUsersLoading;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.userPlus, color: VCareColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'New chat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search people by name or role',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: vcare.mutedForeground,
                    ),
                    filled: true,
                    fillColor: vcare.muted.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: vcare.border),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (suggested.isNotEmpty) ...[
                            _SectionLabel(
                              'Suggested',
                              vcare: vcare,
                              icon: LucideIcons.sparkles,
                            ),
                            const SizedBox(height: 8),
                            for (final user in suggested)
                              _ChatPickRow(
                                user: user,
                                onTap: () => _openChat(user),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if (allPeople.isNotEmpty) ...[
                            _SectionLabel('All people', vcare: vcare),
                            const SizedBox(height: 8),
                            for (final user in allPeople)
                              _ChatPickRow(
                                user: user,
                                onTap: () => _openChat(user),
                              ),
                          ],
                          if (suggested.isEmpty && allPeople.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No people match your search',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: vcare.mutedForeground),
                              ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
    this.label, {
    required this.vcare,
    this.icon,
  });

  final String label;
  final VCareThemeExtension vcare;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: VCareColors.accent),
          const SizedBox(width: 6),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: vcare.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _ChatPickRow extends StatelessWidget {
  const _ChatPickRow({required this.user, required this.onTap});

  final MessengerUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayName = user.username.trim().isEmpty ? user.id : user.username;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: vcare.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    VcareMessengerAvatar(
                      displayTitle: displayName,
                      imageUrl: user.avatarUrl,
                      size: 44,
                      borderRadius: 16,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: user.isOnline
                              ? const Color(0xFF22C55E)
                              : vcare.mutedForeground.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
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
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email.trim().isNotEmpty)
                        Text(
                          user.email.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VCareColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
