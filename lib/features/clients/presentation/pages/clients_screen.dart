import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/clients/data/clients_mock_data.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_row.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/clients_empty_state.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_search_bar.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

/// Clients list — parity with vcareapp [ClientsPage].
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  bool _scrolled = false;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 8;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ClientsMockData.search(_query);
    final subtitle = buildClientsSubtitle(clients.length);
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
              title: vcareTabPageTitle(title: 'Clients', subtitle: subtitle),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: VcareStickySearchHeaderDelegate(
              scrolled: _scrolled,
              focused: _searchFocused,
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onFocusChange: (focused) {
                if (focused != _searchFocused) {
                  setState(() => _searchFocused = focused);
                }
              },
              placeholder: 'Search clients by name, email or city',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: clients.isEmpty
                ? const SliverToBoxAdapter(child: ClientsEmptyState())
                : SliverList.separated(
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
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
