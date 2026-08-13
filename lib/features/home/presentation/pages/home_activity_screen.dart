import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_w9_form_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class HomeActivityScreen extends ConsumerStatefulWidget {
  const HomeActivityScreen({super.key});

  @override
  ConsumerState<HomeActivityScreen> createState() => _HomeActivityScreenState();
}

class _HomeActivityScreenState extends ConsumerState<HomeActivityScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(todoListStateProvider);
      if (state.items.isEmpty &&
          !state.isInitialLoading &&
          !state.isInitialError) {
        ref.read(todoListStateProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listState = ref.read(todoListStateProvider);
    final shouldLoadMore =
        listState.hasMore &&
        listState.items.isNotEmpty &&
        !listState.isLoadingMore &&
        listState.loadMoreErrorMessage == null &&
        !listState.isInitialLoading &&
        !listState.isInitialError &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref.read(todoListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(todoListStateProvider.notifier).refresh();
  }

  Future<void> _handleItemTap(TodoItem item) async {
    if (item.type == TodoType.paymentFailed) {
      await TodoTransactionDetailSheet.show(context, item: item);
      return;
    }
    if (item.type == TodoType.w9FormMissing) {
      await TodoW9FormSheet.show(context, item: item);
      return;
    }
    if (item.type == TodoType.completeProfile) {
      await context.pushNamed(
        AppRouter.profileEditName,
        queryParameters: const {'tab': 'story'},
      );
      if (!mounted) {
        return;
      }
      await ref.read(todoListStateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(todoListStateProvider);
    final items = listState.items;

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        slivers: [
          const SliverVcarePageHeader(title: 'To do list', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (listState.isInitialLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (listState.isInitialError && items.isEmpty)
                  VcareErrorStatePanel(
                    title: 'Unable to load tasks',
                    message: listState.operation.errorMessage,
                    padding: const EdgeInsets.all(24),
                    actionLabel: context.appLocalization.retry,
                    onAction: () =>
                        ref.read(todoListStateProvider.notifier).loadInitial(),
                  )
                else if (items.isEmpty)
                  const VcareEmptyStateCard(
                    icon: LucideIcons.listChecks,
                    title: 'No tasks yet',
                    description:
                        'Action items and updates will appear here when something needs your attention.',
                  )
                else
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    TodoListRow(
                      item: items[i],
                      onTap: () => _handleItemTap(items[i]),
                    ),
                  ],
                if (listState.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (listState.loadMoreErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.read(todoListStateProvider.notifier).loadMore(),
                        child: Text(
                          NetworkErrorMessage.displayMessage(
                            context,
                            message: listState.loadMoreErrorMessage,
                          ),
                          style: TextStyle(color: context.vcare.primary),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
