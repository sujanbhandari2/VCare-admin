import 'package:flutter/material.dart';
import 'package:vcare_admin/core/styles/app_colors.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/common_icon.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    this.hint = 'Search',
    this.controller,
    this.margin = .zero,
    this.enabled = true,
    this.required = false,
    this.maxLength,
    this.readOnly = false,
    this.filled = false,
    this.fillColor,
    this.borderColor,
    this.showClearButton = false,
    this.onChanged,
    this.onSearched,
    this.onCleared,
    this.prefixIcon = Icons.search,
  });

  final String hint;
  final dynamic prefixIcon;
  final TextEditingController? controller;
  final EdgeInsetsGeometry margin;
  final bool enabled;
  final bool required;
  final int? maxLength;
  final bool readOnly;
  final bool filled;
  final Color? fillColor;
  final Color? borderColor;
  final bool showClearButton;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSearched;
  final VoidCallback? onCleared;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  /// Search Controller to use if not provided
  ///
  final _controller = TextEditingController();

  /// Notifier to show clear button
  ///
  late ValueNotifier<bool> _showClear;

  @override
  void initState() {
    super.initState();
    _showClear = ValueNotifier(false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: TextFormField(
        controller: widget.controller ?? _controller,
        textInputAction: .search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: context.textTheme.regular14?.copyWith(
            color: context.theme.hintColor,
          ),
          prefixIcon: widget.prefixIcon != null
              ? CommonIcon(icon: widget.prefixIcon)
              : null,
          suffixIcon: ValueListenableBuilder<bool>(
            valueListenable: _showClear,
            builder: (context, show, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 275),
                child: show
                    ? IconButton(
                        onPressed: () {
                          (widget.controller ?? _controller).clear();
                          _showClear.value = false;
                          widget.onCleared?.call();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : SizedBox.shrink(),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: .circular(8.0),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: .circular(8.0),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.grey),
          ),
          filled: widget.filled,
          fillColor: widget.fillColor,
          isDense: true,
        ),
        textAlignVertical: .center,
        style: context.textTheme.regular14?.copyWith(
          color: !widget.enabled ? context.theme.hintColor : null,
        ),
        onChanged: (s) {
          _showClear.value = widget.showClearButton && s.trim().isNotEmpty;
          widget.onChanged?.call(s);
        },
        onFieldSubmitted: widget.onSearched,
        keyboardType: .text,
        enabled: widget.enabled,
        maxLength: widget.maxLength,
        readOnly: widget.readOnly,
        buildCounter:
            (
              _, {
              required int currentLength,
              required bool isFocused,
              int? maxLength,
            }) => null,
        maxLines: 1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _showClear.dispose();
    super.dispose();
  }
}
