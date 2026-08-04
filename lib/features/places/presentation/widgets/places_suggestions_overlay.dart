import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';

/// Suggestion panel anchored to an address field via [anchorKey].
///
/// Opens below the field when there is room above the keyboard; otherwise opens
/// above so the keyboard does not cover the list.
class PlacesSuggestionsOverlay extends StatelessWidget {
  const PlacesSuggestionsOverlay({
    super.key,
    required this.anchorKey,
    required this.suggestions,
    required this.onPick,
  });

  static const double panelMaxHeight = 240;
  static const double gap = 4;

  final GlobalKey anchorKey;
  final List<PlacePrediction> suggestions;
  final ValueChanged<PlacePrediction> onPick;

  @override
  Widget build(BuildContext context) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final fieldOffset = box.localToGlobal(Offset.zero);
    final fieldSize = box.size;
    final media = MediaQuery.of(context);
    final usableBottom = media.size.height - media.viewInsets.bottom;
    final spaceBelow = usableBottom - (fieldOffset.dy + fieldSize.height) - gap;
    final openAbove = spaceBelow < panelMaxHeight;

    final panel = _SuggestionsPanel(
      suggestions: suggestions,
      onPick: onPick,
    );

    if (openAbove) {
      return Positioned(
        left: fieldOffset.dx,
        width: fieldSize.width,
        bottom: media.size.height - fieldOffset.dy + gap,
        child: panel,
      );
    }

    return Positioned(
      left: fieldOffset.dx,
      width: fieldSize.width,
      top: fieldOffset.dy + fieldSize.height + gap,
      child: panel,
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.suggestions,
    required this.onPick,
  });

  final List<PlacePrediction> suggestions;
  final ValueChanged<PlacePrediction> onPick;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: vcare.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: PlacesSuggestionsOverlay.panelMaxHeight,
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onPick(suggestion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: vcare.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
