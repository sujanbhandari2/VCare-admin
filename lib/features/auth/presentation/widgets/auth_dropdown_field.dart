import 'package:flutter/material.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

import 'package:flutter_template/features/auth/domain/enums/base_enum.dart';

class AuthDropdownField<T extends BaseEnum> extends StatefulWidget {
  const AuthDropdownField({
    super.key,
    required this.items,
    required this.label,
    this.hint,
    this.value,
    this.margin = .zero,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.autoValidateMode = .onUserInteraction,
    this.enabled = false,
    this.required = false,
  });

  final List<T> items;
  final String label;
  final String? hint;
  final T? value;
  final EdgeInsetsGeometry margin;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;
  final void Function(T?)? onSaved;
  final AutovalidateMode autoValidateMode;
  final bool enabled;
  final bool required;

  @override
  State<AuthDropdownField<T>> createState() => _AuthDropdownFieldState<T>();
}

class _AuthDropdownFieldState<T extends BaseEnum>
    extends State<AuthDropdownField<T>> {
  /// Selected value
  ///
  T? _selected;

  /// Init State
  ///
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onChanged(widget.value);
    });
  }

  /// on value changed
  ///
  void _onChanged(T? value) {
    if (value != null) {
      setState(() {
        _selected = value;
      });
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          if (widget.required)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: !widget.enabled ? context.theme.hintColor : null,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '*',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: !widget.enabled
                          ? context.theme.hintColor
                          : context.theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              widget.label,
              style: context.textTheme.bodySmall?.copyWith(
                color: !widget.enabled ? context.theme.hintColor : null,
              ),
            ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<T>(
            items: widget.items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.localizedLabel(context)),
                  ),
                )
                .toList(),
            initialValue: _selected,
            hint: Text(
              widget.hint ?? widget.label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: .circular(8.0)),
              isDense: true,
            ),
            style: context.textTheme.bodyLarge?.copyWith(
              color: !widget.enabled ? context.theme.hintColor : null,
            ),
            validator: widget.validator,
            onSaved: widget.onSaved,
            autovalidateMode: widget.autoValidateMode,
            onChanged: widget.enabled ? _onChanged : null,
            borderRadius: .circular(8),
          ),
        ],
      ),
    );
  }
}
