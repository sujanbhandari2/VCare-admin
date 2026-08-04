import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';
import 'package:vcare_admin/features/places/domain/entities/places_autocomplete_type.dart';
import 'package:vcare_admin/features/places/presentation/providers/places_repository_provider.dart';
import 'package:vcare_admin/features/places/presentation/widgets/places_suggestions_overlay.dart';
import 'package:vcare_admin/features/places/utils/parse_address_components.dart';

const _debounceMs = 350;
const _minChars = 3;

/// Street address typeahead that fills city/state/postal on place selection.
class AddressLine1Autocomplete extends ConsumerStatefulWidget {
  const AddressLine1Autocomplete({
    super.key,
    required this.controller,
    this.label = 'Street address',
    this.hint = '123 Market St',
    this.maxLength = 120,
    this.errorText,
    this.onChanged,
    this.onSelect,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<ParsedAddressParts>? onSelect;

  @override
  ConsumerState<AddressLine1Autocomplete> createState() =>
      _AddressLine1AutocompleteState();
}

class _AddressLine1AutocompleteState
    extends ConsumerState<AddressLine1Autocomplete>
    with WidgetsBindingObserver {
  final _anchorKey = GlobalKey();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  CancelToken? _predictionsCancel;
  CancelToken? _resolveCancel;

  List<PlacePrediction> _suggestions = const [];
  bool _loading = false;
  bool _userSearching = false;
  bool _skipPredictions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _predictionsCancel?.cancel();
    _resolveCancel?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _overlayEntry?.markNeedsBuild();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay so a suggestion tap can register before the overlay is removed.
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _focusNode.hasFocus) return;
        _hideSuggestions();
      });
    }
  }

  void _onInputChanged(String value) {
    _userSearching = true;
    _skipPredictions = false;
    widget.onChanged?.call(value);
    _scheduleFetch(value);
  }

  void _scheduleFetch(String value) {
    _debounce?.cancel();
    _predictionsCancel?.cancel();

    if (!_userSearching || _skipPredictions) {
      _hideSuggestions();
      return;
    }

    final trimmed = value.trim();
    if (trimmed.length < _minChars) {
      _hideSuggestions();
      return;
    }

    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      unawaited(_fetchPredictions(trimmed));
    });
  }

  Future<void> _fetchPredictions(String input) async {
    final cancel = CancelToken();
    _predictionsCancel = cancel;

    final response = await ref
        .read(placesRepositoryProvider)
        .fetchPredictions(
          input: input,
          type: PlacesAutocompleteType.address,
          cancelToken: cancel,
        );

    if (!mounted || cancel.isCancelled || _skipPredictions) return;

    response.when(
      success: (predictions) {
        setState(() {
          _suggestions = predictions;
          _loading = false;
        });
        if (predictions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      },
      failure: (_) {
        setState(() {
          _suggestions = const [];
          _loading = false;
        });
        _removeOverlay();
      },
    );
  }

  Future<void> _onPick(PlacePrediction prediction) async {
    _predictionsCancel?.cancel();
    _userSearching = false;
    _skipPredictions = true;
    _hideSuggestions();
    setState(() => _loading = true);

    final cancel = CancelToken();
    _resolveCancel = cancel;

    final response = await ref
        .read(placesRepositoryProvider)
        .resolvePlaceAddress(prediction: prediction, cancelToken: cancel);

    if (!mounted || cancel.isCancelled) return;

    response.when(
      success: (parts) {
        widget.controller.text = parts.line1;
        widget.onSelect?.call(parts);
        setState(() => _loading = false);
      },
      failure: (_) {
        final parts = parseAddressLabel(prediction.label);
        widget.controller.text = parts.line1;
        widget.onSelect?.call(parts);
        setState(() => _loading = false);
      },
    );
  }

  void _hideSuggestions() {
    setState(() {
      _suggestions = const [];
      _loading = false;
    });
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(
      builder: (context) => PlacesSuggestionsOverlay(
        anchorKey: _anchorKey,
        suggestions: _suggestions,
        onPick: (prediction) {
          unawaited(_onPick(prediction));
        },
      ),
    );
    overlay.insert(_overlayEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          key: _anchorKey,
          controller: widget.controller,
          focusNode: _focusNode,
          maxLength: widget.maxLength,
          onChanged: _onInputChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            errorText: widget.errorText,
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
          ),
        ),
      ],
    );
  }
}
