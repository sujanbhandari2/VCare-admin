import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';
import 'package:vcare_admin/features/places/domain/entities/places_autocomplete_type.dart';
import 'package:vcare_admin/features/places/presentation/providers/places_repository_provider.dart';
import 'package:vcare_admin/features/places/presentation/widgets/places_suggestions_overlay.dart';
import 'package:vcare_admin/features/places/utils/parse_address_components.dart';

const _debounceMs = 350;
const _minChars = 3;

/// Combined city/state typeahead for primary location (web parity).
class PrimaryLocationField extends ConsumerStatefulWidget {
  const PrimaryLocationField({
    super.key,
    required this.cityController,
    required this.stateController,
    this.errorText,
    this.onChanged,
    this.showLabel = true,
    this.loginStyle = false,
  });

  final TextEditingController cityController;
  final TextEditingController stateController;
  final String? errorText;
  final void Function({required String city, required String state})? onChanged;
  final bool showLabel;

  /// Matches login activate inputs (web `LOGIN_INPUT_CLASS`).
  final bool loginStyle;

  @override
  ConsumerState<PrimaryLocationField> createState() =>
      _PrimaryLocationFieldState();
}

class _PrimaryLocationFieldState extends ConsumerState<PrimaryLocationField>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
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
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController(
      text: formatPrimaryLocation(
        widget.cityController.text,
        widget.stateController.text,
      ),
    );
    _focusNode.addListener(_onFocusChanged);
    widget.cityController.addListener(_syncFromParents);
    widget.stateController.addListener(_syncFromParents);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _predictionsCancel?.cancel();
    _resolveCancel?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    widget.cityController.removeListener(_syncFromParents);
    widget.stateController.removeListener(_syncFromParents);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _overlayEntry?.markNeedsBuild();
  }

  void _syncFromParents() {
    if (_focused) return;
    final next = formatPrimaryLocation(
      widget.cityController.text,
      widget.stateController.text,
    );
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  void _onFocusChanged() {
    _focused = _focusNode.hasFocus;
    if (!_focusNode.hasFocus) {
      _commitParsed(format: true);
      // Delay so a suggestion tap can register before the overlay is removed.
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _focusNode.hasFocus) return;
        _hideSuggestions();
      });
    }
  }

  void _commitParsed({required bool format}) {
    final parsed = parsePrimaryLocationInput(_controller.text);
    widget.cityController.text = parsed.city;
    widget.stateController.text = parsed.state;
    widget.onChanged?.call(city: parsed.city, state: parsed.state);
    if (format) {
      _controller.text = formatPrimaryLocation(parsed.city, parsed.state);
    }
  }

  void _onInputChanged(String value) {
    _userSearching = true;
    _skipPredictions = false;
    final parsed = parsePrimaryLocationInput(value);
    widget.cityController.text = parsed.city;
    widget.stateController.text = parsed.state;
    widget.onChanged?.call(city: parsed.city, state: parsed.state);
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
          type: PlacesAutocompleteType.cities,
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
        .resolvePlaceCityState(prediction: prediction, cancelToken: cancel);

    if (!mounted || cancel.isCancelled) return;

    void apply(String city, String state) {
      final c = city.trim();
      final s = state.trim();
      widget.cityController.text = c;
      widget.stateController.text = s;
      _controller.text = formatPrimaryLocation(c, s);
      widget.onChanged?.call(city: c, state: s);
    }

    response.when(
      success: (parts) {
        apply(parts.city, parts.state);
        setState(() => _loading = false);
      },
      failure: (_) {
        final parts = parseCityStateLabel(prediction.label);
        apply(parts.city, parts.state);
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
    // Field layout may settle after keyboard/insets; refresh once next frame.
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
    final fillColor = widget.loginStyle
        ? vcare.muted.withValues(alpha: 0.5)
        : vcare.card;
    final contentPadding = widget.loginStyle
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          const Text(
            'Primary location',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          key: _anchorKey,
          controller: _controller,
          focusNode: _focusNode,
          maxLength: 120,
          onChanged: _onInputChanged,
          style: widget.loginStyle
              ? const TextStyle(fontWeight: FontWeight.w500)
              : null,
          decoration: InputDecoration(
            hintText: 'New Orleans, Louisiana',
            hintStyle: TextStyle(
              color: vcare.mutedForeground.withValues(alpha: 0.6),
            ),
            counterText: '',
            errorText: widget.errorText,
            filled: true,
            fillColor: fillColor,
            isDense: !widget.loginStyle,
            contentPadding: contentPadding,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: VCareColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
