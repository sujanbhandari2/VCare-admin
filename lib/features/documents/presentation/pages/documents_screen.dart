import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_list_state_provider.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_doc_row.dart';
import 'package:vcare_admin/features/documents/presentation/widgets/documents_empty_state.dart';
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
  bool _isLoadMoreRequested = false;
  String? _busyDocumentId;

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

  bool _canManage(DocumentItem item) {
    return canManageDocument(
      currentUserId: ref
          .read(documentsListStateProvider.notifier)
          .resolveCurrentUserId(),
      createdBy: item.createdBy,
      userId: item.userId,
    );
  }

  Future<void> _openDocument(DocumentItem item) async {
    // Match web: open previewLink first, then fall back to url.
    final preview = item.previewUrl?.trim() ?? '';
    final url = item.dataUrl.trim();
    final openUrl = preview.isNotEmpty ? preview : url;

    if (openUrl.isEmpty) {
      context.showVcareToast(
        title: 'Preview unavailable',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    if (item.kind == DocumentKind.image || openUrl.startsWith('data:image')) {
      await DocumentsPreviewDialog.show(context, item);
      return;
    }

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

  Future<void> _downloadDocument(DocumentItem item) async {
    setState(() => _busyDocumentId = item.id);

    final result = await ref
        .read(documentsListStateProvider.notifier)
        .downloadDocumentContent(documentId: item.id);

    if (!mounted) return;

    if (!result.success || result.bytes == null) {
      setState(() => _busyDocumentId = null);
      context.showVcareToast(
        title: 'Could not download document',
        description: result.error,
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final safeName = item.name.trim().isEmpty ? 'document' : item.name.trim();
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(result.bytes!, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              name: safeName,
              mimeType: mimeTypeFromFileName(safeName),
            ),
          ],
          subject: safeName,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      context.showVcareToast(
        title: 'Could not download document',
        variant: VcareToastVariant.destructive,
      );
    } finally {
      if (mounted) {
        setState(() => _busyDocumentId = null);
      }
    }
  }

  Future<void> _renameDocument(DocumentItem item) async {
    if (!_canManage(item)) {
      context.showVcareToast(
        title: 'You can only rename files you uploaded',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDocumentDialog(initialName: item.name),
    );

    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == item.name) return;

    final validationError = documentRenameValidationError(trimmed);
    if (validationError != null) {
      if (!mounted) return;
      context.showVcareToast(
        title: validationError,
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _busyDocumentId = item.id);

    final result = await ref
        .read(documentsListStateProvider.notifier)
        .renameDocument(documentId: item.id, name: trimmed);

    if (!mounted) return;
    setState(() => _busyDocumentId = null);

    if (result.success) {
      context.showVcareToast(
        title: 'Renamed to $trimmed',
        variant: VcareToastVariant.success,
      );
    } else {
      context.showVcareToast(
        title: 'Could not rename document',
        description: result.error,
        variant: VcareToastVariant.destructive,
      );
    }
  }

  Future<void> _deleteDocument(DocumentItem item) async {
    if (!_canManage(item)) {
      context.showVcareToast(
        title: 'You can only delete files you uploaded',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

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

    setState(() => _busyDocumentId = item.id);

    final result = await ref
        .read(documentsListStateProvider.notifier)
        .deleteDocument(documentId: item.id);

    if (!mounted) return;

    setState(() => _busyDocumentId = null);

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
      query: _searchController.text,
    );

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        padForMobileBottomNav: true,
        slivers: [
          SliverVcarePageHeader(
            title: 'My Documents',
            subtitle: "Everything you've shared, in one place",
            showBack: true,
            showBell: false,
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
                      isBusy: _busyDocumentId == filtered[i].id,
                      canManage: _canManage(filtered[i]),
                      onOpen: filtered[i].canOpen
                          ? () => _openDocument(filtered[i])
                          : null,
                      onDownload: () => _downloadDocument(filtered[i]),
                      onRename: () => _renameDocument(filtered[i]),
                      onDelete: () => _deleteDocument(filtered[i]),
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

class _RenameDocumentDialog extends StatefulWidget {
  const _RenameDocumentDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDocumentDialog> createState() => _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends State<_RenameDocumentDialog> {
  late final TextEditingController _controller;
  late final String _extension;

  @override
  void initState() {
    super.initState();
    final parts = splitDocumentFileName(widget.initialName);
    _extension = parts.extension;
    _controller = TextEditingController(text: parts.baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the original extension locked; strips any extension typed into the name.
  String _normalizedBaseName(String raw) {
    var baseName = raw.trim();
    if (baseName.isEmpty) return '';

    if (_extension.isNotEmpty) {
      final lower = baseName.toLowerCase();
      final lockedExt = _extension.toLowerCase();
      if (lower.endsWith(lockedExt)) {
        baseName = baseName.substring(0, baseName.length - _extension.length);
      } else {
        final lastDot = baseName.lastIndexOf('.');
        if (lastDot > 0) {
          baseName = baseName.substring(0, lastDot);
        }
      }
    }

    return baseName.trim();
  }

  void _submit() {
    final baseName = _normalizedBaseName(_controller.text);
    if (baseName.isEmpty) return;

    Navigator.pop(
      context,
      joinDocumentFileName(baseName: baseName, extension: _extension),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return AlertDialog(
      title: const Text('Rename document'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // Prevent typing a new extension into the name field.
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[\\/]')),
        ],
        decoration: InputDecoration(
          hintText: 'Document name',
          suffixText: _extension.isNotEmpty ? _extension : null,
          suffixStyle: TextStyle(
            fontSize: 16,
            color: vcare.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
          helperText: _extension.isNotEmpty
              ? 'File extension cannot be changed'
              : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
