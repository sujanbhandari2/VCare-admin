import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_row.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/clients_empty_state.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_search_bar.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

/// Clients list — parity with vcareapp [ClientsPage].
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _scrolled = false;
  bool _searchFocused = false;
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientsListStateProvider.notifier).loadInitial();
    });
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 8;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }

    final listState = ref.read(clientsListStateProvider);
    final shouldLoadMore =
        listState.hasMore &&
        listState.items.isNotEmpty &&
        !listState.isLoadingMore &&
        !listState.isRefreshing &&
        listState.loadMoreErrorMessage == null &&
        !listState.isInitialLoading &&
        !listState.isInitialError &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref.read(clientsListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(clientsListStateProvider.notifier).search(value);
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(clientsListStateProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(clientsListStateProvider);
    final clients = listState.items;
    final subtitle = buildClientsSubtitle(
      listState.totalItems,
      isLoading: listState.isInitialLoading,
    );
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        controller: _scrollController,
        onRefresh: _onRefresh,
        padForMobileBottomNav: true,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: true,
              showBottomBorder: _scrolled,
              title: vcareTabPageTitle(title: 'Clients', subtitle: subtitle),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: VcareStickySearchHeaderDelegate(
              scrolled: _scrolled,
              focused: _searchFocused,
              controller: _searchController,
              onChanged: _onSearchChanged,
              onFocusChange: (focused) {
                if (focused != _searchFocused) {
                  setState(() => _searchFocused = focused);
                }
              },
              placeholder: 'Search clients by name, email or city',
            ),
          ),
          if (listState.isInitialLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (listState.isInitialError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: VcareErrorStatePanel(
                title: 'Unable to load clients',
                message: listState.operation.errorMessage,
                actionLabel: context.appLocalization.retry,
                onAction: () =>
                    ref.read(clientsListStateProvider.notifier).loadInitial(),
              ),
            )
          else if (listState.isEmpty)
            const SliverToBoxAdapter(child: ClientsEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: clients.length + (listState.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= clients.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final client = clients[index];
                  return ClientRow(
                    client: client,
                    onTap: () => context.pushNamed(
                      AppRouter.clientDetailName,
                      pathParameters: {'id': client.id},
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
