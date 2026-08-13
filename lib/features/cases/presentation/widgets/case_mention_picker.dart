import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Overlay list of mentionable users shown when typing `@`.
class CaseMentionPicker extends StatelessWidget {
  const CaseMentionPicker({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onSelected,
    this.error,
    this.onRetry,
  });

  final List<CaseNoteTagUser> users;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<CaseNoteTagUser> onSelected;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      elevation: 8,
      borderRadius: VCareRadius.lgAll,
      color: vcare.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: VCareRadius.lgAll,
            border: Border.all(color: vcare.border),
          ),
          child: isLoading && users.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : error != null && users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      if (onRetry != null)
                        TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ),
                )
              : users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No matches',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return InkWell(
                      onTap: () => onSelected(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: context.vcare.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.vcare.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: vcare.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.atSign,
                              size: 14,
                              color: vcare.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
