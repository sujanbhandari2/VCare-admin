import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vcare_admin/features/cases/data/pending_attachment.dart';
import 'package:vcare_admin/features/cases/data/request_file_item.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_detail_composer.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_detail_header.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_detail_message_list.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_detail_preview_dialog.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_details_sheet.dart';
import 'package:vcare_admin/features/cases/utils/request_new_utils.dart';
import 'package:vcare_admin/features/cases/data/requests_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  late CareRequest _request;
  late List<RequestMessage> _messages;
  final List<PendingAttachment> _pending = [];
  bool _filesOpen = false;
  String? _editingId;

  /// Web `requestsStore` fields + live thread messages for the sheet.
  CareRequest get _liveRequest {
    final seed = RequestsMockData.byId(widget.requestId) ?? _request;
    return CareRequest(
      id: seed.id,
      type: seed.type,
      title: seed.title,
      status: seed.status,
      createdAt: seed.createdAt,
      updatedAt: seed.updatedAt,
      lastMessageBody: seed.lastMessageBody,
      description: seed.description,
      messages: _messages,
    );
  }

  @override
  void initState() {
    super.initState();
    final seed =
        RequestsMockData.byId(widget.requestId) ??
        HomeMockData.requestById(widget.requestId);
    _request = seed ?? RequestsMockData.seed().first;
    _messages = List<RequestMessage>.from(_request.messages);
    _composer.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<RequestFileItem> get _files => collectRequestFiles(_messages);

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _simulateUpload(String itemId) {
    void tick(double pct) {
      if (!mounted) return;
      setState(() {
        final index = _pending.indexWhere((item) => item.id == itemId);
        if (index == -1) return;
        if (pct >= 100) {
          _pending[index] = _pending[index].copyWith(
            status: PendingAttachmentStatus.done,
            progress: 100,
            clearError: true,
          );
        } else {
          _pending[index] = _pending[index].copyWith(progress: pct);
        }
      });
      if (pct < 100) {
        Future.delayed(const Duration(milliseconds: 220), () {
          tick((pct + 18).clamp(0, 100));
        });
      }
    }

    setState(() {
      final index = _pending.indexWhere((item) => item.id == itemId);
      if (index == -1) return;
      _pending[index] = _pending[index].copyWith(
        status: PendingAttachmentStatus.uploading,
        progress: 0,
        clearError: true,
      );
    });
    Future.delayed(const Duration(milliseconds: 200), () => tick(8));
  }

  void _addPending(PendingAttachment item) {
    setState(() => _pending.add(item));
    _simulateUpload(item.id);
  }

  Future<void> _onFileBytes({
    required String name,
    required List<int> bytes,
    required String mime,
  }) async {
    if (bytes.length > requestNewMaxAttachmentBytes) {
      _showSnack('${name.isEmpty ? 'File' : name} is larger than 5MB');
      return;
    }
    final baseName = name.trim().isEmpty ? 'attachment' : name;
    final displayName = mime.startsWith('image/')
        ? '${baseName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg'
        : baseName;
    _addPending(
      PendingAttachment(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        name: displayName,
        dataUrl: 'data:$mime;base64,${base64Encode(bytes)}',
        size: bytes.length,
      ),
    );
  }

  String _mimeForFile(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'pdf' => 'application/pdf',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'wav' => 'audio/wav',
      'webm' => 'audio/webm',
      'ogg' => 'audio/ogg',
      'aac' => 'audio/aac',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _pickFiles() async {
    const typeGroups = [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'],
        mimeTypes: ['image/*'],
      ),
      XTypeGroup(
        label: 'Documents',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      ),
      XTypeGroup(
        label: 'Audio',
        extensions: ['mp3', 'm4a', 'wav', 'webm', 'ogg', 'aac'],
        mimeTypes: ['audio/*'],
      ),
    ];
    final files = await openFiles(acceptedTypeGroups: typeGroups);
    if (!mounted || files.isEmpty) return;
    for (final file in files) {
      final bytes = await file.readAsBytes();
      await _onFileBytes(
        name: file.name,
        bytes: bytes,
        mime: _mimeForFile(file.name),
      );
    }
  }

  void _send() {
    final body = _composer.text.trim();
    if (_editingId != null) {
      if (body.isEmpty) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == _editingId);
        if (index != -1) {
          final old = _messages[index];
          _messages[index] = RequestMessage(
            id: old.id,
            sender: old.sender,
            body: body,
            createdAt: old.createdAt,
            attachments: old.attachments,
          );
        }
        _editingId = null;
        _composer.clear();
      });
      _scrollToBottom();
      return;
    }

    final ready = _pending
        .where((item) => item.status == PendingAttachmentStatus.done)
        .toList();
    if (body.isEmpty && ready.isEmpty) return;
    if (_pending.any(
      (item) => item.status == PendingAttachmentStatus.uploading,
    )) {
      _showSnack('Waiting for uploads to finish…');
      return;
    }

    setState(() {
      _messages.add(
        RequestMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'me',
          body: body,
          createdAt: DateTime.now(),
          attachments: ready.isEmpty
              ? null
              : ready.map((item) => item.toAttachment()).toList(),
        ),
      );
      _composer.clear();
      _pending.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _startEdit(String id, String body) {
    setState(() {
      _editingId = id;
      _composer.text = body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _composer.clear();
    });
  }

  void _deleteMessage(String id) {
    setState(() {
      _messages.removeWhere((message) => message.id == id);
      if (_editingId == id) _cancelEdit();
    });
  }

  void _showDetails() {
    RequestDetailsSheet.show(context, _liveRequest);
  }

  void _showFilePreview(RequestAttachment file) {
    RequestDetailPreviewDialog.show(context, file);
  }

  void _addVoicePending() {
    _addPending(
      PendingAttachment(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Voice note.m4a',
        dataUrl: 'data:audio/mp4;base64,',
        size: 12000,
      ),
    );
    _showSnack('Voice note recorded (mock).');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final seed = HomeMockData.requestById(widget.requestId);
    if (seed == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: VcarePageHeader(
                title: 'Case',
                showBack: true,
                onBack: () => context.pop(),
              ),
            ),
            const SliverFillRemaining(
              child: Center(child: Text('Request not found')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: 'Case',
            showBack: true,
            onBack: () => context.pop(),
          ),
          RequestDetailHeader(
            request: _liveRequest,
            filesOpen: _filesOpen,
            onFilesToggle: () => setState(() => _filesOpen = !_filesOpen),
            onShowDetails: _showDetails,
            files: _files,
            onAddFile: _pickFiles,
            onPreviewFile: _showFilePreview,
          ),
          Expanded(
            child: RequestDetailMessageList(
              messages: _messages,
              scrollController: _scrollController,
              onEditMessage: _startEdit,
              onDeleteMessage: _deleteMessage,
            ),
          ),
          RequestDetailComposer(
            controller: _composer,
            pending: _pending,
            editingId: _editingId,
            onSend: _send,
            onAttach: _pickFiles,
            onVoice: _addVoicePending,
            onCancelEdit: _cancelEdit,
            onRemovePending: (id) =>
                setState(() => _pending.removeWhere((item) => item.id == id)),
            onRetryPending: _simulateUpload,
          ),
        ],
      ),
    );
  }
}
