import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

/// Bottom-tab pages: title stays below the safe area; only the search field compacts on scroll.
class VcareStickyTabScaffold extends StatefulWidget {
  const VcareStickyTabScaffold({
    super.key,
    required this.header,
    required this.body,
    this.search,
    this.footer,
    this.onScrollCompactChanged,
    this.scrollCompactThreshold = 16,
  });

  final Widget header;
  final Widget body;
  final VcareStickySearchField? search;
  final Widget? footer;
  final ValueChanged<bool>? onScrollCompactChanged;
  final double scrollCompactThreshold;

  factory VcareStickyTabScaffold.page({
    Key? key,
    required String title,
    String? subtitle,
    Widget? action,
    required Widget body,
    VcareStickySearchField? search,
    Widget? footer,
    double scrollCompactThreshold = 16,
    ValueChanged<bool>? onScrollCompactChanged,
  }) {
    return VcareStickyTabScaffold(
      key: key,
      scrollCompactThreshold: scrollCompactThreshold,
      onScrollCompactChanged: onScrollCompactChanged,
      header: VcarePageHeader(title: title, subtitle: subtitle, action: action),
      search: search,
      footer: footer,
      body: body,
    );
  }

  @override
  State<VcareStickyTabScaffold> createState() => _VcareStickyTabScaffoldState();
}

class VcareStickySearchField {
  const VcareStickySearchField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 8),
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final EdgeInsets padding;
}

class _VcareStickyTabScaffoldState extends State<VcareStickyTabScaffold> {
  bool _compactSearch = false;
  bool _lastScrollCompact = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final compact = notification.metrics.pixels > widget.scrollCompactThreshold;
    if (widget.search != null && compact != _compactSearch) {
      setState(() => _compactSearch = compact);
    }
    if (widget.onScrollCompactChanged != null &&
        compact != _lastScrollCompact) {
      _lastScrollCompact = compact;
      widget.onScrollCompactChanged!(compact);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final search = widget.search;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Material(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.header,
                  if (search != null) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: vcare.border.withValues(
                              alpha: _compactSearch ? 0.6 : 0,
                            ),
                          ),
                        ),
                      ),
                      padding: search.padding,
                      height: _compactSearch ? 44 : 52,
                      child: _SearchField(
                        controller: search.controller,
                        hintText: search.hintText,
                        compact: _compactSearch,
                        onChanged: search.onChanged,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.body,
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.compact,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool compact;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          color: vcare.mutedForeground.withValues(alpha: 0.7),
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 12, right: 8, bottom: compact ? 4 : 0),
          child: Icon(
            LucideIcons.search,
            size: compact ? 16 : 18,
            color: vcare.mutedForeground.withValues(alpha: 0.7),
          ),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: compact ? 32 : 40,
          minHeight: compact ? 32 : 40,
        ),
        filled: true,
        fillColor: vcare.muted.withValues(alpha: 0.5),
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: vcare.border.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: vcare.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
