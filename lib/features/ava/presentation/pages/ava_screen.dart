import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/features/ava/data/ava_mock_data.dart';
import 'package:flutter_template/features/ava/domain/entities/ava_message.dart';
import 'package:flutter_template/features/ava/presentation/providers/ava_state_provider.dart';
import 'package:flutter_template/features/ava/presentation/widgets/ava_composer.dart';
import 'package:flutter_template/features/ava/presentation/widgets/ava_message_list.dart';
import 'package:flutter_template/features/ava/presentation/widgets/ava_page_header.dart';

/// AVA chat screen — parity with vcareapp [/ava] + [AvaChatPanel].
class AvaScreen extends ConsumerStatefulWidget {
  const AvaScreen({super.key});

  @override
  ConsumerState<AvaScreen> createState() => _AvaScreenState();
}

class _AvaScreenState extends ConsumerState<AvaScreen> {
  final _scrollController = ScrollController();
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _composer.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composer.removeListener(_onDraftChanged);
    _composer.dispose();
    super.dispose();
  }

  void _onDraftChanged() => setState(() {});

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? text]) {
    final body = (text ?? _composer.text).trim();
    if (body.isEmpty) return;

    ref.read(avaStateProvider.notifier).sendMessage(body);
    _composer.clear();
    _scrollToBottom();
  }

  void _startEdit(String id, String body) {
    ref.read(avaStateProvider.notifier).startEdit(id, body);
    _composer.text = body;
  }

  void _cancelEdit() {
    ref.read(avaStateProvider.notifier).cancelEdit();
    _composer.clear();
  }

  void _deleteMessage(String id) {
    ref.read(avaStateProvider.notifier).deleteMessage(id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avaStateProvider);
    final messages = state.messages.isEmpty
        ? List<AvaMessage>.from(AvaMockData.seedMessages)
        : state.messages;
    final showSuggestions = messages.length <= 1;

    ref.listen(
      avaStateProvider.select((s) => s.messages.length),
      (previous, next) => _scrollToBottom(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AvaPageHeader(),
            Expanded(
              child: AvaMessageList(
                scrollController: _scrollController,
                messages: messages,
                showSuggestions: showSuggestions,
                onSend: _send,
                onEdit: _startEdit,
                onDelete: _deleteMessage,
                onHumanRequest: () =>
                    context.pushNamed(AppRouter.requestNewName),
              ),
            ),
            AvaComposer(
              controller: _composer,
              editingId: state.editingId,
              canSend: _composer.text.trim().isNotEmpty,
              onSend: () => _send(),
              onCancelEdit: _cancelEdit,
            ),
          ],
        ),
      ),
    );
  }
}
