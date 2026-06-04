import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/ava/data/ava_mock_data.dart';
import 'package:flutter_template/features/ava/domain/entities/ava_message.dart';
import 'package:flutter_template/features/ava/presentation/providers/ava_state_provider.dart';
import 'package:flutter_template/features/ava/utils/ava_chat_date.dart';
import 'package:flutter_template/features/main_wrapper/presentation/widgets/vcare_bottom_navigation.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

/// Layout tokens from vcareapp AVA feature (`px-5`, `gap-3`, `AvaChatMessage`, etc.).
abstract final class AvaLayout {
  static const double horizontalPadding = 20;
  static const double listTopPadding = 8;
  static const double listBottomPadding = 24;
  static const double itemGap = 12;
  static const double bubbleMaxWidthFactor = 0.78;
  static const double bubbleRadius = 16;
  static const double bubbleTailRadius = 6;
  static const EdgeInsets bubblePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const double bubbleFontSize = 14;
  static const double avatarSize = 32;
  static const double avatarIconSize = 16;
}

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
    final vcare = context.vcare;
    final state = ref.watch(avaStateProvider);
    final messages = state.messages.isEmpty
        ? List<AvaMessage>.from(AvaMockData.seedMessages)
        : state.messages;
    final showSuggestions = messages.length <= 1;
    final composerBottom =
        vcareAvaComposerBottomInset(context) +
        MediaQuery.viewInsetsOf(context).bottom;
    final editingExtra = state.editingId != null ? 36.0 : 0.0;
    final overlayHeight =
        kAvaComposerHeight + editingExtra + composerBottom;

    ref.listen(
      avaStateProvider.select((s) => s.messages.length),
      (previous, next) => _scrollToBottom(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VcarePageHeader(
                  title: 'AVA',
                  subtitle: 'Advocate Virtual Assistant',
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          AvaLayout.horizontalPadding,
                          AvaLayout.listTopPadding,
                          AvaLayout.horizontalPadding,
                          overlayHeight + AvaLayout.listBottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - overlayHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildChatChildren(
                              vcare,
                              messages,
                              showSuggestions,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: composerBottom,
              child: _AvaComposer(
                controller: _composer,
                editingId: state.editingId,
                canSend: _composer.text.trim().isNotEmpty,
                onSend: () => _send(),
                onCancelEdit: _cancelEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChatChildren(
    VCareThemeExtension vcare,
    List<AvaMessage> messages,
    bool showSuggestions,
  ) {
    final children = <Widget>[];

    for (var i = 0; i < messages.length; i++) {
      if (i == 0 ||
          !avaSameDay(messages[i - 1].createdAt, messages[i].createdAt)) {
        children.add(
          _DateChip(label: formatAvaChatDateSeparator(messages[i].createdAt)),
        );
      }
      children.add(
        _AvaMessageBubble(
          message: messages[i],
          onEdit: messages[i].isMe ? _startEdit : null,
          onDelete: messages[i].isMe ? _deleteMessage : null,
        ),
      );
    }

    if (messages.length > 1) {
      children.add(
        _HumanRequestLink(
          onTap: () => context.pushNamed(AppRouter.requestNewName),
        ),
      );
    }

    if (showSuggestions) {
      children.add(_SuggestionList(onSelect: _send));
    }

    return _spaced(children);
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.isEmpty) return items;
    final spaced = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      spaced.add(const SizedBox(height: AvaLayout.itemGap));
      spaced.add(items[i]);
    }
    return spaced;
  }
}

/// Matches vcareapp [ChatDateSeparator].
class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: vcare.muted.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Matches vcareapp [AvaChatMessage].
class _AvaMessageBubble extends StatelessWidget {
  const _AvaMessageBubble({required this.message, this.onEdit, this.onDelete});

  final AvaMessage message;
  final void Function(String id, String body)? onEdit;
  final void Function(String id)? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isMe = message.isMe;
    final maxBubbleWidth =
        MediaQuery.sizeOf(context).width * AvaLayout.bubbleMaxWidthFactor;

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[_AvaAvatar(vcare: vcare), const SizedBox(width: 8)],
        if (isMe && (onEdit != null || onDelete != null)) ...[
          _MessageActionsMenu(
            onEdit: onEdit != null
                ? () => onEdit!(message.id, message.body)
                : null,
            onDelete: onDelete != null ? () => onDelete!(message.id) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: AvaLayout.bubblePadding,
            decoration: BoxDecoration(
              color: isMe ? VCareColors.primary : vcare.muted,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AvaLayout.bubbleRadius),
                topRight: const Radius.circular(AvaLayout.bubbleRadius),
                bottomLeft: Radius.circular(
                  isMe ? AvaLayout.bubbleRadius : AvaLayout.bubbleTailRadius,
                ),
                bottomRight: Radius.circular(
                  isMe ? AvaLayout.bubbleTailRadius : AvaLayout.bubbleRadius,
                ),
              ),
            ),
            child: Text(
              message.body,
              style: TextStyle(
                fontSize: AvaLayout.bubbleFontSize,
                height: 1.35,
                color: isMe
                    ? VCareColors.primaryForeground
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvaAvatar extends StatelessWidget {
  const _AvaAvatar({required this.vcare});

  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AvaLayout.avatarSize,
      height: AvaLayout.avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VCareColors.primary, vcare.accent],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.sparkles,
        size: AvaLayout.avatarIconSize,
        color: VCareColors.primaryForeground,
      ),
    );
  }
}

class _MessageActionsMenu extends StatelessWidget {
  const _MessageActionsMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        LucideIcons.moreHorizontal,
        size: 16,
        color: context.vcare.mutedForeground.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 14),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 14,
                  color: VCareColors.destructive,
                ),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(color: VCareColors.destructive),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Matches vcareapp [AvaSuggestionList].
