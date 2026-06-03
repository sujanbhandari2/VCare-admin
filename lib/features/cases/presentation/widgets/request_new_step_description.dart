import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/utils/request_new_utils.dart';

class RequestNewStepDescription extends StatelessWidget {
  const RequestNewStepDescription({
    super.key,
    required this.controller,
    required this.onSpeakInstead,
    required this.onFieldVoiceAction,
  });

  final TextEditingController controller;
  final VoidCallback onSpeakInstead;
  final VoidCallback onFieldVoiceAction;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final length = controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need help with?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Type or tap the mic to speak — describe it in your own words.',
          style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vcare.border),
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 7,
                minLines: 7,
                maxLength: requestNewMaxDescriptionLength,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => const SizedBox.shrink(),
                decoration: InputDecoration(
                  hintText:
                      "e.g. I got a \$4,200 ER bill from St. Mary's and some charges look duplicated.",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: vcare.mutedForeground.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 52, 16),
                ),
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: vcare.accent,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    onTap: onFieldVoiceAction,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        LucideIcons.arrowUp,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SpeakInsteadButton(onPressed: onSpeakInstead),
            const Spacer(),
            Text(
              '$length/$requestNewMaxDescriptionLength',
              style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeakInsteadButton extends StatelessWidget {
  const _SpeakInsteadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VCareColors.primary.withValues(alpha: 0.1),
      shape: StadiumBorder(
        side: BorderSide(color: VCareColors.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mic, size: 14, color: VCareColors.primary),
              const SizedBox(width: 6),
              Text(
                'Speak instead',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VCareColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
