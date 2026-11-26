import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_notes_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_mention_picker.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_note_mention_editing_controller.dart';
import 'package:vcare_admin/features/cases/utils/case_note_mentions.dart';

/// Where the mention suggestions sit relative to the note input.
enum CaseMentionPickerPlacement { above, below }

/// Default inset for composer mention text (keeps text off the left border).
const EdgeInsets kCaseNoteMentionFieldContentPadding = EdgeInsets.only(left: 5);

/// Note input that shows a anchored mention picker while an `@` query is active.
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
    this.contentPadding = kCaseNoteMentionFieldContentPadding,
  });

  final String caseId;
  final CaseNoteMentionEditingController controller;
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
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
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
    _focusNode.dispose();
    super.dispose();
  }

  void _hidePicker() {
    if (_portalController.isShowing) _portalController.hide();
  }

  void _onTextChanged() {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.baseOffset < 0) {
      _hidePicker();
      if (mounted) setState(() {});
      return;
    }

    final text = widget.controller.text;
    final cursor = selection.baseOffset.clamp(0, text.length);
    final active = findActiveMentionQuery(
      text,
      cursor,
      widget.controller.mentions,
    );
    if (active == null) {
      _hidePicker();
    } else {
      _query = active.query;
      if (!_portalController.isShowing) _portalController.show();
      _searchTagUsers();
    }
    if (mounted) setState(() {});
  }

  void _searchTagUsers() {
    ref
        .read(caseNotesStateProvider(widget.caseId).notifier)
        .fetchTagUsers(search: _query.isEmpty ? null : _query);
  }

  void _insertMention(CaseNoteTagUser user) {
    final selection = widget.controller.selection;
    final cursor = selection.isValid
        ? selection.baseOffset.clamp(0, widget.controller.text.length)
        : widget.controller.text.length;
    final active = findActiveMentionQuery(
      widget.controller.text,
      cursor,
      widget.controller.mentions,
    );
    if (active == null) return;

    widget.controller.insertMention(
      name: user.displayName,
      email: user.email,
      query: active,
    );
    _hidePicker();
  }

  bool get _isAbove => widget.placement == CaseMentionPickerPlacement.above;

  TextStyle _composerTextStyle(Color color) {
    return TextStyle(
      fontSize: 13,
      height: 1.4,
      color: color,
      decoration: TextDecoration.none,
    );
  }

  Widget _buildComposerField() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textStyle = _composerTextStyle(textColor);

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: textStyle,
      cursorColor: textColor,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Theme.of(context).hintColor,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: widget.contentPadding,
      ),
    );
  }

  double _pickerMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return math.min(kCaseMentionPickerMaxHeight, screenHeight * 0.26);
  }

  Widget _buildPicker(CaseNotesStateData notesState, {required double maxHeight}) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: CaseMentionPicker(
        users: notesState.tagUsers,
        isLoading: notesState.searchingTagUsers,
        error: notesState.tagUsersOperation.errorMessage,
        onRetry: _searchTagUsers,
        onSelected: _insertMention,
        maxHeight: maxHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(caseNotesStateProvider(widget.caseId));

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (overlayContext) {
          final width = _layerLink.leaderSize?.width;
          if (width == null || width <= 0) {
            return const SizedBox.shrink();
          }

          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: _isAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor:
                _isAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(0, _isAbove ? -6 : 6),
            child: Material(
              type: MaterialType.transparency,
              child: Align(
                alignment:
                    _isAbove ? Alignment.bottomLeft : Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: _buildPicker(
                    notesState,
                    maxHeight: _pickerMaxHeight(overlayContext),
                  ),
                ),
              ),
            ),
          );
        },
        child: _buildComposerField(),
      ),
    );
  }
}