class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.onSelect});

  final void Function(String text) onSelect;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Try asking'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < AvaMockData.suggestions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _SuggestionChip(
              label: AvaMockData.suggestions[i],
              onTap: () => onSelect(AvaMockData.suggestions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AvaLayout.bubbleRadius),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AvaLayout.bubbleRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: AvaLayout.bubbleFontSize),
            ),
          ),
        ),
      ),
    );
  }
}

/// Matches vcareapp [AvaHumanRequestLink].
class _HumanRequestLink extends StatelessWidget {
  const _HumanRequestLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: VCareColors.primary.withValues(alpha: 0.1),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Need a human? Submit a request',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: VCareColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 12,
                    color: VCareColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Matches vcareapp [AvaComposer] — `px-5 pt-1 pb-0`, pill input + send.
class _AvaComposer extends StatelessWidget {
  const _AvaComposer({
    required this.controller,
    required this.editingId,
    required this.canSend,
    required this.onSend,
    required this.onCancelEdit,
  });

  static const double _fieldPaddingLeft = 16;
  static const double _fieldPaddingRight = 6;
  static const double _sendButtonSize = 36;
  static const double _textSize = 14;

  final TextEditingController controller;
  final String? editingId;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AvaLayout.horizontalPadding,
          4,
          AvaLayout.horizontalPadding,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (editingId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Editing message',
                        style: TextStyle(
                          fontSize: 11,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelEdit,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VCareColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Material(
              color: vcare.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(color: vcare.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _fieldPaddingLeft,
                  6,
                  _fieldPaddingRight,
                  6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: _textSize, height: 1.25),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: canSend ? (_) => onSend() : null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          hintText: 'Ask AVA anything…',
                          hintStyle: TextStyle(
                            fontSize: _textSize,
                            color: vcare.mutedForeground.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: canSend
                          ? VCareColors.primary
                          : VCareColors.primary.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: canSend ? onSend : null,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: _sendButtonSize,
                          height: _sendButtonSize,
                          child: Icon(
                            LucideIcons.send,
                            size: 16,
                            color: VCareColors.primaryForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
