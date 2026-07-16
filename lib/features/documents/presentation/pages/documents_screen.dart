import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_filter.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_doc_row.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_empty_state.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_filters.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_preview_dialog.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_upload_actions.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

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
  String? _deletingDocumentId;

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
    return ref
        .watch(documentsListStateProvider)
        .items
        .map(documentItemFromAgentFile)
        .toList();
  }

  Future<void> _openDocument(DocumentItem item) async {
    if (!item.canOpen) return;

    if (item.kind == DocumentKind.image ||
        item.imagePreviewUrl.startsWith('data:') ||
        isDocumentPdf(item.imagePreviewUrl, item.name) ||
        isDocumentPdf(item.dataUrl, item.name)) {
      await DocumentsPreviewDialog.show(context, item);
      return;
    }

    final openUrl = item.dataUrl.trim().isNotEmpty
        ? item.dataUrl
        : item.imagePreviewUrl;

    final launched = await launchUrlString(
      openUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      context.showVcareToast(
        title: 'Could not open document',
        description: item.name,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _deleteDocument(DocumentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '${item.name} will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingDocumentId = item.id);

    final result = await ref
        .read(documentsListStateProvider.notifier)
        .deleteDocument(documentId: item.id);

    if (!mounted) return;

    setState(() => _deletingDocumentId = null);

    if (result.success) {
      context.showVcareToast(
        title: 'Document deleted',
        variant: VcareToastVariant.success,
      );
    } else {
      context.showVcareToast(
        title: 'Could not delete document',
        description: result.error,
        variant: VcareToastVariant.destructive,
      );
    }
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
        padForMobileBottomNav: true,
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
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
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
                  VcareErrorStatePanel(
                    title: 'Unable to load documents',
                    message: listState.operation.errorMessage,
                    padding: const EdgeInsets.all(24),
                    actionLabel: context.appLocalization.retry,
                    onAction: () => ref
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
                      isDeleting: _deletingDocumentId == filtered[i].id,
                      onOpen: filtered[i].canOpen
                          ? () => _openDocument(filtered[i])
                          : null,
                      onDelete: filtered[i].isDeletable
                          ? () => _deleteDocument(filtered[i])
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
                          NetworkErrorMessage.displayMessage(
                            context,
                            message: listState.loadMoreErrorMessage,
                          ),
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
