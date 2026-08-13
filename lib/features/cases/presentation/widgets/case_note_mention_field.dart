import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_mention_picker.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';

/// Where the floating mention suggestions sit relative to the input.
enum CaseMentionPickerPlacement { above, below }

/// Note input that floats the mention picker while an `@` query is being typed.
class CaseNoteMentionField extends ConsumerStatefulWidget {
  const CaseNoteMentionField({
    super.key,
    required this.caseId,
    required this.controller,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 5,
    this.enabled = true,
    this.autofocus = false,
    this.placement = CaseMentionPickerPlacement.below,
    this.contentPadding = EdgeInsets.zero,
  });

  final String caseId;
  final TextEditingController controller;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final CaseMentionPickerPlacement placement;
  final EdgeInsetsGeometry contentPadding;

  @override
  ConsumerState<CaseNoteMentionField> createState() =>
      _CaseNoteMentionFieldState();
}

class _CaseNoteMentionFieldState extends ConsumerState<CaseNoteMentionField> {
  static final RegExp _activeQueryRegex = RegExp(r'@([^\s@]*)$');

  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CaseNoteMentionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _hidePicker();
  }

  void _hidePicker() {
    if (_portalController.isShowing) _portalController.hide();
  }

  void _onTextChanged() {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.baseOffset < 0) {
      _hidePicker();
      return;
    }

    final text = widget.controller.text;
    final cursor = selection.baseOffset.clamp(0, text.length);
    final match = _activeQueryRegex.firstMatch(text.substring(0, cursor));
    if (match == null) {
      _hidePicker();
      return;
    }

    _query = match.group(1) ?? '';
    if (!_portalController.isShowing) _portalController.show();
    _searchTagUsers();
  }

  void _searchTagUsers() {
    ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .fetchTagUsers(search: _query.isEmpty ? null : _query);
  }

  void _insertMention(CaseNoteTagUser user) {
    final text = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final match = _activeQueryRegex.firstMatch(before);
    if (match == null) return;

    final token = formatMention(user.displayName, user.email);
    final newBefore = '${before.substring(0, match.start)}$token ';
    widget.controller.value = TextEditingValue(
      text: '$newBefore$after',
      selection: TextSelection.collapsed(offset: newBefore.length),
    );
    _hidePicker();
  }

  bool get _isAbove => widget.placement == CaseMentionPickerPlacement.above;

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(caseNotesStateProvider(widget.caseId));

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (overlayContext) {
          final width = _layerLink.leaderSize?.width ?? 240;

          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: _isAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: _isAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(0, _isAbove ? -6 : 6),
            child: SizedBox(
              width: width,
              child: CaseMentionPicker(
                users: notesState.tagUsers,
                isLoading: notesState.searchingTagUsers,
                error: notesState.tagUsersOperation.errorMessage,
                onRetry: _searchTagUsers,
                onSelected: _insertMention,
              ),
            ),
          );
        },
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: const TextStyle(fontSize: 13, height: 1.4),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(fontSize: 13, height: 1.4),
            border: InputBorder.none,
            isDense: true,
            contentPadding: widget.contentPadding,
          ),
        ),
      ),
    );
  }
}
