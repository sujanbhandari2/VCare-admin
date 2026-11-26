import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Fixed row height (avatar + two text lines + vertical padding).
const double kCaseMentionPickerRowExtent = 52;

/// Vertical padding inside the mention list (`ListView` top + bottom).
const double kCaseMentionPickerListVerticalPadding = 8;

/// How many user rows to show before the list scrolls.
const int kCaseMentionPickerVisibleRows = 3;

/// Default cap for the mention suggestions sheet.
const double kCaseMentionPickerMaxHeight =
    kCaseMentionPickerVisibleRows * kCaseMentionPickerRowExtent +
    kCaseMentionPickerListVerticalPadding;

/// Overlay list of mentionable users shown when typing `@`.
class CaseMentionPicker extends StatelessWidget {
  const CaseMentionPicker({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onSelected,
    this.error,
    this.onRetry,
    this.maxHeight = kCaseMentionPickerMaxHeight,
  });

  final List<CaseNoteTagUser> users;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<CaseNoteTagUser> onSelected;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      elevation: 4,
      color: vcare.card,
      clipBehavior: Clip.antiAlias,
      borderRadius: VCareRadius.lgAll,
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
            : _UserList(
                users: users,
                maxHeight: maxHeight,
                onSelected: onSelected,
              ),
      ),
    );
  }
}

class _UserList extends StatefulWidget {
  const _UserList({
    required this.users,
    required this.maxHeight,
    required this.onSelected,
  });

  final List<CaseNoteTagUser> users;
  final double maxHeight;
  final ValueChanged<CaseNoteTagUser> onSelected;

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final itemCount = widget.users.length;
    final contentHeight =
        itemCount * kCaseMentionPickerRowExtent +
        kCaseMentionPickerListVerticalPadding;
    final listHeight = math.min(contentHeight, widget.maxHeight);
    final needsScroll = contentHeight > widget.maxHeight;

    final scrollPhysics = needsScroll
        ? const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())
        : const NeverScrollableScrollPhysics();

    return SizedBox(
      height: listHeight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => notification.depth == 0,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.builder(
            controller: _scrollController,
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: itemCount,
            itemExtent: kCaseMentionPickerRowExtent,
            physics: scrollPhysics,
            dragStartBehavior: DragStartBehavior.down,
            itemBuilder: (context, index) {
              final user = widget.users[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onSelected(user),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              vcare.primary.withValues(alpha: 0.12),
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: vcare.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vcare.mutedForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
