import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_filter.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/presentation/providers/document_uploads_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_doc_row.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_empty_state.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_filters.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_upload_actions.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  static const double _horizontalPadding = 20;
  static const double _loadMoreTriggerThreshold = 240;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  DocumentFilter _filter = DocumentFilter.all;
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsListStateProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listState = ref.read(documentsListStateProvider);
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
      ref.read(documentsListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(documentsListStateProvider.notifier).refresh();
  }

  List<DocumentItem> _allItems() {
    final uploads = ref.watch(documentUploadsStateProvider);
    final apiItems = ref
        .watch(documentsListStateProvider)
        .items
        .map(documentItemFromAgentFile)
        .toList();

    return [...uploads, ...apiItems]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final listState = ref.watch(documentsListStateProvider);
    final items = _allItems();
    final filtered = filterDocuments(
      items: items,
      filter: _filter,
      query: _searchController.text,
    );

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'My Documents',
              subtitle: "Everything you've shared, in one place",
              showBack: true,
              showBell: false,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              0,
              _horizontalPadding,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search documents…',
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: vcare.mutedForeground,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: vcare.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: vcare.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: vcare.border),
                          ),
                          filled: true,
                          fillColor: vcare.card,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const DocumentsUploadActions(),
                  ],
                ),
                const SizedBox(height: 16),
                DocumentsFilters(
                  value: _filter,
                  items: items,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (listState.isInitialLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (listState.isInitialError && items.isEmpty)
                  _DocumentsErrorState(
                    message: listState.operation.errorMessage,
                    onRetry: () => ref
                        .read(documentsListStateProvider.notifier)
                        .loadInitial(),
                  )
                else if (filtered.isEmpty)
                  const DocumentsEmptyState()
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    DocumentsDocRow(
                      item: filtered[i],
                      onDelete: filtered[i].isDeletable
                          ? () => ref
                                .read(documentUploadsStateProvider.notifier)
                                .removeUpload(filtered[i].uploadId!)
                          : null,
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
                        onPressed: () => ref
                            .read(documentsListStateProvider.notifier)
                            .loadMore(),
                        child: Text(
                          listState.loadMoreErrorMessage!,
                          style: TextStyle(color: VCareColors.primary),
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

class _DocumentsErrorState extends StatelessWidget {
  const _DocumentsErrorState({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              message ?? 'Unable to load documents.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
